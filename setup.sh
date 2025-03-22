#!/bin/bash

# Créer les répertoires nécessaires
mkdir -p postgres-init

# Créer le fichier d'initialisation pour PostgreSQL
cat > postgres-init/init-documents-db.sql << 'EOF'
-- Création de la base de données documents
CREATE DATABASE documents;

-- Connexion à la base de données documents
\c documents;

-- Création d'une table pour stocker les documents
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB,
    embedding_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Création d'un index pour la recherche plein texte
CREATE INDEX idx_documents_content ON documents USING GIN (to_tsvector('english', content));

-- Création d'un index pour la recherche dans les métadonnées
CREATE INDEX idx_documents_metadata ON documents USING GIN (metadata);

-- Fonction pour mettre à jour le timestamp updated_at
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour updated_at automatiquement
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON documents
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- Création d'une table pour les chunks de documents
CREATE TABLE chunks (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES documents(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    metadata JSONB,
    embedding_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Création d'un index pour la recherche plein texte sur les chunks
CREATE INDEX idx_chunks_content ON chunks USING GIN (to_tsvector('english', content));
EOF

# Créer le docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    ports:
      - "5678:5678"
    environment:
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - NODE_ENV=production
      # Variables pour permettre à n8n de communiquer avec les autres services
      - POSTGRES_HOST=db
      - POSTGRES_PORT=5432
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=postgres
      - QDRANT_HOST=qdrant
      - QDRANT_PORT=6333
      - FLOWISE_HOST=flowise
      - FLOWISE_PORT=3000
    volumes:
      - n8n_data:/home/node/.n8n
    restart: unless-stopped
    networks:
      - kreacity-ai

  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - qdrant_data:/qdrant/storage
    restart: unless-stopped
    networks:
      - kreacity-ai
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:6333/"]
      interval: 5s
      timeout: 5s
      retries: 5

  db:
    image: postgres:15
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_USER=postgres
      - POSTGRES_DB=postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./postgres-init:/docker-entrypoint-initdb.d
    restart: unless-stopped
    networks:
      - kreacity-ai

  flowise:
    image: flowiseai/flowise:latest
    ports:
      - "3000:3000"
    environment:
      - PORT=3000
      - DATABASE_PATH=/root/.flowise
      - APIKEY_PATH=/root/.flowise
      - SECRETKEY_PATH=/root/.flowise
      # Variables pour permettre à Flowise de communiquer avec les autres services
      - POSTGRES_HOST=db
      - POSTGRES_PORT=5432
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=postgres
      - QDRANT_HOST=qdrant
      - QDRANT_PORT=6333
    volumes:
      - flowise_data:/root/.flowise
    restart: unless-stopped
    networks:
      - kreacity-ai

volumes:
  n8n_data:
  qdrant_data:
  postgres_data:
  flowise_data:

networks:
  kreacity-ai:
    driver: bridge
EOF

# Créer le script d'initialisation pour Qdrant
cat > init-qdrant.sh << 'EOF'
#!/bin/bash

# Attendre que Qdrant démarre
echo "Attente du démarrage de Qdrant..."
sleep 10

# Créer la collection vectors
echo "Création de la collection vectors dans Qdrant..."
curl -X PUT 'http://localhost:6333/collections/vectors' -H 'Content-Type: application/json' -d '{
  "vectors": {
    "size": 1024,
    "distance": "Cosine"
  }
}'

echo "Initialisation de Qdrant terminée"
EOF

chmod +x init-qdrant.sh

# Créer un README pour les utilisateurs
cat > README.md << 'EOF'
# Kreacity AI

Une stack d'IA locale combinant :

- **n8n** (port 5678) : Automatisation de workflows
- **Qdrant** (port 6333) : Base de données vectorielle
- **PostgreSQL** (port 5432) : Base de données SQL
- **Flowise** (port 3000) : Construction de flux IA sans code

Cette stack est configurée pour utiliser Mistral AI comme service d'embeddings externe.

## Installation rapide

```bash
# Cloner le dépôt
git clone https://github.com/vecrea/kreacity-ai.git
cd kreacity-ai

# Lancer l'installation
chmod +x setup.sh
./setup.sh

# Initialiser Qdrant
./init-qdrant.sh
```

## Préparer un environnement propre

Pour nettoyer votre environnement Docker avant l'installation :

```bash
docker stop $(docker ps -a -q) || true \
&& docker rm $(docker ps -a -q) || true \
&& docker volume prune -f \
&& docker network prune -f \
&& docker image prune -a -f
```

⚠️ **Attention** : Cette commande supprime tous les conteneurs, volumes et réseaux Docker.

## Services disponibles

Une fois installé, les services sont disponibles aux adresses suivantes :

- **n8n** : http://localhost:5678
- **Flowise** : http://localhost:3000
- **Qdrant API** : http://localhost:6333
- **PostgreSQL** : localhost:5432

## Configuration de Mistral AI dans Flowise

Pour configurer Mistral AI comme service d'embeddings dans Flowise :

1. Obtenez une clé API de Mistral AI en vous inscrivant sur leur site.
2. Dans Flowise, lorsque vous configurez un workflow, ajoutez un nœud "MistralAI Embeddings".
3. Configurez-le avec votre clé API.
4. La collection Qdrant est configurée pour utiliser des vecteurs de dimension 1024 (compatibles avec Mistral).

## Exemples d'utilisation

### Workflow RAG typique dans Flowise
1. Importer des documents via "Document Loader"
2. Découper les documents en chunks avec "Text Splitter"
3. Générer des embeddings avec "MistralAI Embeddings"
4. Stocker dans "Qdrant Vector Store"
5. Configurer un nœud "Conversational Retrieval Chain"
6. Connecter à un modèle de langage (LLM) de votre choix
EOF

# Démarrer les services
echo "Création du réseau kreacity-ai si nécessaire..."
docker network create kreacity-ai 2>/dev/null || true

echo "Démarrage des services..."
docker-compose up -d

echo "Tous les services sont démarrés !"
echo "URLs des services :"
echo "- n8n: http://localhost:5678"
echo "- Flowise: http://localhost:3000"
echo "- Qdrant API: http://localhost:6333"
echo "- PostgreSQL: localhost:5432 (utiliser un client PostgreSQL comme pgAdmin)"
echo ""
echo "IMPORTANT : Exécutez maintenant './init-qdrant.sh' pour initialiser la collection Qdrant"
echo ""
echo "Pour utiliser Mistral AI comme service d'embeddings, vous devrez :"
echo "1. Obtenir une clé API Mistral AI"
echo "2. Configurer un nœud MistralAI Embeddings dans Flowise avec cette clé"
