# Guide utilisateur — Smart Home Connect

## Première utilisation

### 1. Créer un compte

1. Ouvre l’app → **S’inscrire**.
2. Renseigne prénom, nom, **email**, **téléphone** et mot de passe (6 caractères min.).
3. Tu es connecté automatiquement après inscription.

### 2. Se connecter

- **Email** ou **téléphone** + mot de passe.
- Option **Se souvenir de moi** pour préremplir l’identifiant.

### 3. Devenir administrateur

L’app ne crée pas d’admin automatiquement. Un responsable doit :

1. T’inscrire normalement.
2. Ouvrir Firebase Console → Firestore → `users/ton_userId`.
3. Ajouter le champ : `"role": "admin"`.
4. Te déconnecter / reconnecter → interface **Maisons · Utilisateurs · Profil**.

---

## Guides (Paramètres)

### Guide propriétaire

Accessible via **Paramètres → Guides utilisateur → Guide propriétaire**.

Le propriétaire gère **en autonomie** (sans déplacement de l’admin) :

| Action | Menu |
|--------|------|
| Pièces | Onglet **Pièces** → + / crayon |
| Appareils | **Accueil** → + / déplacer / supprimer |
| Invités | **Paramètres** → **Mes invités** |
| RFID | **Paramètres** → **Accès RFID & portes** |
| Stats conso | Bandeau **Tableau de bord** sur l’Accueil |
| Accès mobile | **Paramètres** → **Accès mobile (Wi‑Fi)** |

**Réservé à l’admin plateforme** (à distance) : création de compte, promotion en propriétaire, suppression de maison.

### Guide invité (membre)

- Pilotage ON/OFF uniquement
- **Profil** → Quitter la maison

### Guide utilisateur standard

- Ajout pièces / appareils si compte actif
- Demander le rôle **propriétaire** à l’admin pour gestion complète
- **Rejoindre une maison** via code 5 chiffres

---

## Interface utilisateur

### Accueil (Dashboard)

- Affiche les **appareils** de la pièce sélectionnée (défaut : Salon).
- Menu **⋮** en haut : changer de pièce.
- Bouton **+** : ajouter un capteur ou un actionneur (utilisateurs connectés, sauf invités).
- Icône **déplacer** sur une carte : changer la pièce de l’appareil.
- **Tableau de bord** : nombre d’appareils allumés, total, consommation estimée.
- **Guide détaillé** : Paramètres → **Guide : ajouter des appareils**.

### Pièces

- Liste de toutes les pièces.
- **+** : ajouter une pièce (utilisateurs connectés, sauf invités).
- **Crayon** : renommer une pièce (propriétaire / admin).

### Profil

- Nom, email, téléphone.
- **Thème** clair / sombre.
- **Langue** : français, anglais, arabe.
- **Police** et **taille du texte**.
- **Déconnexion**.

### Paramètres

- **Cartes RFID** : gérer les badges autorisés (UID + nom).
- Notifications : à brancher (toggle présent).

---

## Interface administrateur

### Maisons

- Liste des utilisateurs ayant au moins une pièce ou un appareil.
- Tap sur une maison → **dashboard admin** de cette maison (CRUD appareils).

### Utilisateurs

- **+** : créer un utilisateur (email, téléphone, mot de passe, rattachement maison optionnel).
- Tap sur un utilisateur :
  - Modifier profil / mot de passe
  - Rattacher / détacher d’une maison
  - **Supprimer** (si pas d’appareils restants)

### Gestion des appareils (dashboard admin)

- Bouton **+** : ajouter capteur ou actionneur.
- Types disponibles :

| Catégorie | Types |
|-----------|-------|
| Capteurs | DHT, PIR, RFID, Ultrason (ULTRA) |
| Actionneurs | Lampe, Relais, Moteur, LED, Servo porte, Matrice MAX |

- Chaque ajout demande une **broche GPIO** (2–53).
- **Servo** : lien RFID optionnel (`rfid_cible`).
- **Seed démo** : bouton pour créer pièces + appareils d’exemple.

### Supprimer une pièce (admin)

Menu ⋮ → corbeille sur la pièce → supprime la pièce **et** tous ses appareils.

---

## Cas d’usage typiques

### Ajouter une lampe dans le salon

1. Admin → ouvrir la maison cible.
2. Sélectionner pièce **Salon** (menu ⋮).
3. **+** → **Lampe** → choisir broche libre → valider.

### Configurer l’accès RFID

1. **Utilisateur** → Paramètres → Cartes RFID → ajouter UID + nom.
2. **Admin** → ajouter capteur **Lecteur RFID** (broche 10).
3. **Admin** → ajouter **Servo porte** → lier au lecteur RFID (optionnel).

### Partager sa maison avec un membre

1. Admin → Utilisateurs → créer ou éditer le membre.
2. **Rattacher à une maison** → choisir le propriétaire.
3. Le membre voit la maison du propriétaire (lecture + commandes).

---

## Dépannage

| Problème | Solution |
|----------|----------|
| Connexion lente puis rien | Vérifier internet, Firebase initialisé, auth anonyme activée |
| « Identifiants incorrects » | Vérifier email/téléphone et mot de passe |
| Appareils ne chargent pas | Hot restart ; admin : ouvrir une maison depuis l’onglet Maisons |
| Broche déjà utilisée | Choisir une autre broche (2–53) |
| Pas d’interface admin | Champ `role: admin` manquant dans Firestore |
| Erreur permission Firestore | Redéployer `firestore.rules` |

---

## Support technique (équipe dev)

- Schéma données : [FIRESTORE.md](FIRESTORE.md)
- Architecture : [DOCUMENTATION.md](DOCUMENTATION.md)
- Tests : `flutter test test/appareil_spec_test.dart`
