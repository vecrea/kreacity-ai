#!/usr/bin/env node

/**
 * Gestionnaire de versioning pour Kreacity-AI
 * 
 * Ce script permet de:
 * - Incrémenter automatiquement les versions (majeure, mineure, patch)
 * - Créer des tags Git pour chaque version
 * - Générer un changelog basé sur les commits
 * - Mettre à jour les fichiers de configuration avec la nouvelle version
 * - Générer des instructions de mise à jour pour les utilisateurs
 * - Vérifier la compatibilité des dépendances avec la nouvelle version
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const semver = require('semver');

// Configuration
const CONFIG = {
  packageFiles: ['package.json', 'package-lock.json'],
  changelogFile: 'CHANGELOG.md',
  versionFile: 'VERSION',
  updateInstructionsFile: 'UPDATE.md',
  releaseNotesDir: 'docs/releases',
  migrationScriptsDir: 'scripts/migrations',
};

/**
 * Lit la version actuelle depuis package.json
 * @returns {string} Version actuelle
 */
function getCurrentVersion() {
  try {
    const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    return packageJson.version || '0.1.0';
  } catch (error) {
    console.warn('Impossible de lire package.json, utilisation de la version 0.1.0 par défaut');
    return '0.1.0';
  }
}

/**
 * Met à jour la version dans tous les fichiers de configuration
 * @param {string} newVersion Nouvelle version à appliquer
 */
function updateVersionInFiles(newVersion) {
  // Mettre à jour package.json et package-lock.json
  CONFIG.packageFiles.forEach(file => {
    if (fs.existsSync(file)) {
      const content = JSON.parse(fs.readFileSync(file, 'utf8'));
      content.version = newVersion;
      fs.writeFileSync(file, JSON.stringify(content, null, 2) + '\n');
      console.log(`✅ Version mise à jour dans ${file}`);
    }
  });

  // Mettre à jour le fichier VERSION s'il existe
  if (fs.existsSync(CONFIG.versionFile)) {
    fs.writeFileSync(CONFIG.versionFile, newVersion + '\n');
    console.log(`✅ Version mise à jour dans ${CONFIG.versionFile}`);
  } else {
    // Créer le fichier VERSION s'il n'existe pas
    fs.writeFileSync(CONFIG.versionFile, newVersion + '\n');
    console.log(`✅ Fichier ${CONFIG.versionFile} créé avec la version ${newVersion}`);
  }
}

/**
 * Récupère les commits depuis la dernière version
 * @returns {string[]} Liste des messages de commit
 */
function getCommitsSinceLastTag() {
  try {
    const lastTag = execSync('git describe --tags --abbrev=0 2>/dev/null || echo ""').toString().trim();
    const range = lastTag ? `${lastTag}..HEAD` : '';
    const format = '%s';
    const command = lastTag 
      ? `git log ${range} --pretty=format:"${format}"`
      : `git log --pretty=format:"${format}"`;
    
    return execSync(command).toString().trim().split('\n').filter(Boolean);
  } catch (error) {
    console.warn('Impossible de récupérer les commits, historique vide ou erreur Git');
    return [];
  }
}

/**
 * Met à jour le changelog avec les nouveaux commits
 * @param {string} version Nouvelle version
 * @param {string[]} commits Liste des commits
 */
