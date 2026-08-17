# IN CRYPT Chat — App Flutter + Firebase + Cloudinary (100% gratuit)

Application de messagerie pour les étudiants IN CRYPT Codage : discussions
privées, groupes, fil de publications (façon Facebook), partage d'images et
de documents, photo de profil. Connexion via **compte Google** (Firebase
Auth).

Ce dépôt contient le **code source complet**, prêt à être ouvert dans un
environnement Flutter. Il n'a pas été compilé ni testé dans cet environnement
(pas d'accès à pub.dev / Firebase / Cloudinary ici) — à faire de ton côté en
suivant les étapes ci-dessous.

**Ce projet ne nécessite aucune carte bancaire, nulle part.**

## Pourquoi Cloudinary et pas Firebase Storage ?

Depuis février 2026, Google exige que tout projet utilisant Firebase Storage
soit sur le forfait payant Blaze (même si l'usage réel reste gratuit — il
faut simplement une carte enregistrée). Pour éviter ça complètement, ce
projet envoie les images et documents vers **Cloudinary** à la place :
un service d'hébergement de médias avec un forfait gratuit généreux (25
"crédits" par mois, largement suffisant pour un groupe d'étudiants) et
**aucune carte bancaire requise**, même à l'inscription.

Firebase reste utilisé pour tout le reste (connexion Google, base de
données des messages/publications) — ces services-là sont restés gratuits
sans condition.

## Fichiers de configuration Android (dossier `android_config/`)

Ce zip contient un dossier `android_config/` avec les 3 fichiers Gradle déjà
préparés avec les bonnes versions (Gradle 9.1.0, AGP 9.0.1, Kotlin 2.3.20 —
celles que Flutter recommande actuellement) et les personnalisations déjà
faites (clé de signature release, minification désactivée). Une fois ton
projet créé avec `flutter create .`, copie-les à ces emplacements exacts,
en écrasant les fichiers générés automatiquement :

- `android_config/settings.gradle.kts` → `android/settings.gradle.kts`
- `android_config/app_build.gradle.kts` → `android/app/build.gradle.kts`
- `android_config/gradle-wrapper.properties` → `android/gradle/wrapper/gradle-wrapper.properties`

⚠️ Il te faudra aussi régénérer ta clé de signature (le fichier
`release-key.jks` n'est pas inclus ici, il ne se transmet pas comme du code) :

```powershell
keytool -genkeypair -v -keystore android\app\release-key.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias icc_release -storepass iccChat2026 -keypass iccChat2026 -dname "CN=IN CRYPT Codage, OU=IN CRYPT, O=IN CRYPT, L=Ouagadougou, S=Centre, C=BF"
```

## 1. Pré-requis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installé
- Un compte Google + un projet créé sur la [console Firebase](https://console.firebase.google.com)
- Un compte gratuit sur [cloudinary.com](https://cloudinary.com) (inscription par email, aucune carte demandée)
- Firebase CLI : `npm install -g firebase-tools` (pour déployer les règles Firestore)

## 2. Configurer Cloudinary (2 minutes)

1. Crée un compte gratuit sur [cloudinary.com](https://cloudinary.com/users/register_free).
2. Une fois connecté, ton **"Cloud name"** est affiché en haut du tableau de
   bord — note-le.
3. Va dans ⚙️ **Settings → Upload**, descends jusqu'à "Upload presets", clique
   sur **"Add upload preset"**.
4. Mets un nom simple, ex. `icc_chat_unsigned`.
5. Change **"Signing Mode"** de "Signed" à **"Unsigned"** (c'est ce qui
   permet à l'app d'envoyer des fichiers directement, sans clé secrète
   côté client).
6. Facultatif mais recommandé pour la sécurité : dans "Upload Manipulations
   and Restrictions", tu peux limiter les formats autorisés et la taille
   max de fichier, pour éviter les abus puisque ce preset est public.
7. Enregistre.
8. Ouvre `lib/services/storage_service.dart` dans le projet, et remplace :
   ```dart
   static const String _cloudName = 'TON_CLOUD_NAME';
   static const String _uploadPreset = 'icc_chat_unsigned';
   ```
   par tes propres valeurs.

## 3. Créer le projet Firebase

Sur [console.firebase.google.com](https://console.firebase.google.com),
crée un projet. Tu peux désactiver Google Analytics à la création — l'app
ne l'utilise pas.

## 4. Activer les services Firebase nécessaires (gratuits, sans carte)

- **Authentication** → onglet "Sign-in method" → active le fournisseur
  **"Google"**.
- **Firestore Database** → créer une base (mode production).

(Pas besoin d'activer "Storage" — ce projet ne l'utilise plus.)

## 5. Relier le projet Flutter à Firebase

```bash
flutter pub get
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Choisis ton projet Firebase et les plateformes visées (Android / iOS / Web).
Ça remplace `lib/firebase_options.dart` (actuellement un placeholder) par
tes vraies clés.

## 6. Configuration spécifique à Google Sign-In

### Android
1. Récupère l'empreinte SHA-1 de ta clé de débogage :
   ```bash
   cd android && ./gradlew signingReport
   ```
   (sur Windows : `gradlew signingReport`)
2. Copie la valeur `SHA1` affichée sous `debugAndroidTest` ou `debug`.
3. Dans la console Firebase → ⚙️ Paramètres du projet → tes applications →
   sélectionne l'app Android → "Ajouter une empreinte" → colle le SHA-1.
4. Retélécharge `google-services.json` (bouton dans les paramètres de
   l'app) et remplace le fichier dans `android/app/`.
5. Répète l'opération avec l'empreinte SHA-1 de ta **clé de release** avant
   de publier sur le Play Store.

### iOS
1. Dans la console Firebase → Paramètres du projet → ton app iOS →
   télécharge `GoogleService-Info.plist` et place-le dans `ios/Runner/`.
2. Ouvre `ios/Runner/Info.plist` et ajoute un `URL Scheme` avec la valeur
   `REVERSED_CLIENT_ID` trouvée dans `GoogleService-Info.plist`.

## 7. Déployer les règles de sécurité Firestore

```bash
firebase deploy --only firestore:rules
```

## 8. Lancer l'application

```bash
flutter run
```

## Modèle de données Firestore

```
users/{uid}
  username: string     (nom Google au départ, modifiable ensuite)
  email: string
  photoUrl: string | null   (URL Cloudinary après le premier changement de photo)
  createdAt: timestamp

chats/{chatId}
  isGroup: bool
  name: string             (vide pour un DM, rempli pour un groupe)
  memberIds: [uid, ...]
  lastMessage: string
  lastMessageAt: timestamp
  chats/{chatId}/messages/{messageId}
    senderId, senderName, type ('text'|'image'|'file')
    text, mediaUrl (URL Cloudinary), fileName, createdAt

posts/{postId}
  authorId, authorName, authorPhoto
  text, imageUrl (URL Cloudinary)
  likes: [uid, ...]
  commentCount: number
  createdAt: timestamp
  posts/{postId}/comments/{commentId}
    authorId, authorName, text, createdAt
```

## Où sont stockés les fichiers sur Cloudinary

```
profile_photos/{uid}/...
post_images/{postId}/...
chat_files/{chatId}/...
```
(organisation en dossiers, visible dans le tableau de bord Cloudinary → Media Library)

## Arborescence du projet

```
lib/
  main.dart                 point d'entrée, gère la connexion auto
  theme.dart                couleurs et typographies (identiques au site web)
  models.dart                AppUser, ChatMessage, ChatThread, Post, PostComment
  widgets.dart               avatar, indicateurs partagés
  services/
    auth_service.dart        connexion / déconnexion Google
    firestore_service.dart   discussions, groupes, publications, commentaires
    storage_service.dart     envoi des images/fichiers/photos de profil vers Cloudinary
  screens/
    auth_screen.dart         écran de connexion Google
    home_shell.dart          navigation à 4 onglets (Discussions, Groupes, Publications, Profil)
    chat_screen.dart         conversation (texte, image, document)
firestore.rules
```

## Ce qu'il reste à faire de ton côté

- Créer le compte Cloudinary et renseigner `_cloudName` / `_uploadPreset`
  dans `lib/services/storage_service.dart` (voir étape 2) — sans ça, les
  envois d'images/fichiers échoueront.
- Exécuter `flutterfire configure` avec ton propre projet Firebase.
- Activer le fournisseur "Google" dans Authentication.
- Configurer le SHA-1 (Android) et l'URL scheme (iOS) — voir étape 6.
- Personnaliser l'icône de l'app et le nom affiché.
- Tester sur un vrai appareil / émulateur — je n'ai pas pu compiler le projet
  dans cet environnement.
