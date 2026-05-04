# Smart Home — Architecture IoT temps réel (Event‑Driven)

Ce repo contient une **infrastructure IoT de bout en bout en temps réel**.  
Objectif: **éviter le polling** (interroger la DB toutes les X secondes) en utilisant un modèle **Event‑Driven** (piloté par les événements).

## Résumé de l’architecture (ce qui est fait)

Pipeline de communication:

Flutter App ↔ Firebase Firestore ↔ Node.js (Bridge) ↔ MQTT Broker (HiveMQ) ↔ ESP32 ↔ Arduino Mega

Points clés:
- **Firestore = source de vérité** pour l’état souhaité + historique
- **Node bridge** écoute Firestore en push et publie sur MQTT
- Le matériel répond via un topic MQTT de feedback (pour confirmer la réception)

## Specs techniques

### A) Stockage — Firebase Firestore (source de vérité)

Structure attendue:
- **Collection** `maison`
  - **Document** `led_status`
    - champ `etat`: `0` ou `1`
  - **Document** `device_status`
    - champ `online`: `true/false` (supervision online/offline)
- **Collection** `historique_maison`
  - logs de chaque action (commande / feedback / LWT)

Mécanisme:
- côté bridge: écoute “temps réel” (snapshot)
- côté Flutter: stream Firestore (push)

### B) Transport — MQTT (HiveMQ)

Broker (TLS):
- host: `broker.hivemq.com`
- port: `8883`

Topics:
- **Commande**: `maison/led`
  - payload: `"1"` (ON), `"0"` (OFF)
- **Feedback**: `maison/led/status`
  - payload libre (ex: `"ACK"`, `"1"`, etc.)
- **Online/Offline (LWT)**: `maison/online`
  - payload: `"1"` (online), `"0"` (offline)

### C) Middleware — Node.js bridge (orchestrateur)

Le bridge ne “dort” jamais:
- Firestore → MQTT: quand `maison/led_status.etat` change, publish sur `maison/led`
- MQTT → Firestore:
  - `maison/led/status` → met à jour `maison/led_status.last_ack`
  - `maison/online` → met à jour `maison/device_status.online`
  - ajoute un log dans `historique_maison`

Code: `backend/node-bridge/`

### D) Hardware

- **ESP32**: Wi‑Fi + TLS + MQTT, parse les payloads
- **Arduino Mega**: reçoit les ordres via UART et pilote les actionneurs (LED, futurs relais)

## Roadmap (PoC → produit)

### Mobile (Frontend)
- Dashboard final: UI plus riche + capteurs (ex: température DHT22)
- Feedback: afficher “online/offline” basé sur Firestore `device_status.online`
- Afficher le dernier feedback matériel (ex: `led_status.last_ack`)

### Backend / Supervision
- LWT complet côté ESP32 (broker notifie en cas de débranchement)
- Sécurité: Firestore Rules pour limiter l’écriture à l’utilisateur authentifié

### Hardware
- UART final (ESP32 TX ↔ Mega RX)
- Gestion erreurs: LED diagnostic sur ESP32 si Wi‑Fi perdu

## Lancer le bridge Node.js

Pré-requis:
- Node.js >= 18
- Un Service Account Firebase (fichier JSON)

Dans `backend/node-bridge/`:

1) Copier `.env.example` vers `.env` et renseigner `FIREBASE_SERVICE_ACCOUNT_PATH`.
2) Installer les dépendances:
   - `npm install`
3) Lancer:
   - `npm start`

## Lancer l’app Flutter

Assure-toi d’avoir configuré Firebase sur Android/iOS (google-services / plist), puis:
- `flutter pub get`
- `flutter run`