function updateChangelog(version, commits) {
  const date = new Date().toISOString().split('T')[0];
  const header = `## [${version}] - ${date}\n`;
  
  // Catégoriser les commits (basé sur les préfixes conventionnels)
  const categorized = {
    features: [],
    fixes: [],
    breaking: [],
    docs: [],
    refactor: [],
    tests: [],
    other: []
  };
  
  commits.forEach(commit => {
    if (commit.startsWith('feat:') || commit.startsWith('feature:')) {
      categorized.features.push(commit.replace(/^feat(\(\w+\))?:/, '').trim());
    } else if (commit.startsWith('fix:')) {
      categorized.fixes.push(commit.replace(/^fix(\(\w+\))?:/, '').trim());
    } else if (commit.startsWith('docs:')) {
      categorized.docs.push(commit.replace(/^docs(\(\w+\))?:/, '').trim());
    } else if (commit.startsWith('refactor:')) {
      categorized.refactor.push(commit.replace(/^refactor(\(\w+\))?:/, '').trim());
    } else if (commit.startsWith('test:')) {
      categorized.tests.push(commit.replace(/^test(\(\w+\))?:/, '').trim());
    } else if (commit.includes('BREAKING CHANGE')) {
      categorized.breaking.push(commit);
    } else {
      categorized.other.push(commit);
    }
  });
  
  // Générer le contenu du changelog
  let changelogContent = header + '\n';
  
  if (categorized.breaking.length > 0) {
    changelogContent += '### ⚠️ BREAKING CHANGES\n\n';
    categorized.breaking.forEach(commit => {
      changelogContent += `- ${commit}\n`;
    });
    changelogContent += '\n';
  }
  
  if (categorized.features.length > 0) {
    changelogContent += '### ✨ Nouvelles fonctionnalités\n\n';
    categorized.features.forEach(commit => {
      changelogContent += `- ${commit}\n`;
    });
    changelogContent += '\n';
  }
  
  if (categorized.fixes.length > 0) {
    changelogContent += '### 🐛 Corrections de bugs\n\n';
    categorized.fixes.forEach(commit => {
      changelogContent += `- ${commit}\n`;
    });
    changelogContent += '\n';
  }
  
  if (categorized.docs.length > 0) {
    changelogContent += '### 📚 Documentation\n\n';
    categorized.docs.forEach(commit => {
      changelogContent += `- ${commit}\n`;
    });
    changelogContent += '\n';
  }
  
  if (categorized.refactor.length > 0) {
    changelogContent += '### 🔨 Refactoring\n\n';
    categorized.refactor.forEach(commit => {
      changelogContent += `- ${commit}\n`;
    });
    changelogContent += '\n';
  }
  
  if (categorized.tests.length > 0) {
    changelogContent += '### 🧪 Tests\n\n';
    categorized.tests.forEach(commit => {
      changelogContent += `- ${commit}\n`;
    });
    changelogContent += '\n';
  }
  
  if (categorized.other.length > 0) {
    changelogContent += '### 🔄 Autres changements\n\n';
    categorized.other.forEach(commit => {
      changelogContent += `- ${commit}\n`;
    });
    changelogContent += '\n';
  }
  
  // Écrire ou mettre à jour le changelog
  let fullChangelog = '';
  if (fs.existsSync(CONFIG.changelogFile)) {
    const existingChangelog = fs.readFileSync(CONFIG.changelogFile, 'utf8');
    // Insérer les nouveaux changements après le titre
    if (existingChangelog.includes('# Changelog')) {
      fullChangelog = existingChangelog.replace('# Changelog', '# Changelog\n\n' + changelogContent);
    } else {
      fullChangelog = '# Changelog\n\n' + changelogContent + existingChangelog;
    }
  } else {
    fullChangelog = '# Changelog\n\n' + changelogContent;
  }
  
  fs.writeFileSync(CONFIG.changelogFile, fullChangelog);
  console.log(`✅ Changelog mis à jour avec les changements de la version ${version}`);
}

/**
 * Crée un tag Git pour la nouvelle version
 * @param {string} version Nouvelle version
 * @param {object} options Options de configuration
 */
