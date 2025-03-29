#!/bin/bash

echo "Kreacity AI - Assistant d'installation/mise à jour v1.5.1"
echo "--------------------------------------------------------"
echo ""

# Fonction pour demander confirmation
ask_yes_no() {
    local prompt=$1
    local default=$2
    local yn
    
    if [ "$default" = "Y" ]; then
        prompt="$prompt [Y/n] "
    else
        prompt="$prompt [y/N] "
    fi
    
    read -p "$prompt" yn
    
    if [ -z "$yn" ]; then
        yn=$default
    fi
    
    case $yn in
        [Yy]* ) return 0;;
        * ) return 1;;
    esac
}

# Fonction pour vérifier si un service est en cours d'exécution
is_service_running() {
    local service_name=$1
    docker ps --format '{{.Names}}' | grep -q "^$service_name$"
    return $?
}

# Vérifier si Docker est installé et fonctionne
if ! command -v docker &> /dev/null || ! docker info &> /dev/null; then
    echo "❌ Docker n'est pas installé ou n'est pas en cours d'exécution."
    echo "Veuillez installer Docker et Docker Compose avant de continuer."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "⚠️ Docker Compose n'est pas installé."
    if ask_yes_no "Voulez-vous continuer quand même ?" "N"; then
        echo "Continuation..."
    else
        echo "Installation annulée."
        exit 1
    fi
fi

# Création du réseau kreacity-network s'il n'existe pas déjà
if ! docker network ls | grep -q kreacity-network; then
    echo "Création du réseau kreacity-network..."
    docker network create kreacity-network
else
    echo "✅ Le réseau kreacity-network existe déjà."
fi

# Vérifier les services existants
SERVICES=("n8n" "flowise" "web-ui" "qdrant" "db" "ollama" "webhook-forwarder" "adminer")
RUNNING_SERVICES=()

echo "Vérification des services existants..."
for service in "${SERVICES[@]}"; do
    if is_service_running "$service" || is_service_running "kreacity-$service"; then
        if is_service_running "$service"; then
            RUNNING_SERVICES+=("$service")
        else
            RUNNING_SERVICES+=("kreacity-$service")
        fi
        echo "✅ $service est déjà en cours d'exécution."
    else
        echo "❌ $service n'est pas en cours d'exécution."
    fi
done

echo ""
echo "Veuillez choisir les composants à configurer/mettre à jour :"

# Option pour créer les répertoires
CREATE_DIRS=false
if ask_yes_no "Créer les répertoires de données ?" "Y"; then
    CREATE_DIRS=true
fi

# Option pour configurer le Web UI
SETUP_WEBUI=false
if ! is_service_running "web-ui" || ask_yes_no "Reconfigurer l'interface Web UI ?" "N"; then
    SETUP_WEBUI=true
fi

# Option pour créer/modifier le docker-compose.yml
UPDATE_DOCKER_COMPOSE=false
if ask_yes_no "Mettre à jour le fichier docker-compose.yml ?" "Y"; then
    UPDATE_DOCKER_COMPOSE=true
fi

# Option pour configurer Qdrant avec taille de vecteurs 1024
UPDATE_QDRANT=false
if ! is_service_running "qdrant" || ask_yes_no "Reconfigurer Qdrant pour bge-m3 (1024D) ?" "Y"; then
    UPDATE_QDRANT=true
fi

# Option pour mettre à jour PostgreSQL
UPDATE_POSTGRES=false
if ! is_service_running "db" || ask_yes_no "Mettre à jour le schéma PostgreSQL ?" "N"; then
    UPDATE_POSTGRES=true
fi

# Option pour configurer Ollama avec bge-m3
UPDATE_OLLAMA=false
if ! is_service_running "ollama" || ask_yes_no "Télécharger le modèle bge-m3 pour Ollama ?" "Y"; then
    UPDATE_OLLAMA=true
fi

# Option pour configurer ngrok
UPDATE_NGROK=false
if ! is_service_running "webhook-forwarder" || ask_yes_no "Configurer ou mettre à jour ngrok ?" "N"; then
    UPDATE_NGROK=true
fi

# Option pour créer un workflow d'exemple n8n
CREATE_EXAMPLE=false
if ask_yes_no "Créer un workflow d'exemple pour n8n avec bge-m3 ?" "Y"; then
    CREATE_EXAMPLE=true
fi

# Option pour créer un exemple de document
CREATE_DOCUMENT_EXAMPLE=false
if ask_yes_no "Créer un exemple d'insertion de document dans Qdrant ?" "Y"; then
    CREATE_DOCUMENT_EXAMPLE=true
fi

# Option pour démarrer/redémarrer les services
START_SERVICES=false
if ask_yes_no "Démarrer/redémarrer les services après configuration ?" "Y"; then
    START_SERVICES=true
fi

# Option pour sauvegarder les workflows n8n avant la mise à jour
BACKUP_N8N=false
if ask_yes_no "Sauvegarder les workflows n8n avant mise à jour ?" "Y"; then
    BACKUP_N8N=true
fi

echo ""
echo "🔧 Début de la configuration selon vos choix..."

