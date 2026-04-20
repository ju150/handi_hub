# HandiHub

Application tablette Android développée dans le cadre d'un projet P2I (ENSC — 2A Groupe 2, Julien Bernard, 2026).

HandiHub est une interface simplifiée, conçue pour une utilisatrice en situation de handicap moteur utilisant un stylet. Elle donne accès à quatre modules : **Lecture** (bibliothèque EPUB), **Rééducation** (kiné, respiration, orthophonie, relaxation), **Discussion** (SMS natif Android) et **Jeux** (4 jeux internes + raccourci vers jeu externe).

---

## Table des matières

1. [Ce que l'on peut tester](#1-ce-que-lon-peut-tester)
2. [Prérequis](#2-prérequis)
3. [Cloner le projet](#3-cloner-le-projet)
4. [Installer les dépendances](#4-installer-les-dépendances)
5. [Configurer l'émulateur tablette](#5-configurer-lémulateur-tablette)
6. [Lancer l'application](#6-lancer-lapplication)
7. [Gestion des secrets et mode dégradé](#7-gestion-des-secrets-et-mode-dégradé)
8. [Test rapide — parcours recommandé](#8-test-rapide--parcours-recommandé)
9. [Dépannage](#9-dépannage)
10. [Structure du projet](#10-structure-du-projet)
11. [Remarques pour l'examinateur](#11-remarques-pour-lexaminateur)

---

## 1. Ce que l'on peut tester

| Module | Testable sans secrets Firebase | Notes |
|---|---|---|
| Hub d'accueil | ✅ Oui | Anti-double-tap, overlay |
| Jeux (4 jeux internes) | ✅ Oui | Touche la Cible, Memory, Match Coloré, Candy Crush |
| Jeux (raccourci Briser des Mots) | ✅ Oui | Ouvre l'app externe si installée |
| Discussion (SMS) | ✅ Oui | Nécessite les permissions SMS sur l'émulateur |
| Rééducation — navigation | ✅ Oui | Les 4 sous-modules s'ouvrent |
| Rééducation — exercices | ⚠️ Cache uniquement | Si aucun cache local, la liste sera vide |
| Lecture — interface | ✅ Oui | L'UI s'affiche correctement |
| Lecture — livres | ⚠️ Cache uniquement | Sans Firebase, aucun livre ne se charge |
| Application admin (React) | ❌ Non | Nécessite les clés Firebase (non versionnées) |

---

## 2. Prérequis

### Outils obligatoires

| Outil | Version | Vérification |
|---|---|---|
| Flutter | ≥ 3.27 (SDK Dart ^3.11) | `flutter --version` |
| Android Studio | ≥ 2023 | Pour l'émulateur AVD |
| Java (JDK) | 17 | Requis par Gradle (`compileOptions VERSION_17`) |
| Git | n'importe | `git --version` |

### Vérifier l'environnement Flutter

```bash
flutter doctor
```

La sortie doit montrer au minimum :
- `[✓] Flutter` — SDK installé
- `[✓] Android toolchain` — SDK Android et licences acceptées
- `[✓] Android Studio` — installé

Si des licences Android ne sont pas acceptées :

```bash
flutter doctor --android-licenses
# Répondre 'y' à toutes les invites
```

### Java 17

Flutter / Gradle exige Java 17. Vérifier :

```bash
java -version
# doit afficher : openjdk 17.x.x ou similaire
```

Si Java 17 n'est pas la version active, configurer `JAVA_HOME` ou utiliser le JDK bundlé d'Android Studio.

---

## 3. Cloner le projet

```bash
git clone https://github.com/ju150/handi_hub_p2i.git
cd handi_hub_p2i
```

Vérifier après clonage que les dossiers suivants sont présents :

```
lib/
android/
admin/
pubspec.yaml
```

---

## 4. Installer les dépendances

### Application Flutter (obligatoire)

```bash
# Depuis la racine du projet
flutter pub get
```

### Application admin React (optionnel — ne fonctionne pas sans les clés Firebase)

```bash
cd admin
npm install
# Note : le lancement nécessite un fichier .env non versionné (voir section 7)
```

---

## 5. Configurer l'émulateur tablette

L'application est conçue pour une tablette Android en mode portrait. Un émulateur tablette est fortement recommandé pour une démonstration correcte.

### Créer l'émulateur dans Android Studio

1. Ouvrir Android Studio → **Device Manager** (icône dans la barre latérale)
2. Cliquer sur **Create Virtual Device**
3. Choisir une tablette : par exemple **Pixel Tablet** ou **10.1" WXGA Tablet**
4. Sélectionner une image système : **API 34** (Android 14) recommandé
5. Orientation par défaut : **Portrait**
6. Cliquer **Finish**

### Lancer l'émulateur

**Option A — depuis Android Studio :** cliquer sur le bouton ▶ dans le Device Manager.

**Option B — depuis le terminal (Windows) :**

```powershell
# Remplacer Pixel_Tablet_API34 par le nom exact de votre AVD
# Pour voir la liste des AVD disponibles :
flutter emulators

# Lancer l'émulateur
flutter emulators --launch <nom_de_votre_avd>
```

### Vérifier que l'émulateur est prêt

```bash
# Attendre ~30 secondes après le démarrage, puis :
flutter devices
# Doit afficher quelque chose comme :
# Pixel Tablet (mobile) • emulator-5554 • android-x64
```

### Émulateur offline ou écran noir (cas fréquent)

Si `flutter devices` affiche `offline` au lieu de `device` :

```bash
# Option 1 — relancer sans snapshot (résout la plupart des cas)
flutter emulators --launch <nom_avd>
# Si déjà lancé, le fermer et relancer avec -no-snapshot-load via Android Studio
```

```bash
# Option 2 — redémarrer le serveur ADB
adb kill-server
adb start-server
adb devices
```

---

## 6. Lancer l'application

### Lancement standard

```bash
# Depuis la racine du projet
flutter run
```

Flutter détecte automatiquement l'émulateur actif. Si plusieurs devices sont connectés :

```bash
# Voir les devices disponibles
flutter devices

# Lancer sur un device spécifique (remplacer emulator-5554 par l'ID affiché)
flutter run -d emulator-5554
```

### Build APK (pour installation sur tablette physique)

```bash
# Build APK debug
flutter build apk --debug

# Installer sur tablette connectée en USB (mode développeur activé)
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Vérifier que l'app a bien démarré

L'application démarre sur le **Hub HandiHub** : 4 grandes tuiles colorées (Lecture, Jeux, Discussion, Rééducation). Si cette page s'affiche, le lancement est réussi.

---

## 7. Gestion des secrets et mode dégradé

### Ce qui n'est pas sur GitHub

| Fichier | Contenu | Impact |
|---|---|---|
| `android/app/src/google-services.json` | Clés Firebase réelles (projet `handi-hub-maman`) | Connexion Firebase non fonctionnelle |
| `admin/.env` | Clés Firebase pour l'app admin React | App admin non fonctionnelle |
| `tools/firebase-admin-key.json` | Clé service account Firebase | Scripts de seed non utilisables |

### Ce qui EST sur GitHub

`android/app/google-services.json` est un fichier **placeholder** avec de fausses clés, suffisant pour que la compilation Gradle aboutisse. Il ne permet pas de se connecter au projet Firebase réel.

### Ce qui se passe au démarrage sans les vraies clés

L'initialisation Firebase est encapsulée dans un `try/catch` dans `main.dart` :

```dart
try {
  await Firebase.initializeApp();
  // ...
  FirebaseService.isInitialized = true;
} catch (e) {
  debugPrint('❌ Firebase init échoué : $e');
  // L'app continue avec FirebaseService.isInitialized = false
}
```

**Conséquence :** l'application démarre normalement. Les fonctionnalités dépendantes de Firebase renvoient des listes vides ou utilisent le cache local si disponible.

### Tableau des fonctionnalités selon la configuration

| Fonctionnalité | Sans Firebase | Avec Firebase |
|---|---|---|
| Hub, navigation, UI | ✅ 100% fonctionnel | ✅ 100% fonctionnel |
| Module Jeux (4 jeux) | ✅ 100% fonctionnel | ✅ 100% fonctionnel |
| Module Discussion (SMS) | ✅ 100% fonctionnel | ✅ 100% fonctionnel |
| Rééducation — navigation | ✅ 100% fonctionnel | ✅ 100% fonctionnel |
| Rééducation — exercices | ⚠️ Liste vide (pas de cache) | ✅ Catalogue complet |
| Lecture — UI | ✅ Fonctionnel | ✅ Fonctionnel |
| Lecture — livres | ⚠️ Aucun livre | ✅ Catalogue complet |
| Enregistrement sessions kiné | ⚠️ Silencieux (échec ignoré) | ✅ Sauvegardé Firestore |
| Application admin React | ❌ Non fonctionnel | ✅ Fonctionnel |