function createGitTag(version, options = {}) {
  try {
    // Vérifier s'il y a des fichiers modifiés non commités
    const status = execSync('git status --porcelain').toString();
    const hasUncommittedChanges = status.trim().length > 0;
    
    if (hasUncommittedChanges) {
      if (options.commitAll) {
        // Commit automatiquement toutes les modifications en attente
        console.log("🔍 Modifications non commitées détectées, commit automatique...");
        
        // Ajouter tous les fichiers modifiés
        execSync('git add .');
        
        // Créer un commit avec un message descriptif
        execSync(`git commit -m "docs: préparation pour la version ${version}" --no-verify`);
        console.log("✅ Modifications commitées automatiquement");
      } else {
        console.warn("⚠️ Des fichiers modifiés n'ont pas été commités.");
        console.warn("   Utilisez l'option --commit-all pour commiter automatiquement ces changements.");
        console.warn("   Ou commitez-les manuellement avant de lancer le script de versioning.");
        
        // Afficher les fichiers modifiés
        console.log("\nFichiers modifiés non commités:");
        console.log(status);
        
        if (!options.force) {
          console.error("❌ Annulation du processus de versioning. Commitez vos changements d'abord.");
          process.exit(1);
        } else {
          console.log("⚠️ Option --force détectée, continuation malgré les changements non commités...");
        }
      }
    }
    
    // Ajouter les fichiers modifiés par le script de versioning
    execSync('git add ' + CONFIG.packageFiles.join(' ') + ' ' + CONFIG.changelogFile + ' ' + CONFIG.versionFile + ' ' + CONFIG.updateInstructionsFile);
    
    // Ajouter aussi les dossiers de documentation si des fichiers y ont été créés
    if (fs.existsSync(CONFIG.releaseNotesDir)) {
      execSync(`git add ${CONFIG.releaseNotesDir}`);
    }
    
    // Créer un commit de version
    execSync(`git commit -m "chore: version ${version}" --no-verify`);
    
    // Créer un tag pour la version
    execSync(`git tag -a v${version} -m "Version ${version}"`);
    
    console.log(`✅ Tag Git v${version} créé`);
    
    if (options.push) {
      // Pousser les modifications et les tags
      console.log("🔄 Envoi des modifications vers le dépôt distant...");
      try {
        execSync('git push origin HEAD');
        execSync('git push origin --tags');
        console.log("✅ Modifications envoyées avec succès");
      } catch (error) {
        console.error("❌ Erreur lors de l'envoi des modifications:", error.message);
        console.log("Vous pouvez les envoyer manuellement avec:");
        console.log(`git push origin HEAD && git push origin v${version}`);
      }
    } else {
      console.log('\nUtilisez la commande suivante pour pousser les changements:');
      console.log(`git push origin HEAD && git push origin v${version}`);
    }
  } catch (error) {
    console.error('❌ Impossible de créer le tag Git:', error.message);
  }
}

/**
 * Fonction principale pour gérer la version
 */
/**
 * Génère des instructions de mise à jour en fonction des changements
 * @param {string} version - Nouvelle version
 * @param {string[]} commits - Commits depuis la dernière version
 */