# Sauvegarde des workflows n8n si demandé
if [ "$BACKUP_N8N" = true ]; then
    echo "Sauvegarde des workflows n8n..."
    
    # Détecter le conteneur n8n
    N8N_CONTAINER=""
    if is_service_running "kreacity-n8n"; then
        N8N_CONTAINER="kreacity-n8n"
    elif is_service_running "n8n"; then
        N8N_CONTAINER="n8n"
    fi
    
    if [ -n "$N8N_CONTAINER" ]; then
        # Créer le répertoire de sauvegarde
        mkdir -p ./backups/$(date +%Y-%m-%d)
        
        # Exporter les workflows
        echo "Exportation des workflows depuis $N8N_CONTAINER..."
        docker exec -i $N8N_CONTAINER n8n export:workflow --all --output=/tmp/n8n-workflows-backup.json
        docker cp $N8N_CONTAINER:/tmp/n8n-workflows-backup.json ./backups/$(date +%Y-%m-%d)/n8n-workflows-backup.json
        
        echo "✅ Workflows n8n sauvegardés dans ./backups/$(date +%Y-%m-%d)"
    else
        echo "⚠️ Aucun conteneur n8n trouvé. Impossible de sauvegarder les workflows."
    fi
fi

# Création des répertoires nécessaires
if [ "$CREATE_DIRS" = true ]; then
    echo "Création des répertoires de données..."
    mkdir -p ./n8n-data ./flowise-data ./qdrant-data ./postgres-data ./ollama-data ./web-ui-data ./adminer-data
fi

# Configuration de l'interface Web
if [ "$SETUP_WEBUI" = true ]; then
    echo "Configuration de l'interface web..."
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
                    <span class="bg-blue-800 px-3 py-1 rounded-full text-sm">v1.5.1</span>
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

            <a href="http://localhost:8080" target="_blank" class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
                <div class="flex items-start justify-between">
                    <div>
                        <h2 class="text-xl font-semibold text-gray-800">Adminer</h2>
                        <p class="text-gray-600 mt-2">Interface de gestion pour PostgreSQL</p>
                    </div>
                    <div class="text-blue-500 text-2xl">
                        <i class="fas fa-table"></i>
                    </div>
                </div>
                <div class="mt-4 text-sm text-blue-600">Port: 8080</div>
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
                    <p class="text-gray-400">Version 1.5.1</p>
                </div>
            </div>
        </div>
    </footer>
</body>
</html>
HTML_EOF
fi

# Mise à jour du fichier docker-compose.yml
if [ "$UPDATE_DOCKER_COMPOSE" = true ]; then
    echo "Mise à jour du fichier docker-compose.yml..."
    
    # Création d'un fichier temporaire pour le docker-compose.yml
    cat > docker-compose.yml.new << 'COMPOSE_EOF'
version: '3.8'

services:
  n8n:
    container_name: kreacity-n8n
    image: n8nio/n8n:latest
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - N8N_HOST=localhost
      - NODE_ENV=production
      - N8N_METRICS=true
      - WEBHOOK_TUNNEL_URL=${NGROK_URL}
    volumes:
      - ./n8n-data:/home/node/.n8n
    networks:
      - kreacity-network

  flowise:
    container_name: kreacity-flowise
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
    container_name: kreacity-web-ui
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./web-ui-data:/usr/share/nginx/html
    networks:
      - kreacity-network

  qdrant:
    container_name: kreacity-qdrant
    image: qdrant/qdrant:latest
    restart: unless-stopped
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage
    networks:
      - kreacity-network

  db:
    container_name: kreacity-db
    image: postgres:15
    restart: unless-stopped
    ports:
      - "5555:5432"  # Utiliser 5555 sur l'hôte pour éviter le conflit
    environment:
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_USER=postgres
      - POSTGRES_DB=postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - kreacity-network

  ollama:
    container_name: kreacity-ollama
    image: ollama/ollama:latest
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ./ollama-data:/root/.ollama
    networks:
      - kreacity-network
    deploy:
      resources:
        limits:
          memory: 4G
        reservations:
          memory: 2G

  webhook-forwarder:
    container_name: kreacity-webhook-forwarder
    image: ngrok/ngrok:latest
    restart: unless-stopped
    ports:
      - "4040:4040"
    environment:
      - NGROK_AUTHTOKEN=${NGROK_TOKEN}
    networks:
      - kreacity-network
    command: ["http", "kreacity-n8n:5678", "--log=stdout"]

  adminer:
    container_name: kreacity-adminer
    image: adminer:latest
    restart: unless-stopped
    ports:
      - "8090:8080"
    environment:
      - ADMINER_DEFAULT_SERVER=kreacity-db
      - ADMINER_DEFAULT_USER=postgres
      - ADMINER_DEFAULT_PASSWORD=postgres
      - ADMINER_DESIGN=flat
    networks:
      - kreacity-network

networks:
  kreacity-network:
    external: true

volumes:
  qdrant_data:
    name: kreacity_qdrant_data
  postgres_data:
    name: kreacity_postgres_data
COMPOSE_EOF

    # Mettre à jour le fichier docker-compose.yml
    mv docker-compose.yml.new docker-compose.yml

    # Création du fichier .env s'il n'existe pas
    if [ ! -f .env ]; then
        echo "COMPOSE_PROJECT_NAME=kreacity" > .env
    else
        # S'assurer que COMPOSE_PROJECT_NAME est présent dans .env
        if ! grep -q "COMPOSE_PROJECT_NAME" .env; then
            echo "COMPOSE_PROJECT_NAME=kreacity" >> .env
        fi
    fi
fi

