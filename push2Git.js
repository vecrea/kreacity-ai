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

// Configuration - Sera adaptée automatiquement en fonction des fichiers trouvés
const CONFIG = {
  packageFiles: [], // Sera rempli automatiquement
  changelogFile: 'CHANGELOG.md',
  versionFile: 'VERSION',
  updateInstructionsFile: 'UPDATE.md',
  releaseNotesDir: 'docs/releases',
  migrationScriptsDir: 'scripts/migrations',
};

/**
 * Initialise la configuration en fonction des fichiers existants
 */
function initConfig() {
  // Vérifier les fichiers package.json
  if (fs.existsSync('package.json')) {
    CONFIG.packageFiles.push('package.json');
  }
  
  if (fs.existsSync('package-lock.json')) {
    CONFIG.packageFiles.push('package-lock.json');
  }
  
  // Créer les répertoires nécessaires s'ils n'existent pas
  const dirs = [CONFIG.releaseNotesDir, CONFIG.migrationScriptsDir];
  dirs.forEach(dir => {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
      console.log(`✅ Répertoire ${dir} créé`);
    }
  });
  
  // Créer les fichiers essentiels s'ils n'existent pas
  if (!fs.existsSync(CONFIG.versionFile)) {
    fs.writeFileSync(CONFIG.versionFile, '0.1.0\n');
    console.log(`✅ Fichier ${CONFIG.versionFile} créé avec la version 0.1.0`);
  }
  
  if (!fs.existsSync(CONFIG.changelogFile)) {
    fs.writeFileSync(CONFIG.changelogFile, '# Changelog\n\n');
    console.log(`✅ Fichier ${CONFIG.changelogFile} créé`);
  }
  
  console.log('Configuration initialisée :');
  console.log(`- Fichiers de package: ${CONFIG.packageFiles.length > 0 ? CONFIG.packageFiles.join(', ') : 'Aucun'}`);
}

/**
 * Lit la version actuelle depuis package.json ou VERSION
 * @returns {string} Version actuelle
 */
function getCurrentVersion() {
  // Essayer d'abord de lire depuis package.json
  if (fs.existsSync('package.json')) {
    try {
      const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      return packageJson.version || '0.1.0';
    } catch (error) {
      console.warn('Impossible de lire package.json correctement');
    }
  }
  
  // Sinon, lire depuis le fichier VERSION
  if (fs.existsSync(CONFIG.versionFile)) {
    try {
      return fs.readFileSync(CONFIG.versionFile, 'utf8').trim();
    } catch (error) {
      console.warn(`Impossible de lire ${CONFIG.versionFile}`);
    }
  }
  
  // Valeur par défaut
  return '0.1.0';
}

/**
 * Met à jour la version dans tous les fichiers de configuration
 * @param {string} newVersion Nouvelle version à appliquer
 */
