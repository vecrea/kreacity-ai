# Gestionnaire de Versioning et Push Git pour Kreacity-AI

## Description

`push2Git.js` est un outil en ligne de commande conçu pour automatiser et standardiser la gestion des versions et le déploiement de projets Kreacity-AI. Il permet de gérer les versions selon les conventions SemVer (Semantic Versioning), générer des changelogs basés sur les commits et faciliter la publication de nouvelles versions sur GitHub.

## Fonctionnalités

- 🔄 **Gestion automatique des versions**
  - Incrémentation des versions selon SemVer (majeure, mineure, patch)
  - Définition manuelle de versions spécifiques

- 📝 **Génération de documentation**
  - Création automatique de changelogs basés sur les messages de commits
  - Génération d'instructions de mise à jour pour les utilisateurs
  - Production de notes de version détaillées

- 🔍 **Analyse de projet**
  - Détection des dépendances obsolètes avant publication
  - Identification des changements majeurs nécessitant une migration

- 🔖 **Intégration Git**
  - Création intelligente de tags Git pour chaque version
  - Génération de commits pour les fichiers de versioning
  - Publication automatique sur le dépôt distant

## Installation

```bash
# Rendre le script exécutable
chmod +x push2Git.js

# Lier le script pour une utilisation globale (optionnel)
npm link
```

## Prérequis

- Node.js (v12 ou supérieur)
- Git
- Package `semver` installé (`npm install semver`)
- Accès avec droits d'écriture à votre dépôt GitHub

## Configuration GitHub

Avant d'utiliser les fonctionnalités de push, configurez correctement votre accès GitHub :

1. **Authentification via token** (recommandé) :
   - Créez un token d'accès personnel sur GitHub (Settings > Developer settings > Personal access tokens)
   - Sélectionnez au minimum les permissions "repo"
   - Configurez l'URL de votre dépôt avec le token :
   ```bash
   git remote set-url origin https://USERNAME:TOKEN@github.com/user/repo.git
   ```

2. **Authentification SSH** (alternative) :
   ```bash
   git remote set-url origin git@github.com:user/repo.git
   ```

3. **Stockage de credentials** (pour éviter de saisir le mot de passe à chaque fois) :
   ```bash
   # Sur macOS
   git config --global credential.helper osxkeychain
   
   # Sur Windows
   git config --global credential.helper wincred
   
   # Sur Linux
   git config --global credential.helper store
   ```

## Utilisation

```bash
./push2Git.js <type> [options]
```

### Types de version

- `major` - Incrémente la version majeure (x.0.0)
- `minor` - Incrémente la version mineure (0.x.0)
- `patch` - Incrémente la version de patch (0.0.x)
- `<version>` - Définit explicitement la version (ex: 1.5.0)

### Options

- `--dry-run` - Simule le processus sans faire de modifications
- `--no-git` - Désactive l'intégration Git (pas de commit/tag)
- `--no-check` - Ignore la vérification des dépendances
- `--commit-all` - Commit automatiquement toutes les modifications en attente
- `--push` - Pousse automatiquement les changements vers le dépôt distant
- `--force` - Force l'exécution malgré les erreurs ou avertissements (peut aussi recréer des tags existants)

### Exemples

```bash
# Incrémenter la version mineure
./push2Git.js minor

# Publier une version spécifique et pousser sur GitHub
./push2Git.js 1.5.0 --push

# Simuler une incrémentation majeure
./push2Git.js major --dry-run

# Incrémenter le patch et commiter tous les changements
./push2Git.js patch --commit-all

# Forcer la création d'une version même si un tag existe déjà
./push2Git.js 1.5.0 --force
```

## Fichiers générés

Le script gère ou crée automatiquement les fichiers suivants :

- `VERSION` - Contient le numéro de version actuel
- `CHANGELOG.md` - Historique structuré des changements
- `UPDATE.md` - Instructions pour la mise à jour
- `docs/releases/v*.md` - Notes de version spécifiques
- `scripts/migrations/` - Scripts de migration entre versions (si nécessaire)

## Convention de messages de commit

Pour tirer pleinement parti de la génération automatique de changelog, utilisez ces préfixes :

- `feat:` - Nouvelles fonctionnalités
- `fix:` - Corrections de bugs
- `docs:` - Modifications de documentation
- `refactor:` - Refactoring du code
- `test:` - Modifications liées aux tests
- `BREAKING CHANGE` - Changements incompatibles avec les versions précédentes

## Comportement intelligent de Git

Le script inclut plusieurs mécanismes pour éviter les erreurs Git courantes :

- Détection intelligente des changements non commités
- Analyse précise des fichiers stagés pour éviter les commits vides
- Vérification complète des tags existants avec possibilité de recréation via `--force`
- Distinction entre les modifications générales et les modifications spécifiques à la version
- Gestion élégante des erreurs d'authentification

## Résolution des problèmes courants

### Erreur d'authentification (403)
Si vous voyez une erreur comme `remote: Permission to user/repo.git denied` :
- Vérifiez vos droits d'accès au dépôt
- Configurez correctement votre token d'accès personnel (voir section Configuration GitHub)
- Utilisez SSH au lieu de HTTPS si les problèmes persistent

### Absence de commits dans le changelog
- Assurez-vous que vos messages de commit suivent les conventions définies
- Utilisez des préfixes standards comme `feat:`, `fix:`, etc.

### Script de migration manquant
Si des changements majeurs sont détectés mais qu'aucun script de migration n'est trouvé, créez manuellement le script dans `scripts/migrations/`.

### Problèmes avec les tags Git
- Le script détecte automatiquement si un tag existe déjà pour la version
- Pour recréer un tag existant, utilisez l'option `--force`
- Pour pousser manuellement un tag, utilisez `git push origin v{version}`

### Commit vide évité automatiquement
Le script vérifie désormais intelligemment s'il y a des changements stagés à commiter avant de tenter un commit, évitant ainsi l'erreur "Empty commit". Il analyse spécifiquement les fichiers avec un statut de staged (`A`, `M`, `R`, `C`, `D` suivis d'un espace) pour une détection plus précise.

## Personnalisation

Vous pouvez modifier les paramètres du script en éditant les valeurs de configuration au début du fichier :

```javascript
const CONFIG = {
  packageFiles: [], // Détection automatique
  changelogFile: 'CHANGELOG.md',
  versionFile: 'VERSION',
  updateInstructionsFile: 'UPDATE.md',
  releaseNotesDir: 'docs/releases',
  migrationScriptsDir: 'scripts/migrations',
};
```

---

Développé avec ❤️ par l'équipe Kreacity-AI