function generateUpdateInstructions(version, commits) {
  const previousVersion = getPreviousVersion();
  const date = new Date().toISOString().split('T')[0];
  let instructions = `# Instructions de mise à jour vers la version ${version}\n\n`;
  instructions += `Date de publication: ${date}\n\n`;
  
  // Déterminer si cette mise à jour contient des changements majeurs
  const hasMajorChanges = commits.some(commit => 
    commit.includes('BREAKING CHANGE') || 
    commit.startsWith('feat!:') || 
    commit.startsWith('fix!:')
  );
  
  // Déterminer si la version nécessite de nouvelles dépendances
  const newDependencies = detectNewDependencies(commits);
  
  // Instructions standard
  instructions += `## Comment mettre à jour\n\n`;
  instructions += `1. Récupérez les derniers changements:\n`;
  instructions += `   \`\`\`bash\n`;
  instructions += `   git fetch origin\n`;
  instructions += `   git checkout v${version}\n`;
  instructions += `   \`\`\`\n\n`;
  
  if (newDependencies.length > 0) {
    instructions += `2. Installez les nouvelles dépendances:\n`;
    instructions += `   \`\`\`bash\n`;
    instructions += `   npm install\n`;
    instructions += `   \`\`\`\n\n`;
  }
  
  // Instructions spécifiques pour les migrations si nécessaire
  if (hasMajorChanges) {
    const migrationScriptPath = path.join(CONFIG.migrationScriptsDir, `migrate-${previousVersion}-to-${version}.js`);
    
    if (fs.existsSync(migrationScriptPath)) {
      instructions += `## Migration requise\n\n`;
      instructions += `Cette version contient des changements majeurs qui nécessitent une migration.\n\n`;
      instructions += `Exécutez le script de migration:\n`;
      instructions += `\`\`\`bash\n`;
      instructions += `node ${migrationScriptPath}\n`;
      instructions += `\`\`\`\n\n`;
    } else {
      instructions += `## Changements majeurs\n\n`;
      instructions += `Cette version contient des changements majeurs. Veuillez consulter le CHANGELOG.md pour plus de détails.\n\n`;
    }
  }
  
  // Résumé des changements principaux
  instructions += `## Principales nouveautés\n\n`;
  const features = commits.filter(commit => 
    commit.startsWith('feat:') || commit.startsWith('feature:')
  ).map(commit => commit.replace(/^feat(\(\w+\))?:/, '').trim());
  
  if (features.length > 0) {
    features.slice(0, 5).forEach(feature => {
      instructions += `- ${feature}\n`;
    });
    
    if (features.length > 5) {
      instructions += `- Et ${features.length - 5} autres améliorations...\n`;
    }
  } else {
    instructions += `- Améliorations diverses et corrections de bugs\n`;
  }
  
  instructions += `\nPour une liste complète des changements, consultez le [CHANGELOG.md](./CHANGELOG.md).\n`;
  
  // Créer ou mettre à jour le fichier d'instructions
  fs.writeFileSync(CONFIG.updateInstructionsFile, instructions);
  
  // Créer également un fichier de notes de version spécifique
  const releaseNotesDir = CONFIG.releaseNotesDir;
  if (!fs.existsSync(releaseNotesDir)) {
    fs.mkdirSync(releaseNotesDir, { recursive: true });
  }
  
  fs.writeFileSync(
    path.join(releaseNotesDir, `v${version}.md`), 
    instructions
  );
  
  console.log(`✅ Instructions de mise à jour générées dans ${CONFIG.updateInstructionsFile}`);
}

/**
 * Obtient la version précédente depuis les tags Git
 * @returns {string} Version précédente
 */
function getPreviousVersion() {
  try {
    const lastTag = execSync('git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"').toString().trim();
    return lastTag.replace('v', '');
  } catch (error) {
    return '0.0.0';
  }
}

/**
 * Détecte les nouvelles dépendances ajoutées depuis la dernière version
 * @param {string[]} commits - Liste des commits
 * @returns {string[]} Liste des nouvelles dépendances
 */
function detectNewDependencies(commits) {
  const dependencyCommits = commits.filter(commit => 
    commit.startsWith('chore(deps):') || 
    commit.includes('add dependency') ||
    commit.includes('install package')
  );
  
  const dependencies = [];
  
  dependencyCommits.forEach(commit => {
    const matches = commit.match(/add|install|deps:?\s+([a-zA-Z0-9@/-]+)/gi);
    if (matches) {
      matches.forEach(match => {
        const dep = match.replace(/add|install|deps:?\s+/i, '').trim();
        if (dep && !dependencies.includes(dep)) {
          dependencies.push(dep);
        }
      });
    }
  });
  
  return dependencies;
}

/**
 * Vérifie si certaines dépendances devraient être mises à jour
 */
function checkDependenciesToUpdate() {
  try {
    console.log('Vérification des dépendances à mettre à jour...');
    const outdatedOutput = execSync('npm outdated --json', { encoding: 'utf8' });
    const outdatedDeps = JSON.parse(outdatedOutput);
    
    const criticalDeps = Object.keys(outdatedDeps).filter(dep => {
      const current = outdatedDeps[dep].current;
      const latest = outdatedDeps[dep].latest;
      
      // Considérer une mise à jour comme critique si elle est majeure ou sécuritaire
      const isMajorUpdate = semver.major(latest) > semver.major(current);
      return isMajorUpdate;
    });
    
    if (criticalDeps.length > 0) {
      console.log(`⚠️ Dépendances critiques à mettre à jour avant la publication:`);
      criticalDeps.forEach(dep => {
        const current = outdatedDeps[dep].current;
        const latest = outdatedDeps[dep].latest;
        console.log(`   - ${dep}: ${current} → ${latest}`);
      });
      console.log('Considérez mettre à jour ces dépendances avant de publier la version.');
    }
  } catch (error) {
    console.log('Impossible de vérifier les dépendances à mettre à jour.');
  }
}