function updateVersionInFiles(newVersion) {
  // Mettre à jour package.json et package-lock.json s'ils existent
  CONFIG.packageFiles.forEach(file => {
    if (fs.existsSync(file)) {
      const content = JSON.parse(fs.readFileSync(file, 'utf8'));
      content.version = newVersion;
      fs.writeFileSync(file, JSON.stringify(content, null, 2) + '\n');
      console.log(`✅ Version mise à jour dans ${file}`);
    }
  });

  // Mettre à jour le fichier VERSION (toujours présent car créé si nécessaire)
  fs.writeFileSync(CONFIG.versionFile, newVersion + '\n');
  console.log(`✅ Version mise à jour dans ${CONFIG.versionFile}`);
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
    
    const commits = execSync(command).toString().trim().split('\n').filter(Boolean);
    
    if (commits.length === 0) {
      console.warn('⚠️ Aucun commit trouvé depuis la dernière version. Le changelog sera minimal.');
    } else {
      console.log(`📝 ${commits.length} commits trouvés depuis la dernière version.`);
    }
    
    return commits;
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
  
  // En cas d'absence de commits, créer une entrée minimale
  if (commits.length === 0) {
    commits = ['Mise à jour de la version'];
  }
  
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
 * Obtient la version précédente depuis les tags Git ou depuis le fichier VERSION
 * @returns {string} Version précédente
 */
function getPreviousVersion() {
  try {
    // Essayer d'obtenir depuis Git
    const lastTag = execSync('git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"').toString().trim();
    return lastTag.replace('v', '');
  } catch (error) {
    // Si Git échoue, utiliser le fichier VERSION
    if (fs.existsSync(CONFIG.versionFile)) {
      return fs.readFileSync(CONFIG.versionFile, 'utf8').trim();
    }
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
  // Vérifier si package.json existe avant d'essayer de vérifier les dépendances
  if (!fs.existsSync('package.json')) {
    console.log('⚠️ Aucun fichier package.json trouvé, impossible de vérifier les dépendances.');
    return;
  }
  
  try {
    console.log('Vérification des dépendances à mettre à jour...');
    const outdatedOutput = execSync('npm outdated --json', { encoding: 'utf8' });
    
    // Si aucune dépendance n'est obsolète, la commande peut ne rien retourner
    if (!outdatedOutput.trim()) {
      console.log('✅ Toutes les dépendances sont à jour.');
      return;
    }
    
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
    } else if (Object.keys(outdatedDeps).length > 0) {
      console.log(`ℹ️ ${Object.keys(outdatedDeps).length} dépendances pourraient être mises à jour (non critiques).`);
    }
  } catch (error) {
    console.log('⚠️ Impossible de vérifier les dépendances à mettre à jour.');
    if (error.message.includes('npm')) {
      console.log('   Assurez-vous que npm est installé et accessible.');
    }
  }
}

/**
 * Crée un tag Git pour la nouvelle version
 * @param {string} version Nouvelle version
 * @param {object} options Options de configuration
 */
/**
 * Crée un tag Git pour la nouvelle version
 * @param {string} version Nouvelle version
 * @param {object} options Options de configuration
 */
function createGitTag(version, options = {}) {
  try {
    // Vérifier si Git est disponible
    try {
      execSync('git --version', { stdio: 'ignore' });
    } catch (error) {
      console.error('❌ Git n\'est pas disponible ou n\'est pas installé.');
      console.error('   Vous pouvez installer Git ou utiliser l\'option --no-git.');
      return;
    }
    
    // Vérifier si nous sommes dans un dépôt Git
    try {
      execSync('git rev-parse --is-inside-work-tree', { stdio: 'ignore' });
    } catch (error) {
      console.error('❌ Le répertoire actuel n\'est pas un dépôt Git.');
      console.error('   Initialisez un dépôt Git avec "git init" ou utilisez l\'option --no-git.');
      return;
    }
    
    // Vérifier s'il y a des fichiers modifiés non commités
    let status = execSync('git status --porcelain').toString();
    let hasUncommittedChanges = status.trim().length > 0;
    
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
    
    // Préparer la liste des fichiers à ajouter (uniquement ceux qui existent)
    const filesToAdd = [
      ...CONFIG.packageFiles,
      CONFIG.changelogFile,
      CONFIG.versionFile,
      CONFIG.updateInstructionsFile
    ].filter(file => fs.existsSync(file));
    
    if (filesToAdd.length === 0) {
      console.error('❌ Aucun fichier à commiter pour la version.');
      return;
    }
    
    // Ajouter les fichiers modifiés par le script de versioning
    execSync(`git add ${filesToAdd.join(' ')}`);
    
    // Ajouter aussi les dossiers de documentation si des fichiers y ont été créés
    if (fs.existsSync(CONFIG.releaseNotesDir)) {
      try {
        execSync(`git add ${CONFIG.releaseNotesDir}`);
      } catch (error) {
        // Ignorer silencieusement si le dossier est vide ou déjà ajouté
      }
    }
    
    // Vérifier à nouveau s'il y a des changements stagés prêts à être commités
    status = execSync('git status --porcelain').toString();
    hasUncommittedChanges = status.trim().length > 0;
    
    if (hasUncommittedChanges) {
      // Créer un commit de version seulement s'il y a des changements
      execSync(`git commit -m "chore: version ${version}" --no-verify`);
      console.log(`✅ Changements de version commités`);
    } else {
      console.log(`ℹ️ Aucun nouveau changement à commiter`);
    }
    
    // Vérifier si le tag existe déjà
    try {
      execSync(`git tag -l v${version}`, { stdio: 'pipe' }).toString().trim();
      console.log(`⚠️ Le tag v${version} existe déjà.`);
    } catch (error) {
      // Le tag n'existe pas, on peut le créer
      execSync(`git tag -a v${version} -m "Version ${version}"`);
      console.log(`✅ Tag Git v${version} créé`);
    }
    
    if (options.push) {
      // Pousser les modifications et les tags
      console.log("🔄 Envoi des modifications vers le dépôt distant...");
      try {
        // Déterminer la branche actuelle
        const currentBranch = execSync('git rev-parse --abbrev-ref HEAD').toString().trim();
        execSync(`git push origin ${currentBranch}`);
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
function main() {
  // Initialiser la configuration en fonction de l'environnement
  initConfig();
  
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
    console.log(`- Mise à jour de la version dans ${CONFIG.packageFiles.join(', ') || 'VERSION uniquement'}`);
    console.log(`- Mise à jour du changelog avec ${commits.length} commits`);
    console.log(`- Génération des instructions de mise à jour`);
    if (!options.noGit) {
      console.log(`- Création du tag Git v${newVersion}`);
    }
  }
}

// Exécution du script
main();
