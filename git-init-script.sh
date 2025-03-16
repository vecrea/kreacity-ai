#!/bin/bash

# Ce script crée la structure du dépôt Git pour Kreacity AI Stack

# Créer la structure de base des dossiers
mkdir -p kreacity-ai-stack
cd kreacity-ai-stack

mkdir -p postgres-init
mkdir -p examples/n8n
mkdir -p examples/flowise
mkdir -p docs

# Initialiser le dépôt Git
git init
echo "# Kreacity AI Stack" > README.md
git add README.md
git commit -m "Initial commit"

# Créer les fichiers principaux
cat > docker-compose.yml << 'EOF'
# Contenu du fichier docker-compose.yml
EOF

cat > docker-compose.cpu.yml << 'EOF'
# Contenu du fichier docker-compose.cpu.yml
EOF

cat > docker-compose.gpu.yml << 'EOF'
# Contenu du fichier docker-compose.gpu.yml
EOF

cat > docker-compose.apple-silicon.yml << 'EOF'
# Contenu du fichier docker-compose.apple-silicon.yml
EOF

cat > setup.sh << 'EOF'
# Contenu du fichier setup.sh
EOF

cat > update-dimension.sh << 'EOF'
# Contenu du fichier update-dimension.sh
EOF

# Rendre les scripts exécutables
chmod +x setup.sh
chmod +x update-dimension.sh

# Créer les fichiers de documentation
cat > CONTRIBUTING.md << 'EOF'
# Contenu du fichier CONTRIBUTING.md
EOF

cat > LICENSE << 'EOF'
# Contenu de la licence MIT
EOF

# Créer le fichier .gitignore
cat > .gitignore << 'EOF'
# Fichiers Docker
.env

# Fichiers temporaires
*.swp
*.swo
*~
.DS_Store
Thumbs.db

# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Dossiers de données
data/
volumes/

# Fichiers de sauvegarde
*.bak
*.backup

# Fichiers de configuration locaux
.vscode/
.idea/
*.sublime-*
*.code-workspace

# Fichiers d'environnement
.env.local
.env.development.local
.env.test.local
.env.production.local

# Fichiers de dépendances
node_modules/
EOF

# Créer les scripts d'initialisation pour PostgreSQL
cat > postgres-init/init-documents-db.sql << 'EOF'
-- Contenu du fichier init-documents-db.sql
EOF

# Créer les exemples
cat > examples/n8n/document-processing.json << 'EOF'
# Contenu de l'exemple document-processing.json
EOF

cat > examples/n8n/semantic-search.json << 'EOF'
# Contenu de l'exemple semantic-search.json
EOF

cat > examples/flowise/rag-workflow.json << 'EOF'
# Contenu de l'exemple rag-workflow.json
EOF

cat > examples/README.md << 'EOF'
# Contenu du fichier exemples/README.md
EOF

# Créer la documentation
cat > docs/embeddings.md << 'EOF'
# Contenu du fichier docs/embeddings.md
EOF

cat > docs/architecture.md << 'EOF'
# Contenu du fichier docs/architecture.md
EOF

# Ajouter tous les fichiers au dépôt Git
git add .
git commit -m "Structure initiale du projet"

echo "==================================="
echo "Dépôt Git Kreacity AI Stack créé !"
echo "==================================="
echo "Prochaines étapes :"
echo "1. Copiez le contenu des fichiers fournis dans les fichiers créés"
echo "2. Personnalisez le README.md avec vos informations"
echo "3. Poussez le dépôt vers GitHub ou GitLab"
echo ""
echo "Commandes Git pour pousser vers un nouveau dépôt :"
echo "git remote add origin https://github.com/votre-utilisateur/kreacity-ai-stack.git"
echo "git branch -M main"
echo "git push -u origin main"