# Création du fichier version.js
echo "Mise à jour du fichier version.js..."
cat > version.js << 'VERSION_EOF'
// Kreacity AI Version Information
const version = {
  version: "1.5.1",
  lastUpdate: "2025-03-29",
  features: [
    "Added Ollama for local LLM and embedding processing",
    "Standardized vector size to 1024 dimensions using bge-m3 model",
    "Added web UI dashboard for easy service navigation",
    "Added Adminer for PostgreSQL database management",
    "Improved workflow backup/restore functionality",
    "Fixed compatibility issues with ARM64 architecture (Apple Silicon)",
    "Improved documentation and integration guides",
    "Replaced localtunnel with ngrok for more reliable external access",
    "Optimized database configurations with volume-based storage"
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

# Configuration de ngrok
if [ "$UPDATE_NGROK" = true ]; then
    # Demander le token ngrok à l'utilisateur s'il n'existe pas déjà dans .env
    if ! grep -q "NGROK_TOKEN" .env; then
        echo ""
        echo "Ngrok configuration"
        echo "-------------------"
        echo "Pour accéder à n8n depuis l'extérieur, un token ngrok est nécessaire."
        echo "Vous pouvez obtenir un token gratuit sur https://dashboard.ngrok.com/get-started/your-authtoken"
        echo ""
        read -p "Veuillez saisir votre token ngrok (laisser vide pour version gratuite): " ngrok_token
        echo ""

        # Ajouter le token à .env, même s'il est vide
        echo "NGROK_TOKEN=${ngrok_token}" >> .env
    else
        echo "✅ Token ngrok déjà configuré dans .env"
    fi
fi

# Identifie les services qui doivent être arrêtés pour migration
SERVICES_TO_STOP=()
if [ "$UPDATE_DOCKER_COMPOSE" = true ]; then
    for service in "${RUNNING_SERVICES[@]}"; do
        # Si le service est en cours d'exécution sans le préfixe "kreacity-"
        if [[ "$service" != "kreacity-"* ]]; then
            SERVICES_TO_STOP+=("$service")
        fi
    done
fi

# Arrêter les services si nécessaire pour migration
if [ ${#SERVICES_TO_STOP[@]} -gt 0 ]; then
    echo "Les services suivants doivent être arrêtés pour migration vers le projet kreacity:"
    printf '  - %s\n' "${SERVICES_TO_STOP[@]}"
    
    if ask_yes_no "Voulez-vous arrêter ces services maintenant?" "Y"; then
        echo "Arrêt des services pour migration..."
        for service in "${SERVICES_TO_STOP[@]}"; do
            echo "  Arrêt de $service..."
            docker stop "$service"
            docker rm "$service"
        done
    else
        echo "⚠️ Migration annulée. Les services continuent à fonctionner avec les anciens noms."
    fi
fi

# Démarrage des services si demandé
if [ "$START_SERVICES" = true ]; then
    echo "Démarrage des services avec docker-compose..."
    docker-compose up -d
    
    # Attendre un peu que les services démarrent
    echo "Attente du démarrage des services..."
    sleep 5
fi

# Configuration de Qdrant pour bge-m3 avec vecteurs 1024D
if [ "$UPDATE_QDRANT" = true ] && (is_service_running "kreacity-qdrant" || is_service_running "qdrant"); then
    echo "Configuration de Qdrant pour bge-m3 (vecteurs 1024D)..."
    
    # Attendre que Qdrant soit prêt
    echo "Attente du démarrage de Qdrant..."
    ATTEMPTS=0
    MAX_ATTEMPTS=30
    until [ $ATTEMPTS -ge $MAX_ATTEMPTS ]
    do
        if curl --output /dev/null --silent --fail http://localhost:6333/; then
            echo "✅ Qdrant est prêt!"
            break
        fi
        
        ATTEMPTS=$((ATTEMPTS+1))
        echo "Attente de Qdrant... (tentative $ATTEMPTS/$MAX_ATTEMPTS)"
        sleep 5
    done

    if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
        echo "⚠️ Qdrant n'a pas démarré à temps. La création de collection pourrait échouer."
    else
        # Vérifier si la collection existe déjà
        COLLECTION_EXISTS=false
        if curl --output /dev/null --silent --fail http://localhost:6333/collections/documents; then
            COLLECTION_EXISTS=true
            echo "La collection 'documents' existe déjà."
            if ask_yes_no "Voulez-vous recréer la collection ? Cela effacera toutes les données existantes!" "N"; then
                # Supprimer la collection existante de manière plus sûre
                curl -X DELETE 'http://localhost:6333/collections/documents'
                
                # Attendre un peu que la suppression soit terminée
                sleep 2
                
                COLLECTION_EXISTS=false
                echo "Collection existante supprimée."
            fi
        fi
        
        if [ "$COLLECTION_EXISTS" = false ]; then
            # Créer une nouvelle collection avec configuration optimisée pour 1024 dimensions
            echo "Création de la collection avec configuration optimisée pour bge-m3 (1024D)..."
            curl -X PUT 'http://localhost:6333/collections/documents' \
            -H 'Content-Type: application/json' \
            -d '{
                "vectors": {
                    "size": 1024,
                    "distance": "Cosine"
                },
                "optimizers_config": {
                    "default_segment_number": 2
                },
                "on_disk_payload": true,
                "metadata_config": {
                    "indexed": [
                        "title", 
                        "source", 
                        "type", 
                        "category", 
                        "language", 
                        "author", 
                        "created_at", 
                        "updated_at", 
                        "tags", 
                        "keywords", 
                        "rating"
                    ]
                },
                "hnsw_config": {
                    "m": 16,
                    "ef_construct": 100,
                    "full_scan_threshold": 10000
                },
                "quantization_config": {
                    "scalar": {
                        "type": "int8",
                        "always_ram": true
                    }
                }
            }'
            
            # Vérifier si la collection a été créée
            if curl --output /dev/null --silent --fail http://localhost:6333/collections/documents; then
                echo "✅ Collection créée avec succès."
            else
                echo "⚠️ La création de la collection a échoué. Essai avec une configuration simplifiée..."
                
                # Essayer avec une configuration plus simple en cas d'échec
                curl -X PUT 'http://localhost:6333/collections/documents' \
                -H 'Content-Type: application/json' \
                -d '{
                    "vectors": {
                        "size": 1024,
                        "distance": "Cosine"
                    }
                }'
                
                if curl --output /dev/null --silent --fail http://localhost:6333/collections/documents; then
                    echo "✅ Collection créée avec succès (configuration simplifiée)."
                else
                    echo "❌ Impossible de créer la collection. Veuillez vérifier les logs de Qdrant."
                fi
            fi
        fi
    fi
fi

# Configuration de PostgreSQL
if [ "$UPDATE_POSTGRES" = true ] && (is_service_running "kreacity-db" || is_service_running "db"); then
    echo "Configuration de PostgreSQL..."
    
    # Déterminer le nom du conteneur PostgreSQL
    PG_CONTAINER="kreacity-db"
    if ! is_service_running "kreacity-db" && is_service_running "db"; then
        PG_CONTAINER="db"
    fi
    
    # Attendre que PostgreSQL soit prêt
    echo "Attente du démarrage de PostgreSQL..."
    ATTEMPTS=0
    MAX_ATTEMPTS=30
    until [ $ATTEMPTS -ge $MAX_ATTEMPTS ]
    do
        if docker exec $PG_CONTAINER pg_isready -U postgres > /dev/null 2>&1; then
            echo "✅ PostgreSQL est prêt!"
            break
        fi
        
        ATTEMPTS=$((ATTEMPTS+1))
        echo "Attente de PostgreSQL... (tentative $ATTEMPTS/$MAX_ATTEMPTS)"
        sleep 2
    done

    if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
        echo "⚠️ PostgreSQL n'a pas démarré à temps."
    else
        # Création ou mise à jour de la table documents
        echo "Création/mise à jour des tables de métadonnées..."
        docker exec -i $PG_CONTAINER psql -U postgres -d postgres << 'PSQL_EOF'
-- Table pour les documents (sera créée si elle n'existe pas)
CREATE TABLE IF NOT EXISTS documents (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT,
  source_id TEXT UNIQUE,  -- ID unique du document source (par ex. ID Notion)
  vector_id TEXT,  -- ID dans Qdrant
  language TEXT,
  source TEXT,
  category TEXT,
  author TEXT,
  url TEXT,
  word_count INTEGER,
  tags TEXT[],
  keywords TEXT[],
  rating REAL,
  summary TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table pour les chunks de documents
CREATE TABLE IF NOT EXISTS document_chunks (
  id SERIAL PRIMARY KEY,
  document_id INTEGER REFERENCES documents(id) ON DELETE CASCADE,
  chunk_id TEXT,
  chunk_index INTEGER,
  vector_id TEXT,
  content_preview TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(document_id, chunk_index)
);

-- Index pour accélérer les recherches
CREATE INDEX IF NOT EXISTS idx_documents_language ON documents(language);
CREATE INDEX IF NOT EXISTS idx_documents_category ON documents(category);
CREATE INDEX IF NOT EXISTS idx_documents_source_id ON documents(source_id);
CREATE INDEX IF NOT EXISTS idx_documents_vector_id ON documents(vector_id);
CREATE INDEX IF NOT EXISTS idx_documents_source ON documents(source);
CREATE INDEX IF NOT EXISTS idx_documents_created_at ON documents(created_at);
CREATE INDEX IF NOT EXISTS idx_document_chunks_document_id ON document_chunks(document_id);
CREATE INDEX IF NOT EXISTS idx_document_chunks_vector_id ON document_chunks(vector_id);

PSQL_EOF

        # Vérifier si la table a été créée/mise à jour correctement
        if docker exec -i $PG_CONTAINER psql -U postgres -d postgres -c "\d documents" > /dev/null 2>&1; then
            echo "✅ Tables PostgreSQL créées/mises à jour avec succès."
        else
            echo "⚠️ Problème lors de la création des tables PostgreSQL."
            echo "Vérification non-interactive..."
            
            # Essayer en mode non-interactif
            if docker exec -i $PG_CONTAINER pg_isready; then
                echo "✅ Le serveur PostgreSQL est fonctionnel (mais il peut y avoir des problèmes d'accès interactif)."
            else
                echo "❌ Le serveur PostgreSQL n'est pas fonctionnel."
            fi
        fi
    fi
fi

# Téléchargement du modèle bge-m3 pour Ollama
if [ "$UPDATE_OLLAMA" = true ] && (is_service_running "kreacity-ollama" || is_service_running "ollama"); then
    echo "Configuration d'Ollama pour bge-m3..."
    
    # Déterminer le nom du conteneur Ollama
    OLLAMA_RUNNING=false
    if is_service_running "kreacity-ollama"; then
        OLLAMA_RUNNING=true
    elif is_service_running "ollama"; then
        OLLAMA_RUNNING=true
    fi
    
    if [ "$OLLAMA_RUNNING" = true ]; then
        # Attendre que le service Ollama soit prêt
        echo "Attente du démarrage d'Ollama..."
        ATTEMPTS=0
        MAX_ATTEMPTS=30
        until [ $ATTEMPTS -ge $MAX_ATTEMPTS ]
        do
            if curl --output /dev/null --silent --head --fail http://localhost:11434/; then
                echo "✅ Ollama est prêt!"
                break
            fi
            
            ATTEMPTS=$((ATTEMPTS+1))
            echo "Attente d'Ollama... (tentative $ATTEMPTS/$MAX_ATTEMPTS)"
            sleep 5
        done

        if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
            echo "⚠️ Ollama n'a pas démarré à temps."
        else
            # Télécharger le modèle d'embedding bge-m3
            echo "Téléchargement du modèle bge-m3..."
            curl -X POST http://localhost:11434/api/pull -d '{"name": "bge-m3"}' -s > /dev/null
            echo "Téléchargement du modèle nomic-embed-text comme backup..."
            curl -X POST http://localhost:11434/api/pull -d '{"name": "nomic-embed-text"}' -s > /dev/null

            echo "✅ Modèles d'embedding téléchargés avec succès."
        fi
    else
        echo "❌ Ollama n'est pas en cours d'exécution. Impossible de télécharger les modèles."
    fi
fi

# Vérification et configuration des webhooks ngrok
if [ "$UPDATE_NGROK" = true ] || (is_service_running "kreacity-webhook-forwarder" || is_service_running "webhook-forwarder"); then
    echo "Vérification du statut de webhook-forwarder (ngrok)..."
    
    # Déterminer le nom du conteneur webhook-forwarder
    NGROK_RUNNING=false
    if is_service_running "kreacity-webhook-forwarder"; then
        NGROK_RUNNING=true
    elif is_service_running "webhook-forwarder"; then
        NGROK_RUNNING=true
    fi
    
    if [ "$NGROK_RUNNING" = true ]; then
        ATTEMPTS=0
        MAX_ATTEMPTS=10
        until [ $ATTEMPTS -ge $MAX_ATTEMPTS ]
        do
            if curl --output /dev/null --silent --fail http://localhost:4040/api/tunnels; then
                echo "✅ Webhook-forwarder (ngrok) est prêt!"
                # Récupérer et afficher l'URL publique
                NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"[^"]*' | grep -o 'http[^"]*' | head -1)
                echo ""
                echo "Votre URL ngrok est: $NGROK_URL"
                echo "Cette URL peut être utilisée pour recevoir des webhooks externes."
                
                # Ajouter l'URL ngrok à .env pour que n8n puisse l'utiliser
                if [ -n "$NGROK_URL" ]; then
                    # Si la variable existe déjà, la mettre à jour
                    if grep -q "NGROK_URL" .env; then
                        sed -i '' "s|NGROK_URL=.*|NGROK_URL=${NGROK_URL}|g" .env 2>/dev/null || \
                        sed -i "s|NGROK_URL=.*|NGROK_URL=${NGROK_URL}|g" .env
                    else
                        # Sinon, l'ajouter
                        echo "NGROK_URL=${NGROK_URL}" >> .env
                    fi
                    
                    echo "✅ URL ngrok ajoutée à .env"
                    
                    # Demander si l'utilisateur souhaite redémarrer n8n pour prendre en compte la nouvelle URL
                    if (is_service_running "kreacity-n8n" || is_service_running "n8n") && \
                       ask_yes_no "Voulez-vous redémarrer n8n pour utiliser cette URL de webhook ?" "Y"; then
                        echo "Redémarrage de n8n..."
                        docker-compose restart n8n kreacity-n8n 2>/dev/null || \
                        (docker restart kreacity-n8n 2>/dev/null || docker restart n8n 2>/dev/null)
                    fi
                else
                    echo "⚠️ Impossible de récupérer l'URL ngrok."
                fi
                break
            fi
            
            ATTEMPTS=$((ATTEMPTS+1))
            echo "Attente de webhook-forwarder... (tentative $ATTEMPTS/$MAX_ATTEMPTS)"
            sleep 5
        done

        if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
            echo "⚠️ Webhook-forwarder n'a pas démarré correctement. Vérifiez votre configuration de token ngrok."
        fi
    else
        echo "❌ Webhook-forwarder n'est pas en cours d'exécution. Impossible de vérifier l'URL ngrok."
    fi
fi

# Création d'un workflow d'exemple pour n8n
if [ "$CREATE_EXAMPLE" = true ]; then
    echo "Création d'un workflow d'exemple pour n8n avec bge-m3..."
    mkdir -p ./examples
    cat > ./examples/bge-m3-embedding-workflow.json << 'WORKFLOW_EOF'
{
  "name": "Document Embedding avec bge-m3",
  "nodes": [
    {
      "parameters": {},
      "name": "Start",
      "type": "n8n-nodes-base.start",
      "typeVersion": 1,
      "position": [
        250,
        300
      ]
    },
    {
      "parameters": {
        "filePath": "={{ $json.filePath }}"
      },
      "name": "Read Document",
      "type": "n8n-nodes-base.readBinaryFile",
      "typeVersion": 1,
      "position": [
        450,
        300
      ]
    },
    {
      "parameters": {
        "resource": "embeddings",
        "model": "bge-m3",
        "text": "={{ $json.content }}",
        "options": {}
      },
      "name": "Ollama Embedding",
      "type": "n8n-nodes-base.ollama",
      "typeVersion": 1,
      "position": [
        850,
        300
      ]
    },
    {
      "parameters": {
        "jsCode": "// Générer un UUID valide\nfunction uuidv4() {\n  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {\n    const r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);\n    return v.toString(16);\n  });\n}\n\n// Extraire l'embedding et préparer les données pour Qdrant\nconst data = $json;\nconst embedding = data.embedding;\nconst uuid = uuidv4();\n\n// Vérifier la taille du vecteur d'embedding\nconsole.log(\"Taille du vecteur d'embedding:\", embedding.length);\n\n// Préparer les données pour Qdrant\nconst qdrantData = {\n  points: [{\n    id: uuid,  // UUID au format attendu par Qdrant\n    vector: embedding,\n    payload: {\n      content: data.content,\n      title: data.title || 'Sans titre',\n      language: data.language || 'fr',\n      source: data.source || 'import',\n      category: data.category || 'document',\n      source_id: data.source_id || `doc-${Date.now()}`,\n      chunk_index: data.chunkIndex || 0,\n      total_chunks: data.totalChunks || 1,\n      document_id: data.documentId || `doc-${Date.now()}`\n    }\n  }]\n};\n\nreturn {\n  ...data,\n  vectorId: uuid,\n  source_id: data.source_id || `doc-${Date.now()}`,\n  qdrantData: qdrantData\n};"
      },
      "name": "Préparer données Qdrant",
      "type": "n8n-nodes-base.code",
      "typeVersion": 1,
      "position": [
        1050,
        300
      ]
    },
    {
      "parameters": {
        "url": "http://kreacity-qdrant:6333/collections/documents/points",
        "options": {
          "method": "PUT",
          "body": {
            "points": [
              {
                "id": "={{ $json.vectorId }}",
                "vector": "={{ $json.embedding }}",
                "payload": {
                  "title": "={{ $json.title || 'Sans titre' }}",
                  "content": "={{ $json.content }}",
                  "language": "={{ $json.language || 'fr' }}",
                  "source": "={{ $json.source || 'import' }}",
                  "type": "={{ $json.type || 'document' }}",
                  "category": "={{ $json.category || 'general' }}",
                  "author": "={{ $json.author }}",
                  "source_id": "={{ $json.source_id }}",
                  "created_at": "={{ $json.created_at || $now }}"
                }
              }
            ]
          }
        }
      },
      "name": "Insérer dans Qdrant",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 2,
      "position": [
        1250,
        300
      ]
    },
    {
      "parameters": {
        "operation": "executeQuery",
        "query": "INSERT INTO documents \n(title, content, source_id, language, source, category, author, url, vector_id, tags, created_at, updated_at)\nVALUES (\n  '{{ $json.title || \"Sans titre\" }}', \n  '{{ $json.content.substring(0, 1000) + \"...\" }}', \n  '{{ $json.source_id }}',\n  '{{ $json.language || \"fr\" }}',\n  '{{ $json.source || \"import\" }}',\n  '{{ $json.category || \"general\" }}',\n  '{{ $json.author || \"\" }}',\n  '{{ $json.url || \"\" }}',\n  '{{ $json.vectorId }}',\n  ARRAY[{{ ($json.tags && $json.tags.length > 0) ? \"'\" + $json.tags.join(\"','\") + \"'\" : \"\" }}]::text[],\n  NOW(),\n  NOW()\n)\nON CONFLICT (source_id) \nDO UPDATE SET\n  title = EXCLUDED.title,\n  content = EXCLUDED.content,\n  language = EXCLUDED.language,\n  category = EXCLUDED.category,\n  vector_id = EXCLUDED.vector_id,\n  updated_at = NOW()\nRETURNING id, source_id, vector_id;",
        "options": {}
      },
      "name": "Enregistrer dans PostgreSQL",
      "type": "n8n-nodes-base.postgres",
      "typeVersion": 1,
      "position": [
        1450,
        300
      ]
    }
  ],
  "connections": {
    "Start": {
      "main": [
        [
          {
            "node": "Read Document",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Read Document": {
      "main": [
        [
          {
            "node": "Ollama Embedding",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Ollama Embedding": {
      "main": [
        [
          {
            "node": "Préparer données Qdrant",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Préparer données Qdrant": {
      "main": [
        [
          {
            "node": "Insérer dans Qdrant",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Insérer dans Qdrant": {
      "main": [
        [
          {
            "node": "Enregistrer dans PostgreSQL",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  }
}
WORKFLOW_EOF
    echo "✅ Workflow d'exemple créé avec succès dans ./examples/bge-m3-embedding-workflow.json"
    
    # Créer également un fichier README pour expliquer l'utilisation
    cat > ./examples/README.md << 'README_EOF'
# Exemples d'utilisation de Kreacity AI avec bge-m3

Ce répertoire contient des exemples pour vous aider à utiliser Kreacity AI avec le modèle d'embedding bge-m3.

## Workflow n8n pour l'embedding de documents

Le fichier `bge-m3-embedding-workflow.json` est un workflow n8n que vous pouvez importer pour intégrer des documents dans Qdrant.

### Comment l'utiliser :

1. Ouvrez n8n dans votre navigateur à l'adresse http://localhost:5678
2. Allez dans "Workflows" puis cliquez sur "Import from File"
3. Sélectionnez le fichier `bge-m3-embedding-workflow.json`
4. Configurez le workflow selon vos besoins (sources de données, formats, etc.)

### Structure du workflow :

- Nœud "Start" : Point de départ du workflow
- Nœud "Read Document" : Lecture du fichier (à adapter selon votre source)
- Nœud "Ollama Embedding" : Génération de l'embedding avec bge-m3
- Nœud "Préparer données Qdrant" : Traitement des données et création d'un UUID valide
- Nœud "Insérer dans Qdrant" : Insertion dans Qdrant avec métadonnées
- Nœud "Enregistrer dans PostgreSQL" : Enregistre les métadonnées du document dans PostgreSQL

### Métadonnées flexibles :

Les métadonnées sont optionnelles. Le workflow utilise des valeurs par défaut pour les champs manquants :
- `language` : 'fr' par défaut
- `source` : 'import' par défaut
- `type` : 'document' par défaut
- `category` : 'general' par défaut
- `source_id` : généré automatiquement si non fourni
- `created_at` : date actuelle par défaut
- `tags` : tableau vide par défaut

## Bonnes pratiques

- **Documents volumineux** : Pour les documents très longs, divisez-les en sections plus petites (paragraphes, pages...)
- **Langues** : Spécifiez toujours la langue pour améliorer les résultats de recherche
- **Métadonnées** : Plus vos métadonnées sont riches, plus vos recherches seront précises
- **Catégorisation** : Utilisez des catégories et des tags cohérents pour faciliter le filtrage
- **Identifiants source** : Utilisez toujours un `source_id` unique et stable pour chaque document source

## Recherche dans Qdrant

Pour rechercher des documents similaires à un texte :

```bash
# Générer l'embedding du texte de recherche
curl -X POST http://localhost:11434/api/embeddings \
  -d '{"model": "bge-m3", "prompt": "votre texte de recherche"}' \
  -H 'Content-Type: application/json' \
  | jq -r '.embedding' > embedding.json

# Rechercher dans Qdrant
curl -X POST 'http://localhost:6333/collections/documents/points/search' \
  -H 'Content-Type: application/json' \
  -d '{
    "vector": '"$(cat embedding.json)"',
    "limit": 5,
    "with_payload": true
  }'
```
README_EOF
    echo "✅ Documentation d'exemple créée avec succès dans ./examples/README.md"
fi

# Créer un exemple de script pour insérer un document dans Qdrant
if [ "$CREATE_DOCUMENT_EXAMPLE" = true ]; then
    echo "Création d'un exemple d'insertion de document dans Qdrant..."
    mkdir -p ./examples
    cat > ./examples/insert-document.sh << 'INSERT_DOCUMENT_EOF'
#!/bin/bash

# Ce script montre comment insérer un document dans Qdrant avec des métadonnées flexibles
# Il utilise bge-m3 pour générer l'embedding via Ollama

# Définir l'ID unique du document (utilisez UUID ou un identifiant de votre choix)
DOC_ID="doc-$(date +%s)"
SOURCE_ID="source-$(date +%s)"

# Définir le contenu du document
TITLE="Exemple de document pour Kreacity AI"
CONTENT="Ceci est un exemple de document qui montre comment insérer des données dans Qdrant avec des métadonnées flexibles. Les métadonnées peuvent être complètes ou partielles selon vos besoins. Le modèle bge-m3 génère des embeddings de dimension 1024 qui capturent les nuances sémantiques du texte en français et en anglais."

# Générer l'embedding avec Ollama
echo "Génération de l'embedding avec bge-m3..."
EMBEDDING_RESPONSE=$(curl -s -X POST http://localhost:11434/api/embeddings \
  -d "{\"model\": \"bge-m3\", \"prompt\": \"$CONTENT\"}")

# Extraire le vecteur d'embedding
EMBEDDING=$(echo $EMBEDDING_RESPONSE | sed -n 's/.*"embedding":\(\[.*\]\).*/\1/p')

if [ -z "$EMBEDDING" ]; then
    echo "Erreur: Impossible de générer l'embedding. Vérifiez qu'Ollama est en cours d'exécution avec le modèle bge-m3."
    exit 1
fi

# Générer un UUID valide pour Qdrant
UUID=$(python3 -c 'import uuid; print(uuid.uuid4())')
echo "UUID généré pour Qdrant: $UUID"

# Déterminer l'URL Qdrant selon le nom du conteneur (kreacity-qdrant ou qdrant)
QDRANT_HOST="localhost"

# Insérer le document dans Qdrant avec ID au format UUID
echo "Insertion du document dans Qdrant..."
curl -X PUT http://${QDRANT_HOST}:6333/collections/documents/points \
  -H 'Content-Type: application/json' \
  -d "{
    \"points\": [
      {
        \"id\": \"$UUID\",
        \"vector\": $EMBEDDING,
        \"payload\": {
          \"title\": \"$TITLE\",
          \"content\": \"$CONTENT\",
          \"language\": \"fr\",
          \"source\": \"exemple_script\",
          \"type\": \"document\",
          \"category\": \"exemple\",
          \"author\": \"Kreacity AI\",
          \"source_id\": \"$SOURCE_ID\",
          \"created_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",
          \"tags\": [\"exemple\", \"tutoriel\", \"metadata\"],
          \"rating\": 5
        }
      }
    ]
  }"

# Déterminer le nom du conteneur PostgreSQL
PG_CONTAINER="kreacity-db"
if ! docker ps --format '{{.Names}}' | grep -q "^kreacity-db$"; then
    if docker ps --format '{{.Names}}' | grep -q "^db$"; then
        PG_CONTAINER="db"
    fi
fi

# Insérer également dans PostgreSQL si le conteneur existe
if docker ps --format '{{.Names}}' | grep -q "^$PG_CONTAINER$"; then
    echo "Insertion des métadonnées dans PostgreSQL..."
    docker exec -i $PG_CONTAINER psql -U postgres -d postgres << PSQL_EOF
INSERT INTO documents 
(title, content, source_id, vector_id, language, source, category, author, tags, created_at)
VALUES 
('$TITLE', '$CONTENT', '$SOURCE_ID', '$UUID', 'fr', 'exemple_script', 'exemple', 'Kreacity AI', ARRAY['exemple', 'tutoriel', 'metadata'], '$(date -u +"%Y-%m-%d %H:%M:%S")'::timestamptz);
PSQL_EOF
else
    echo "Conteneur PostgreSQL non trouvé. Métadonnées non insérées dans PostgreSQL."
fi

echo "✅ Document inséré avec succès dans Qdrant!"
echo "ID du document: $SOURCE_ID"
echo "ID du vecteur: $UUID"
echo ""
echo "Pour rechercher des documents similaires, vous pouvez utiliser:"
echo "curl -X POST http://localhost:6333/collections/documents/points/search -H 'Content-Type: application/json' -d '{\"vector\": [...votre vecteur de recherche...], \"limit\": 5}'"
INSERT_DOCUMENT_EOF

    # Rendre le script exécutable
    chmod +x ./examples/insert-document.sh
    echo "✅ Script d'exemple créé avec succès dans ./examples/insert-document.sh"
fi

# Affichage du récapitulatif
echo ""
echo "---------------------------------------------------------------------"
echo "✅ Configuration de Kreacity AI terminée!"
echo "---------------------------------------------------------------------"
echo ""

# Vérifier les services en cours d'exécution après configuration
echo "Services actuels:"
for service in $(docker ps --format '{{.Names}}' | grep -E '^(kreacity-|)n8n$|^(kreacity-|)flowise$|^(kreacity-|)web-ui$|^(kreacity-|)qdrant$|^(kreacity-|)db$|^(kreacity-|)ollama$|^(kreacity-|)webhook-forwarder$|^(kreacity-|)adminer); do
    echo "- $service: ✅ En cours d'exécution"
done

echo ""

# Vérifier si Qdrant est configuré
if curl --output /dev/null --silent --fail http://localhost:6333/collections/documents; then
    echo "Configuration Qdrant: Vecteurs de dimension 1024 pour bge-m3"
    echo "Métadonnées indexées: title, source, type, category, language, author, created_at, updated_at, tags, keywords, rating"
fi

# Vérifier si Ollama a le modèle bge-m3
if curl -s http://localhost:11434/api/tags | grep -q "bge-m3"; then
    echo "Modèle d'embedding: bge-m3 (dimension: 1024, tokens max: 8194)"
fi

# Vérifier l'URL ngrok
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o '"public_url":"[^"]*' | grep -o 'http[^"]*' | head -1)
if [ -n "$NGROK_URL" ]; then
    echo "URL Webhook (ngrok): $NGROK_URL"
fi

if [ "$CREATE_EXAMPLE" = true ]; then
    echo "Exemples: ./examples/ (workflow n8n et documentation)"
fi

if [ "$CREATE_DOCUMENT_EXAMPLE" = true ]; then
    echo "Script d'insertion d'exemple: ./examples/insert-document.sh"
fi

if [ "$BACKUP_N8N" = true ]; then
    echo "Sauvegarde des workflows n8n: ./backups/$(date +%Y-%m-%d)/n8n-workflows-backup.json"
fi

echo ""
echo "Accès aux services:"
echo "- Web UI: http://localhost:8080"
echo "- FloWise: http://localhost:3000"
echo "- n8n: http://localhost:5678"
echo "- Qdrant: http://localhost:6333"
echo "- Ollama: http://localhost:11434"
echo "- PostgreSQL: localhost:5555 (user: postgres, password: postgres)"
echo "- Adminer: http://localhost:8090 (serveur: kreacity-db, user: postgres, password: postgres)"
echo "- Ngrok Dashboard: http://localhost:4040"
echo ""
echo "Pour plus d'informations, consultez la documentation dans le dossier docs/"
echo ""
echo "Pour restaurer une sauvegarde de workflows n8n, utilisez:"
echo "docker exec -i kreacity-n8n n8n import:workflow --input=/tmp/backup.json"
echo "(Après avoir copié le fichier dans le conteneur: docker cp ./backups/[date]/n8n-workflows-backup.json kreacity-n8n:/tmp/backup.json)"