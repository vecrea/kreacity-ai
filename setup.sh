#!/bin/bash

echo "Setting up Kreacity AI environment v1.5.0..."

# Création du réseau kreacity-network s'il n'existe pas déjà
if ! docker network ls | grep -q kreacity-network; then
  echo "Creating kreacity-network..."
  docker network create kreacity-network
else
  echo "kreacity-network already exists."
fi

# Création des répertoires nécessaires
echo "Creating necessary directories..."
mkdir -p ./n8n-data ./flowise-data ./qdrant-data ./postgres-data ./ollama-data ./web-ui-data

# Copie du fichier index.html pour web-ui
echo "Creating web interface..."
cat > ./web-ui-data/index.html << 'HTML_EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kreacity AI Platform</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
</head>
<body class="bg-gray-100 min-h-screen">
    <!-- Header -->
    <header class="bg-gradient-to-r from-blue-900 to-blue-600 text-white shadow-lg">
        <div class="container mx-auto px-4 py-6">
            <div class="flex justify-between items-center">
                <div>
                    <h1 class="text-3xl font-bold">Kreacity AI</h1>
                    <p class="text-blue-100">Plateforme d'Intelligence Artificielle</p>
                </div>
                <div>
                    <span class="bg-blue-800 px-3 py-1 rounded-full text-sm">v1.5.0</span>
                </div>
            </div>
        </div>
    </header>

    <!-- Main Content -->
    <main class="container mx-auto px-4 py-8">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <!-- Services Cards -->
            <a href="http://localhost:3000" target="_blank" class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
                <div class="flex items-start justify-between">
                    <div>
                        <h2 class="text-xl font-semibold text-gray-800">FloWise</h2>
                        <p class="text-gray-600 mt-2">Créez vos workflows d'IA avec une interface graphique intuitive</p>
                    </div>
                    <div class="text-blue-500 text-2xl">
                        <i class="fas fa-project-diagram"></i>
                    </div>
                </div>
                <div class="mt-4 text-sm text-blue-600">Port: 3000</div>
            </a>

            <a href="http://localhost:5678" target="_blank" class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
                <div class="flex items-start justify-between">
                    <div>
                        <h2 class="text-xl font-semibold text-gray-800">n8n</h2>
                        <p class="text-gray-600 mt-2">Automatisez vos flux de travail et intégrations</p>
                    </div>
                    <div class="text-blue-500 text-2xl">
                        <i class="fas fa-cogs"></i>
                    </div>
                </div>
                <div class="mt-4 text-sm text-blue-600">Port: 5678</div>
            </a>

            <a href="http://localhost:6333/dashboard" target="_blank" class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
                <div class="flex items-start justify-between">
                    <div>
                        <h2 class="text-xl font-semibold text-gray-800">Qdrant</h2>
                        <p class="text-gray-600 mt-2">Base de données vectorielle pour recherche sémantique</p>
                    </div>
                    <div class="text-blue-500 text-2xl">
                        <i class="fas fa-database"></i>
                    </div>
                </div>
                <div class="mt-4 text-sm text-blue-600">Port: 6333</div>
            </a>

            <a href="http://localhost:11434" target="_blank" class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
                <div class="flex items-start justify-between">
                    <div>
                        <h2 class="text-xl font-semibold text-gray-800">Ollama</h2>
                        <p class="text-gray-600 mt-2">Serveur de modèles d'IA locaux</p>
                    </div>
                    <div class="text-blue-500 text-2xl">
                        <i class="fas fa-brain"></i>
                    </div>
                </div>
                <div class="mt-4 text-sm text-blue-600">Port: 11434</div>
            </a>

            <a href="http://localhost:4040" target="_blank" class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
                <div class="flex items-start justify-between">
                    <div>
                        <h2 class="text-xl font-semibold text-gray-800">Webhook Forwarder</h2>
                        <p class="text-gray-600 mt-2">Accès externe via ngrok (Dashboard)</p>
                    </div>
                    <div class="text-blue-500 text-2xl">
                        <i class="fas fa-globe"></i>
                    </div>
                </div>
                <div class="mt-4 text-sm text-blue-600">Port: 4040</div>
            </a>
        </div>

        <!-- Documentation Section -->
        <section class="mt-12">
            <h2 class="text-2xl font-bold text-gray-800 mb-6">Documentation</h2>
            <div class="bg-white rounded-lg shadow-md p-6">
                <p class="text-gray-600 mb-4">
                    La documentation complète de Kreacity AI est disponible dans le répertoire <code class="bg-gray-100 px-2 py-1 rounded">docs/</code> du projet.
                </p>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-6">
                    <div class="border rounded p-4">
                        <h3 class="font-semibold text-gray-700">Guide d'utilisation</h3>
                        <p class="text-gray-600 text-sm mt-2">Instructions détaillées pour utiliser chaque service</p>
                    </div>
                    <div class="border rounded p-4">
                        <h3 class="font-semibold text-gray-700">Guide d'intégration</h3>
                        <p class="text-gray-600 text-sm mt-2">Scénarios d'utilisation avancés et exemples d'intégration</p>
                    </div>
                </div>
            </div>
        </section>
    </main>

    <!-- Footer -->
    <footer class="bg-gray-800 text-white py-8 mt-12">
        <div class="container mx-auto px-4">
            <div class="flex flex-col md:flex-row justify-between items-center">
                <div class="mb-4 md:mb-0">
                    <h3 class="text-xl font-bold">Kreacity AI</h3>
                    <p class="text-gray-400">Plateforme locale d'intelligence artificielle</p>
                </div>
                <div>
                    <p class="text-gray-400">Version 1.5.0</p>
                </div>
            </div>
        </div>
    </footer>
