const ACTUATOR_TYPES = new Set([
  "RELAIS",
  "LAMPE",
  "MOTEUR",
  "SERVO",
  "MAX",
  "LED",
  "LIGHT",
  "FAN",
  "OUTLET",
]);

const SENSOR_TYPES = new Set(["PIR", "DHT", "DHT22", "DHT_TEMP", "RFID", "ULTRA"]);

/** @type {Map<string, number>} */
const lastAlertAt = new Map();

/** @type {Map<string, { threshold: number, at: number }>} */
const thresholdCache = new Map();

const THRESHOLD_CACHE_MS = 60_000;

export function normalizeType(raw) {
  return String(raw ?? "")
    .trim()
    .toUpperCase();
}

export function stringifyValeur(raw) {
  if (raw == null) return "";
  if (typeof raw === "number") return String(raw);
  if (typeof raw === "boolean") return raw ? "1" : "0";
  return String(raw).trim();
}

export function isActuator(data) {
  const cat = String(data?.categorie ?? "")
    .trim()
    .toLowerCase();
  if (cat === "actionneur") return true;
  if (cat === "capteur") return false;
  return ACTUATOR_TYPES.has(normalizeType(data?.type));
}

export function isSensor(data) {
  const cat = String(data?.categorie ?? "")
    .trim()
    .toLowerCase();
  if (cat === "capteur") return true;
  if (cat === "actionneur") return false;
  return SENSOR_TYPES.has(normalizeType(data?.type));
}

function normalizeUid(raw) {
  return String(raw ?? "")
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, "");
}

function truthyValeur(raw) {
  const s = stringifyValeur(raw);
  return s === "1" || s.toLowerCase() === "true" || s.toLowerCase() === "on";
}

function parseDhtTemp(valeur) {
  const s = stringifyValeur(valeur);
  const head = s.split(/[,;/|]/)[0]?.trim() ?? "";
  const temp = Number.parseFloat(head.replace(",", "."));
  return Number.isFinite(temp) ? temp : null;
}

async function readAlertThreshold(db, userId, defaultThreshold) {
  const cached = thresholdCache.get(userId);
  const now = Date.now();
  if (cached && now - cached.at < THRESHOLD_CACHE_MS) {
    return cached.threshold;
  }

  let threshold = defaultThreshold;
  try {
    const snap = await db
      .collection("users")
      .doc(userId)
      .collection("preferences")
      .doc("settings")
      .get();
    const raw = snap.data()?.alertThreshold;
    const n = Number(raw);
    if (Number.isFinite(n)) threshold = n;
  } catch (err) {
    console.warn("[Alert] threshold read failed:", err.message ?? err);
  }

  thresholdCache.set(userId, { threshold, at: now });
  return threshold;
}

async function isUidAuthorized(db, userId, uid) {
  const normalized = normalizeUid(uid);
  if (!normalized) return false;

  const snap = await db
    .collection("users")
    .doc(userId)
    .collection("rfidCards")
    .get();

  for (const doc of snap.docs) {
    const data = doc.data() ?? {};
    if (data.active === false || data.actif === false) continue;
    const cardUid = normalizeUid(data.uid ?? data.valeur ?? "");
    if (cardUid && cardUid === normalized) return true;
  }
  return false;
}

function canEmitAlert(type, appareilId, cooldownMs) {
  const key = `${type}:${appareilId}`;
  const now = Date.now();
  const last = lastAlertAt.get(key) ?? 0;
  if (now - last < cooldownMs) return false;
  lastAlertAt.set(key, now);
  return true;
}

export async function createAlert(db, userId, alert, cooldownMs) {
  if (!canEmitAlert(alert.type, alert.appareilId, cooldownMs)) {
    console.log("[Alert] cooldown", alert.type, alert.appareilId);
    return false;
  }

  await db
    .collection("maisons")
    .doc(userId)
    .collection("alerts")
    .add({
      userId,
      type: alert.type,
      severity: alert.severity ?? "medium",
      title: alert.title,
      message: alert.message,
      piece: alert.piece ?? "",
      appareilId: alert.appareilId,
      sourceValue: stringifyValeur(alert.sourceValue),
      read: false,
      createdAt: new Date(),
    });

  console.log("[Alert]", alert.type, "-", alert.title);
  return true;
}

export async function logAccess(db, entry) {
  await db.collection("accessLogs").add({
    userId: entry.userId,
    uid: normalizeUid(entry.uid),
    granted: entry.granted === true,
    appareilId: entry.appareilId ?? "",
    piece: entry.piece ?? "",
    label: entry.label ?? "",
    createdAt: new Date(),
  });
}

/**
 * Évalue les règles d’alerte après changement de `valeur` sur un capteur.
 */
export async function evaluateSensorChange(
  db,
  userId,
  appareilId,
  data,
  { cooldownMs, defaultTempThreshold }
) {
  if (!isSensor(data)) return;

  const type = normalizeType(data.type);
  const valeur = data.valeur;
  const piece = String(data.piece ?? data.label ?? "").trim();
  const label = String(data.label ?? appareilId).trim();

  if (type === "PIR") {
    if (!truthyValeur(valeur)) return;
    await createAlert(
      db,
      userId,
      {
        type: "intrusion",
        severity: "high",
        title: "Mouvement détecté",
        message: `${label}${piece ? ` (${piece})` : ""} — mouvement détecté`,
        piece,
        appareilId,
        sourceValue: valeur,
      },
      cooldownMs
    );
    return;
  }

  if (type === "DHT" || type === "DHT22" || type === "DHT_TEMP") {
    const temp = parseDhtTemp(valeur);
    if (temp == null) return;
    const threshold = await readAlertThreshold(db, userId, defaultTempThreshold);
    if (temp <= threshold) return;
    await createAlert(
      db,
      userId,
      {
        type: "temperature",
        severity: "medium",
        title: "Température élevée",
        message: `${label}${piece ? ` (${piece})` : ""} : ${temp} °C (seuil ${threshold} °C)`,
        piece,
        appareilId,
        sourceValue: valeur,
      },
      cooldownMs
    );
    return;
  }

  if (type === "RFID") {
    const uid = normalizeUid(valeur);
    if (!uid) return;
    const allowed = await isUidAuthorized(db, userId, uid);
    await logAccess({
      userId,
      uid,
      granted: allowed,
      appareilId,
      piece,
      label,
    });
    if (allowed) {
      console.log("[RFID] accès autorisé", uid);
      return;
    }
    await createAlert(
      db,
      userId,
      {
        type: "rfid_denied",
        severity: "high",
        title: "Badge non autorisé",
        message: `${label}${piece ? ` (${piece})` : ""} — UID ${uid} refusé`,
        piece,
        appareilId,
        sourceValue: uid,
      },
      cooldownMs
    );
  }
}