function main() {
  const args = process.argv.slice(2);
  const currentVersion = getCurrentVersion();
  
  let newVersion = currentVersion;
  
  if (args.length === 0 || args[0] === '--help' || args[0] === '-h') {
    console.log(`
Gestionnaire de versioning pour Kreacity-AI

Usage:
  node version.js <type> [options]

Types:
  major   - Incrémente la version majeure (x.0.0)
  minor   - Incrémente la version mineure (0.x.0)
  patch   - Incrémente la version de patch (0.0.x)
  <version> - Définie explicitement la version (ex: 1.2.3)

Options:
  --dry-run    - Simule le processus sans faire de modifications
  --no-git     - Ne crée pas de commit ni de tag Git
  --no-check   - Ignore la vérification des dépendances
  --commit-all - Commit automatiquement toutes les modifications en attente
  --push       - Pousse automatiquement les changements vers le dépôt distant
  --force      - Force l'exécution même en cas d'erreurs ou d'avertissements
    `);
    return;
  }
  
  const versionType = args[0];
  const options = {
    dryRun: args.includes('--dry-run'),
    noGit: args.includes('--no-git'),
    noCheck: args.includes('--no-check'),
    commitAll: args.includes('--commit-all'),
    push: args.includes('--push'),
    force: args.includes('--force')
  };
  
  if (versionType === 'major' || versionType === 'minor' || versionType === 'patch') {
    newVersion = semver.inc(currentVersion, versionType);
  } else if (semver.valid(versionType)) {
    newVersion = versionType;
  } else {
    console.error(`❌ Type de version invalide: ${versionType}`);
    return;
  }
  
  console.log(`🔄 Mise à jour de la version: ${currentVersion} -> ${newVersion}`);
  
  if (options.dryRun) {
    console.log('🔍 Mode simulation activé: aucune modification ne sera effectuée');
  }
  
  if (!options.noCheck) {
    // Vérifier les dépendances à mettre à jour
    checkDependenciesToUpdate();
  }
  
  // Créer les répertoires nécessaires
  if (!options.dryRun) {
    if (!fs.existsSync(CONFIG.migrationScriptsDir)) {
      fs.mkdirSync(CONFIG.migrationScriptsDir, { recursive: true });
    }
    if (!fs.existsSync(CONFIG.releaseNotesDir)) {
      fs.mkdirSync(CONFIG.releaseNotesDir, { recursive: true });
    }
  }
  
  // Récupérer les commits depuis la dernière version
  const commits = getCommitsSinceLastTag();
  
  if (!options.dryRun) {
    // Mettre à jour les fichiers avec la nouvelle version
    updateVersionInFiles(newVersion);
    
    // Mettre à jour le changelog
    updateChangelog(newVersion, commits);
    
    // Générer les instructions de mise à jour
    generateUpdateInstructions(newVersion, commits);
    
    // Créer un tag Git si demandé
    if (!options.noGit) {
      createGitTag(newVersion, options);
    }
  } else {
    console.log(`\nLes changements qui seraient appliqués:\n`);
    console.log(`- Mise à jour de la version dans ${CONFIG.packageFiles.join(', ')} et ${CONFIG.versionFile}`);
    console.log(`- Mise à jour du changelog avec ${commits.length} commits`);
    console.log(`- Génération des instructions de mise à jour`);
    if (!options.noGit) {
      console.log(`- Création du tag Git v${newVersion}`);
    }
  }
}

main();