</body>
</html>
HTML_EOF

# Création du fichier docker-compose.yml
echo "Creating docker-compose.yml..."
cat > docker-compose.yml << 'COMPOSE_EOF'
services:
  n8n:
    container_name: n8n
    image: n8nio/n8n:latest
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - N8N_HOST=localhost
      - NODE_ENV=production
    volumes:
      - ./n8n-data:/home/node/.n8n
    networks:
      - kreacity-network

  flowise:
    container_name: flowise
    image: flowiseai/flowise:latest
    restart: unless-stopped 
    ports:
      - "3000:3000"
    environment:
      - PORT=3000
      - DATABASE_PATH=/root/.flowise
      - APIKEY_PATH=/root/.flowise
    volumes:
      - ./flowise-data:/root/.flowise
    networks:
      - kreacity-network

  web-ui:
    container_name: web-ui
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./web-ui-data:/usr/share/nginx/html
    networks:
      - kreacity-network

  qdrant:
    container_name: qdrant
    image: qdrant/qdrant:latest
    restart: unless-stopped
    ports:
      - "6333:6333"
    volumes:
      - ./qdrant-data:/qdrant/storage
    networks:
      - kreacity-network

  db:
    container_name: db
    image: postgres:15
    restart: unless-stopped
    ports:
      - "5555:5432"  # Utiliser 5555 sur l'hôte pour éviter le conflit
    environment:
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_USER=postgres
      - POSTGRES_DB=postgres
    volumes:
      - ./postgres-data:/var/lib/postgresql/data
    networks:
      - kreacity-network

  ollama:
    container_name: ollama
    image: ollama/ollama:latest
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ./ollama-data:/root/.ollama
    networks:
      - kreacity-network

  webhook-forwarder:
    container_name: webhook-forwarder
    image: ngrok/ngrok:latest
    restart: unless-stopped
    ports:
      - "4040:4040"
    environment:
      - NGROK_AUTHTOKEN=${NGROK_TOKEN}
    networks:
      - kreacity-network
    command: ["http", "n8n:5678", "--log=stdout"]

networks:
  kreacity-network:
    external: true
COMPOSE_EOF

# Création du fichier .env pour définir le nom du projet et le token ngrok
echo "Setting up environment variables..."
echo "COMPOSE_PROJECT_NAME=kreacity" > .env

# Demander le token ngrok à l'utilisateur
echo ""
echo "Ngrok configuration"
echo "-------------------"
echo "Pour accéder à n8n depuis l'extérieur, un token ngrok est nécessaire."
echo "Vous pouvez obtenir un token gratuit sur https://dashboard.ngrok.com/get-started/your-authtoken"
echo ""
read -p "Veuillez saisir votre token ngrok: " ngrok_token
echo ""

# Ajouter le token à .env
echo "NGROK_TOKEN=${ngrok_token}" >> .env

# Création du fichier version.js
echo "Creating version.js..."
cat > version.js << 'VERSION_EOF'
// Kreacity AI Version Information
const version = {
  version: "1.5.0",
  lastUpdate: "2025-03-26",
  features: [
    "Added Ollama for local LLM and embedding processing",
    "Standardized vector size to 1024 dimensions for universal compatibility",
    "Added web UI dashboard for easy service navigation",
    "Fixed compatibility issues with ARM64 architecture (Apple Silicon)",
    "Improved documentation and integration guides",
    "Replaced localtunnel with ngrok for more reliable external access"
  ]
};

console.log("Kreacity AI Version:", version.version);
console.log("Last Updated:", version.lastUpdate);
console.log("Latest Features:");
version.features.forEach((feature, index) => {
  console.log(`  ${index + 1}. ${feature}`);
});

module.exports = version;
VERSION_EOF

# Démarrage de tous les services
echo "Starting all services..."
docker-compose up -d

echo "Setting up Qdrant collection with 1024-dimensional vectors..."

# Attendre que Qdrant soit prêt
echo "Waiting for Qdrant to be ready..."
# Utiliser une approche plus robuste
ATTEMPTS=0
MAX_ATTEMPTS=30
until [ $ATTEMPTS -ge $MAX_ATTEMPTS ]
do
  # Tester l'accès à Qdrant depuis l'hôte
  if curl --output /dev/null --silent --fail http://localhost:6333/; then
    echo "Qdrant is ready!"
    break
  fi
  
  ATTEMPTS=$((ATTEMPTS+1))
  echo "Waiting for Qdrant to start... (attempt $ATTEMPTS/$MAX_ATTEMPTS)"
  sleep 5
done

if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
  echo "Qdrant failed to start in time. Continuing anyway, but collection creation might fail."
fi

# Créer la collection (utiliser localhost car cette commande est exécutée depuis l'hôte)
curl -X PUT 'http://localhost:6333/collections/documents' \
  -H 'Content-Type: application/json' \
  -d '{
    "vectors": {
      "size": 1024,
      "distance": "Cosine"
    }
  }'


echo "Qdrant collection created successfully!"

echo "Setting up PostgreSQL database structure..."

# Attendre que PostgreSQL soit prêt
echo "Waiting for PostgreSQL to be ready..."
until docker exec db pg_isready -U postgres > /dev/null 2>&1; do
  printf '.'
  sleep 2
done

# Créer les tables de métadonnées
echo "Creating metadata tables..."
docker exec -i db psql -U postgres -d postgres << 'PSQL_EOF'

-- Table pour les documents
CREATE TABLE IF NOT EXISTS documents (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT,
  vector_id TEXT UNIQUE,  -- ID dans Qdrant
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


PSQL_EOF

echo "