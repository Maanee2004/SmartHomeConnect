import process from "node:process";

import admin from "firebase-admin";
import mqtt from "mqtt";

import {
  evaluateSensorChange,
  isActuator,
  isSensor,
  stringifyValeur,
} from "./alerts.js";
import { loadConfig, loadServiceAccount } from "./config.js";

const config = loadConfig();
const { houseUserId, alertCooldownMs, defaultTempThreshold, mqtt: mqttCfg } =
  config;

admin.initializeApp({
  credential: admin.credential.cert(loadServiceAccount()),
});

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const appareilsCol = db
  .collection("maisons")
  .doc(houseUserId)
  .collection("appareils");

const isonlineRef = db
  .collection("maisons")
  .doc(houseUserId)
  .collection("isonline")
  .doc("isonline");

/** @type {Map<string, string>} */
const lastValeurByDoc = new Map();

const alertOpts = { cooldownMs: alertCooldownMs, defaultTempThreshold };

function publishMqtt(client, topic, payload) {
  client.publish(topic, payload, { qos: 1, retain: false }, (err) => {
    if (err) console.error("[MQTT] publish error", topic, err.message ?? err);
    else console.log("[MQTT]", topic, "->", payload);
  });
}

async function setHouseOnline(online) {
  await isonlineRef.set(
    { isonline: online, updatedAt: FieldValue.serverTimestamp() },
    { merge: true }
  );
}

async function applySensorMqttPayload(payloadText) {
  let msg;
  try {
    msg = JSON.parse(payloadText);
  } catch {
    console.warn("[MQTT] sensor payload JSON invalide:", payloadText);
    return;
  }

  const appareilId = String(msg.id ?? msg.appareilId ?? "").trim();
  if (!appareilId) {
    console.warn("[MQTT] sensor sans id:", payloadText);
    return;
  }

  const patch = {
    userId: houseUserId,
    valeur: msg.valeur ?? msg.value ?? "0",
    timestamp: FieldValue.serverTimestamp(),
  };
  if (msg.type) patch.type = String(msg.type).trim().toUpperCase();
  if (msg.piece) patch.piece = String(msg.piece).trim();
  if (msg.label) patch.label = String(msg.label).trim();
  if (msg.categorie) patch.categorie = String(msg.categorie).trim();

  const ref = appareilsCol.doc(appareilId);
  await ref.set(patch, { merge: true });
  // Les alertes sont évaluées par l’écoute Firestore (évite les doublons).
}

async function handleAppareilChange(client, change) {
  if (change.type === "removed") {
    lastValeurByDoc.delete(change.doc.id);
    return;
  }

  const appareilId = change.doc.id;
  const data = change.doc.data() ?? {};
  const valeur = data.valeur;
  if (valeur == null) return;

  const serialized = stringifyValeur(valeur);
  const prev = lastValeurByDoc.get(appareilId);
  if (prev === serialized) return;
  lastValeurByDoc.set(appareilId, serialized);

  if (isActuator(data)) {
    const pin = Number(data.pin);
    if (!Number.isFinite(pin)) return;
    publishMqtt(
      client,
      mqttCfg.topicGpio,
      JSON.stringify({
        id: appareilId,
        pin,
        valeur,
        type: data.type,
        categorie: data.categorie ?? "actionneur",
      })
    );
    return;
  }

  if (isSensor(data)) {
    await evaluateSensorChange(db, houseUserId, appareilId, data, alertOpts);
  }
}

function startFirestoreListeners(client) {
  let initialLoad = true;

  appareilsCol.onSnapshot(
    async (snap) => {
      if (initialLoad) {
        for (const doc of snap.docs) {
          const data = doc.data() ?? {};
          if (data.valeur != null) {
            lastValeurByDoc.set(doc.id, stringifyValeur(data.valeur));
          }
        }
        initialLoad = false;
        console.log(
          `[Firestore] état initial — ${lastValeurByDoc.size} appareil(s)`
        );
        return;
      }

      for (const change of snap.docChanges()) {
        try {
          await handleAppareilChange(client, change);
        } catch (err) {
          console.error("[Firestore] appareil change error", err);
        }
      }
    },
    (err) => console.error("[Firestore] appareils snapshot error", err)
  );

  console.log(
    `[Firestore] écoute maisons/${houseUserId}/appareils (+ alerts)`
  );
}

function startMqttBridge() {
  const client = mqtt.connect({
    host: mqttCfg.host,
    port: mqttCfg.port,
    protocol: "mqtts",
    username: mqttCfg.username,
    password: mqttCfg.password,
    clientId: mqttCfg.clientId,
    keepalive: 30,
    reconnectPeriod: 2000,
    clean: true,
  });

  client.on("connect", () => {
    console.log(`[MQTT] connecté ${mqttCfg.host}:${mqttCfg.port}`);
    client.subscribe([mqttCfg.topicSensor, mqttCfg.topicLwt], { qos: 1 }, (err) => {
      if (err) console.error("[MQTT] subscribe error", err);
      else {
        console.log("[MQTT] abonné", mqttCfg.topicSensor, mqttCfg.topicLwt);
      }
    });
  });

  client.on("reconnect", () => console.log("[MQTT] reconnexion…"));
  client.on("error", (err) => console.error("[MQTT] error", err));

  client.on("message", async (topic, payloadBuf) => {
    const payload = payloadBuf.toString("utf8");
    try {
      if (topic === mqttCfg.topicLwt) {
        const online = payload.trim() === "1";
        await setHouseOnline(online);
        console.log("[MQTT] ESP32", online ? "en ligne" : "hors ligne");
        return;
      }

      if (topic === mqttCfg.topicSensor) {
        await applySensorMqttPayload(payload);
      }
    } catch (err) {
      console.error("[MQTT] message handler error", err);
    }
  });

  startFirestoreListeners(client);

  console.log("[Bridge] actif — maison:", houseUserId);
  console.log("[Bridge] capteurs MQTT ->", mqttCfg.topicSensor);
  console.log("[Bridge] actionneurs Firestore ->", mqttCfg.topicGpio);
  console.log("[Bridge] alertes -> maisons/" + houseUserId + "/alerts");
}

startMqttBridge();

process.on("SIGINT", () => {
  console.log("[Bridge] arrêt");
  process.exit(0);
});
