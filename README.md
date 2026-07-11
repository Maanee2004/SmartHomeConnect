# Smart Home Connect

Application mobile **Flutter** de gestion de maison connectée — projet académique aligné sur un diagramme de classes UML et une base **Firebase Firestore**.

**Smart Home Connect** permet de piloter pièces et appareils IoT (capteurs + actionneurs), gérer les utilisateurs (interface admin) et préparer l’intégration Arduino via Firestore comme source de vérité.

---

## Sommaire

| Document | Contenu |
|----------|---------|
| [docs/DOCUMENTATION.md](docs/DOCUMENTATION.md) | Documentation technique complète |
| [docs/FIRESTORE.md](docs/FIRESTORE.md) | Schéma base de données + exemples JSON |
| [docs/GUIDE.md](docs/GUIDE.md) | Guide utilisateur et administrateur |

---

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Application | **Flutter** (Dart 3+) — Android, iOS, Web |
| Base de données | **Cloud Firestore** |
| Auth technique Firebase | **Firebase Auth anonyme** (accès Firestore) |
| Auth applicative | Collection `users` + mot de passe **bcrypt** |
| Backend IoT (prévu) | **Node.js** + MQTT (`backend/node-bridge/`) |
| Matériel (prévu) | Arduino Mega + ESP32 |

---

## Démarrage rapide

### Prérequis

- Flutter SDK ≥ 3.0
- Compte Firebase + projet configuré (`flutterfire configure`)
- Fichiers : `android/app/google-services.json`, `lib/firebase_options.dart`

### Installation

```bash
git clone <url-du-repo>
cd smart_home
flutter pub get
flutter run
```

### Firebase

1. Activer **Firestore** et **Authentication** (méthode **Anonyme** activée).
2. Déployer les règles :

```bash
firebase deploy --only firestore:rules
```

3. Créer un **admin** manuellement dans la console Firestore :

```
Collection : users/{userId}
Champ      : role = "admin"
```

Le `userId` est généré à l’inscription (ex. `usr_jean` pour `jean@mail.com`).

---

## Fonctionnalités principales

### Utilisateur (`role: user`)

- Connexion email ou téléphone + mot de passe
- Dashboard : appareils par pièce, commandes ON/OFF
- Ajout / renommage de pièces
- Profil : thème, langue, police, taille de texte
- Paramètres : cartes RFID autorisées

### Administrateur (`role: admin`)

- Gestion des **maisons** et **utilisateurs**
- CRUD appareils, broches GPIO, suppression pièces
- Seed données de démo
- Édition profil / mot de passe / rattachement maison

---

## Arborescence Firestore (résumé)

```
Firestore Root
 ├── users/{userId}
 │    ├── preferences/settings   ← pièces, thème, membres
 │    └── rfidCards/{cardId}     ← badges autorisés
 ├── appareils/{sensorId}        ← capteurs + actionneurs
 ├── accessLogs/{logId}          ← (schéma prêt, UI à venir)
 └── alerts/{alertId}            ← (schéma prêt, UI à venir)
```

---

## Types d’appareils supportés

| Type | Rôle | Exemple `unit` |
|------|------|----------------|
| DHT | Température + humidité | `celsius/%` |
| PIR | Mouvement | `booleen` |
| RFID | Lecteur badge (UID) | `uid` |
| ULTRA | Distance ultrason | `cm` |
| RELAIS / LAMPE / MOTEUR | ON/OFF | `booleen` |
| SERVO | Porte (lien RFID optionnel) | `booleen` |
| MAX | Matrice LED MAX7219 | `booleen` |

Détail des champs : [docs/FIRESTORE.md](docs/FIRESTORE.md).

---

## Structure du code (`lib/`)

```
lib/
├── main.dart                 # Point d’entrée, routage login / user / admin
├── models/                   # AppUser, Device, AppareilSpec, RfidCard…
├── services/
│   ├── firestore_home_repository.dart   # Pièces, appareils, commandes
│   ├── firestore_auth_repository.dart   # Login, inscription, admin users
│   ├── auth_service.dart                # Session locale + rôles
│   └── rfid_cards_repository.dart       # Badges RFID
├── screens/
│   ├── auth/                 # Login, inscription
│   ├── home/                 # Shell utilisateur (dashboard, pièces, profil)
│   ├── dashboard/            # Grille appareils + ajout
│   └── admin/                # Shell administrateur
└── widgets/                  # DeviceCard, AppBrandHeader…
```

---

## Tests

```bash
flutter test
```

Tests unitaires : `test/appareil_spec_test.dart` (schéma appareils, parsing Firestore).

---

## Backend Node (bridge MQTT)

Le dossier `backend/node-bridge/` contient un orchestrateur Firestore ↔ MQTT pour l’Arduino. **Non branché en production** dans l’app Flutter actuelle (l’app écrit directement dans Firestore).

```bash
cd backend/node-bridge
cp .env.example .env
npm install
npm start
```

---

## État d’avancement

| Zone | État |
|------|------|
| Auth + rôles user/admin | ✅ |
| CRUD pièces / appareils | ✅ |
| Temps réel Firestore | ✅ |
| Cartes RFID | ✅ |
| Schéma ULTRA, MAX, SERVO, DHT… | ✅ |
| Règles Firestore sécurisées | ⚠️ Ouvertes (`if true`) — prod à durcir |
| Bridge Arduino / MQTT live | 🔜 Équipe hardware |
| accessLogs, alerts (UI) | 🔜 |
| API REST (`rest_home_repository`) | Stub non utilisé |

---

## Licence & contexte

Projet académique — soutenance / mémoire maison connectée.

Pour le détail technique complet : **[docs/DOCUMENTATION.md](docs/DOCUMENTATION.md)**.
