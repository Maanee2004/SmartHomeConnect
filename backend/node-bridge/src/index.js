import fs from "node:fs";
import path from "node:path";
import process from "node:process";

import "dotenv/config";
import admin from "firebase-admin";
import mqtt from "mqtt";

function requireEnv(name) {
  const v = process.env[name];
  if (!v || String(v).trim() === "") {
    throw new Error(`Missing env var: ${name}`);
  }
  return v;
}

function toInt01(value) {
  if (value === 0 || value === 1) return value;
  if (value === true) return 1;
  if (value === false) return 0;
  if (typeof value === "string") {
    const s = value.trim();
    if (s === "1" || s.toLowerCase() === "on" || s.toLowerCase() === "true")
      return 1;
    if (s === "0" || s.toLowerCase() === "off" || s.toLowerCase() === "false")
      return 0;
  }
  return null;
}

const serviceAccountPath = requireEnv("FIREBASE_SERVICE_ACCOUNT_PATH");
const homeId = process.env.FIRESTORE_HOME_ID || "maison";

const mqttHost = process.env.MQTT_HOST || "broker.hivemq.com";
const mqttPort = Number(process.env.MQTT_PORT || "8883");
const mqttUsername = process.env.MQTT_USERNAME || undefined;
const mqttPassword = process.env.MQTT_PASSWORD || undefined;
const mqttClientId = process.env.MQTT_CLIENT_ID || "smart-home-bridge";

const topicCommand = process.env.MQTT_TOPIC_COMMAND || "maison/led";
const topicFeedback = process.env.MQTT_TOPIC_FEEDBACK || "maison/led/status";
const topicLwt = process.env.MQTT_TOPIC_LWT || "maison/online";

const serviceAccountAbs = path.isAbsolute(serviceAccountPath)
  ? serviceAccountPath
  : path.resolve(process.cwd(), serviceAccountPath);

if (!fs.existsSync(serviceAccountAbs)) {
  throw new Error(
    `Service account JSON not found: ${serviceAccountAbs}\n` +
      `Download it from Firebase Console -> Project settings -> Service accounts.`
  );
}

admin.initializeApp({
  credential: admin.credential.cert(
    JSON.parse(fs.readFileSync(serviceAccountAbs, "utf8"))
  ),
});

const db = admin.firestore();
const ledRef = db.collection(homeId).doc("led_status");
const deviceStatusRef = db.collection(homeId).doc("device_status");
const historyCol = db.collection(`historique_${homeId}`);

const client = mqtt.connect({
  host: mqttHost,
  port: mqttPort,
  protocol: "mqtts",
  username: mqttUsername,
  password: mqttPassword,
  clientId: mqttClientId,
  keepalive: 30,
  reconnectPeriod: 2000,
  clean: true,
  will: {
    topic: topicLwt,
    payload: "0",
    qos: 1,
    retain: true,
  },
});

let lastPublishedEtat = null;

async function logHistory(event) {
  await historyCol.add({
    ...event,
    ts: admin.firestore.FieldValue.serverTimestamp(),
  });
}

client.on("connect", async () => {
  console.log(`[MQTT] connected ${mqttHost}:${mqttPort}`);
  client.publish(topicLwt, "1", { qos: 1, retain: true });
  await deviceStatusRef.set({ online: true }, { merge: true });

  client.subscribe([topicFeedback, topicLwt], { qos: 1 }, (err) => {
    if (err) console.error("[MQTT] subscribe error", err);
    else console.log("[MQTT] subscribed", topicFeedback, topicLwt);
  });
});

client.on("reconnect", () => console.log("[MQTT] reconnecting..."));

client.on("close", async () => {
  console.log("[MQTT] connection closed");
  await deviceStatusRef.set({ online: false }, { merge: true });
});

client.on("error", (err) => console.error("[MQTT] error", err));

client.on("message", async (topic, payloadBuf) => {
  const payload = payloadBuf.toString("utf8");
  if (topic === topicLwt) {
    const online = payload.trim() === "1";
    await deviceStatusRef.set({ online }, { merge: true });
    await logHistory({ source: "mqtt", type: "lwt", online, payload });
    return;
  }

  if (topic === topicFeedback) {
    await ledRef.set(
      { last_ack: payload.trim(), last_ack_at: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );
    await logHistory({ source: "mqtt", type: "feedback", payload });
  }
});

// Firestore -> MQTT (onSnapshot equivalent in Admin SDK)
ledRef.onSnapshot(
  async (snap) => {
    const data = snap.data() || {};
    const etat = toInt01(data.etat);
    if (etat == null) return;
    if (etat === lastPublishedEtat) return;

    lastPublishedEtat = etat;
    const payload = String(etat);
    client.publish(topicCommand, payload, { qos: 1, retain: false }, async (err) => {
      if (err) console.error("[MQTT] publish error", err);
      else console.log(`[MQTT] publish ${topicCommand} -> ${payload}`);
    });

    await logHistory({ source: "firestore", type: "command", etat });
  },
  (err) => console.error("[Firestore] snapshot error", err)
);

console.log("[Bridge] running (Firestore <-> MQTT)");

