# Schéma Firestore — Smart Home Connect

Documentation de la base de données alignée sur le diagramme UML du projet.

---

## Arborescence globale

```
Firestore Root
 ├── users (Collection)
 │    └── {userId} (Document)
 │         ├── rfidCards (Sous-collection)
 │         └── preferences (Sous-collection)
 │              └── settings (Document)
 ├── appareils (Collection)
 ├── accessLogs (Collection)
 └── alerts (Collection)
```

---

## Collection `users`

**Chemin :** `users/{userId}`

### Document utilisateur

```json
{
  "userId": "usr_jean",
  "name": "Jean Dupont",
  "email": "jean@mail.com",
  "phone": "+22370123456",
  "password": "$2b$10$…",
  "role": "user",
  "houseOwnerUserId": null,
  "createdAt": "<timestamp>"
}
```

| Champ | Type | Description |
|-------|------|-------------|
| `userId` | string | Identifiant (souvent = ID document) |
| `name` | string | Nom affiché |
| `email` | string | Email (unique, minuscules) |
| `phone` | string | Téléphone (unique, avec indicatif) |
| `password` | string | Hash bcrypt |
| `role` | string | `"admin"` ou `"user"` |
| `houseOwnerUserId` | string? | Si membre : ID du propriétaire |
| `createdAt` | timestamp | Date création |

### Sous-collection `preferences`

**Chemin :** `users/{userId}/preferences/settings`

```json
{
  "userId": "usr_jean",
  "pieces": [
    { "id": "salon", "name": "Salon" },
    { "id": "garage", "name": "Garage" }
  ],
  "memberUserIds": ["usr_marie"],
  "theme": "dark",
  "notifications": true,
  "language": "fr",
  "fontFamily": "montserrat",
  "fontScale": 1.0,
  "showDateTime": false,
  "use24HourTime": true,
  "datePattern": "dd/MM/yyyy",
  "alertThreshold": 35.0
}
```

### Sous-collection `rfidCards`

**Chemin :** `users/{userId}/rfidCards/{cardId}`

```json
{
  "cardId": "card_ABCD1234",
  "userId": "usr_jean",
  "uid": "ABCD1234",
  "label": "Badge Papa",
  "active": true,
  "createdAt": "<timestamp>"
}
```

---

## Collection `appareils`

**Chemin :** `appareils/{sensorId}`

Chaque document = un capteur **ou** un actionneur.

---

### Capteur DHT (DHT11 / DHT22)

```json
{
  "sensorId": "salon2_temp_rature",
  "type": "DHT",
  "categorie": "capteur",
  "pin": 2,
  "valeur": "24.5/60.2",
  "unit": "celsius/%",
  "piece": "salon2",
  "label": "Capteur Température/Humidité",
  "userId": "usr_jean",
  "timestamp": "<timestamp>"
}
```

> `valeur` = température et humidité concaténées : `"temp/hum"`.

---

### Capteur PIR (mouvement)

```json
{
  "sensorId": "salon2_detecteur_pir",
  "type": "PIR",
  "categorie": "capteur",
  "pin": 4,
  "valeur": "0",
  "unit": "booleen",
  "piece": "salon2",
  "label": "Détecteur PIR",
  "userId": "usr_jean",
  "timestamp": "<timestamp>"
}
```

`"1"` = mouvement détecté → alerte intrusion côté serveur (prévu).

---

### Lecteur RFID (MFRC522)

Capteur **générique** : pousse uniquement l’UID du badge scanné.

```json
{
  "sensorId": "rfid_entree",
  "type": "RFID",
  "categorie": "capteur",
  "pin": 10,
  "valeur": "ABCD1234",
  "unit": "uid",
  "piece": "garage",
  "label": "Lecteur Badge RFID",
  "userId": "usr_jean",
  "timestamp": "<timestamp>"
}
```

> Le lecteur ne connaît pas le servo. La liaison se fait côté SERVO via `rfid_cible`.

---

### Capteur ultrason (HC-SR04)

```json
{
  "sensorId": "ultra_garage",
  "type": "ULTRA",
  "categorie": "capteur",
  "pin": 5,
  "valeur": "45",
  "unit": "cm",
  "piece": "garage",
  "label": "Capteur de Distance",
  "userId": "usr_jean",
  "timestamp": "<timestamp>"
}
```

**Firmware :** `pin` = Trigger, Echo = `pin + 1`.

---

### Actionneurs classiques (RELAIS, LAMPE, MOTEUR)

```json
{
  "actuatorId": "relais_salon",
  "type": "RELAIS",
  "categorie": "actionneur",
  "pin": 3,
  "valeur": "0",
  "unit": "booleen",
  "piece": "salon2",
  "label": "Relais",
  "userId": "usr_jean",
  "lastChanged": "<timestamp>",
  "changedBy": "usr_jean"
}
```

Types équivalents : `LAMPE`, `MOTEUR` — même structure, `unit: booleen`.

---

### Servomoteur porte (SG90)

```json
{
  "actuatorId": "servo_porte",
  "type": "SERVO",
  "categorie": "actionneur",
  "pin": 9,
  "valeur": "0",
  "unit": "booleen",
  "piece": "garage",
  "label": "Servomoteur Portail",
  "rfid_cible": "rfid_entree",
  "userId": "usr_jean",
  "lastChanged": "<timestamp>"
}
```

| Champ | Description |
|-------|-------------|
| `valeur` | `"0"` fermé / `"1"` ouvert |
| `rfid_cible` | ID du doc RFID écouté, ou `""` si aucun |

---

### Matrice LED (MAX7219)

```json
{
  "actuatorId": "matrice_max",
  "type": "MAX",
  "categorie": "actionneur",
  "pin": 7,
  "valeur": "1",
  "unit": "booleen",
  "piece": "salon2",
  "label": "Matrice LED Notification",
  "userId": "usr_jean",
  "lastChanged": "<timestamp>"
}
```

`pin` = broche CS (Chip Select).

---

## Collections futures

### `accessLogs` (prévu)

Journal des accès RFID, mouvements PIR, etc.

### `alerts` (prévu)

Alertes température (seuil `alertThreshold` dans preferences), intrusion, etc.

---

## Règles de sécurité (développement)

Fichier `firestore.rules` — actuellement ouvert pour le dev :

```javascript
match /users/{userId} {
  allow read, write: if true;
  match /rfidCards/{cardId} { allow read, write: if true; }
  match /preferences/{docId} { allow read, write: if true; }
}
match /appareils/{appareilId} { allow read, write: if true; }
match /accessLogs/{logId} { allow read, write: if true; }
match /alerts/{alertId} { allow read, write: if true; }
```

**Production :** restreindre par `userId`, custom claims, ou validation serveur.

---

## Compatibilité legacy

L’app accepte encore en lecture :

- Types `DHT22`, `DHT_TEMP`, `DHT_HUM` (fusion possible en une carte)
- `valeur` numérique (en plus des chaînes `"0"` / `"1"`)
- Ancienne collection conceptuelle `maison/led_status` (bridge Node d’origine — non utilisée par l’app actuelle)

Les **nouveaux** documents doivent suivre la spec ci-dessus.
