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
  - Création de tags Git pour chaque version
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
- `--force` - Force l'exécution malgré les erreurs ou avertissements

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

## Intégration dans un workflow CI/CD

```yaml
# Exemple pour GitHub Actions
name: Release Version

on:
  workflow_dispatch:
    inputs:
      version_type:
        description: 'Type de version (major, minor, patch)'
        required: true
        default: 'patch'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v3
        with:
          node-version: '16'
      - run: npm ci
      - name: Release new version
        run: ./push2Git.js ${{ github.event.inputs.version_type }} --commit-all --push
```

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

## Résolution des problèmes courants

### Problèmes Git
- Erreur "Not a git repository" : Exécutez d'abord `git init`
- Problèmes de push : Vérifiez vos droits d'accès au dépôt distant

### Changelogs incomplets
- Assurez-vous que vos messages de commit suivent les conventions définies
- Utilisez des préfixes standards comme `feat:`, `fix:`, etc.

### Script de migration manquant
Si des changements majeurs sont détectés mais qu'aucun script de migration n'est trouvé, le script vous avertira. Créez manuellement le script de migration dans `scripts/migrations/`.

---

Développé avec ❤️ par l'équipe Kreacity-AI