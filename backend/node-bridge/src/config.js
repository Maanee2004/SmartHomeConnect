import fs from "node:fs";
import path from "node:path";
import process from "node:process";

import "dotenv/config";

export function requireEnv(name) {
  const v = process.env[name];
  if (!v || String(v).trim() === "") {
    throw new Error(`Missing env var: ${name}`);
  }
  return String(v).trim();
}

export function env(name, fallback = "") {
  const v = process.env[name];
  if (v == null || String(v).trim() === "") return fallback;
  return String(v).trim();
}

export function envInt(name, fallback) {
  const n = Number(process.env[name]);
  return Number.isFinite(n) ? n : fallback;
}

export function topicFromTemplate(template, userId) {
  return template.replaceAll("{userId}", userId);
}

export function loadServiceAccount() {
  const serviceAccountPath = requireEnv("FIREBASE_SERVICE_ACCOUNT_PATH");
  const abs = path.isAbsolute(serviceAccountPath)
    ? serviceAccountPath
    : path.resolve(process.cwd(), serviceAccountPath);

  if (!fs.existsSync(abs)) {
    throw new Error(
      `Service account JSON not found: ${abs}\n` +
        "Download it from Firebase Console -> Project settings -> Service accounts."
    );
  }

  return JSON.parse(fs.readFileSync(abs, "utf8"));
}

export function loadConfig() {
  const houseUserId = requireEnv("HOUSE_USER_ID");

  return {
    houseUserId,
    alertCooldownMs: envInt("ALERT_COOLDOWN_MS", 30_000),
    defaultTempThreshold: envInt("DEFAULT_TEMP_THRESHOLD", 35),
    mqtt: {
      host: env("MQTT_HOST", "broker.hivemq.com"),
      port: envInt("MQTT_PORT", 8883),
      username: env("MQTT_USERNAME") || undefined,
      password: env("MQTT_PASSWORD") || undefined,
      clientId: env("MQTT_CLIENT_ID", "smart-home-bridge"),
      topicSensor: topicFromTemplate(
        env("MQTT_TOPIC_SENSOR", "maison/{userId}/sensor"),
        houseUserId
      ),
      topicGpio: topicFromTemplate(
        env("MQTT_TOPIC_GPIO", "maison/{userId}/gpio"),
        houseUserId
      ),
      topicLwt: topicFromTemplate(
        env("MQTT_TOPIC_LWT", "maison/{userId}/online"),
        houseUserId
      ),
    },
  };
}
