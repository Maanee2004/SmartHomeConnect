# Smart Home — Node Bridge

Orchestrateur **Firestore ↔ MQTT** aligné sur le schéma `maisons/{userId}/`.

## Rôle

| Direction | Action |
|-----------|--------|
| **ESP32 → MQTT → Bridge** | Met à jour `maisons/{userId}/appareils/{id}` |
| **Bridge → Firestore** | Crée alertes (`alerts/`) et journaux (`accessLogs/`) |
| **App Flutter → Firestore** | Commande actionneur → Bridge → MQTT GPIO |
| **ESP32 LWT** | Met à jour `maisons/{userId}/isonline/isonline` |

## Alertes automatiques

| Capteur | Condition | Type alerte |
|---------|-----------|-------------|
| PIR | `valeur` = `1` | `intrusion` |
| DHT | temp > `alertThreshold` (prefs utilisateur) | `temperature` |
| RFID | UID absent de `users/{id}/rfidCards` | `rfid_denied` + `accessLogs` |

Anti-spam : 1 alerte max / 30 s par type + appareil (`ALERT_COOLDOWN_MS`).

## Installation

```bash
cd backend/node-bridge
cp .env.example .env
# Placer serviceAccountKey.json dans ce dossier
npm install
npm start
```

## Configuration `.env`

```env
FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
HOUSE_USER_ID=usr_jean
```

## MQTT — payload capteur (ESP32 → bridge)

**Topic :** `maison/{userId}/sensor` (ex. `maison/usr_jean/sensor`)

```json
{
  "id": "pir_salon",
  "type": "PIR",
  "valeur": "1",
  "piece": "Salon",
  "label": "Détecteur PIR"
}
```

## MQTT — commande actionneur (bridge → ESP32)

**Topic :** `maison/{userId}/gpio`

```json
{
  "id": "lampe_salon",
  "pin": 3,
  "valeur": "1",
  "type": "LAMPE",
  "categorie": "actionneur"
}
```

## MQTT — état en ligne ESP32

**Topic :** `maison/{userId}/online` — payload `1` (online) ou `0` (offline, LWT).

## Test sans ESP32

1. Lancer le bridge avec le bon `HOUSE_USER_ID`.
2. Firebase Console → `maisons/{userId}/appareils/pir_test` → modifier `valeur` à `"1"`.
3. Vérifier `maisons/{userId}/alerts/` — une alerte `intrusion` doit apparaître.
