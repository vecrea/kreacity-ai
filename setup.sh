#!/bin/bash

# Configuration - MODIFIEZ CETTE VARIABLE SELON VOTRE MATÉRIEL
# USE_GPU=false pour CPU uniquement (Mac M1/M2, machines sans GPU)
# USE_GPU=true pour machines avec GPU NVIDIA
USE_GPU=false

# Créer les répertoires nécessaires
mkdir -p postgres-init qdrant-init

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
RETURNS TRIGGER AS $
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

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

# Créer les fichiers de configuration
echo "Création des fichiers de configuration..."

# Version GPU (NVIDIA)
cat > docker-compose.gpu.yml << 'EOF'
version: '3.8'

services:
  # Service pour les embeddings locaux (version GPU)
  sentence-transformers:
    image: ghcr.io/huggingface/text-embeddings-inference:latest
    command: --model-id BAAI/bge-small-en-v1.5
    ports:
      - "8080:80"
    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]
              count: 1
              driver: nvidia
    volumes:
      - hf-cache:/data
    restart: unless-stopped
    networks:
      - kreacity-ai

volumes:
  hf-cache:

networks:
  kreacity-ai:
    external: true
EOF

# Version CPU (pour Mac M1/M2 ou machines sans GPU)
cat > docker-compose.cpu.yml << 'EOF'
version: '3.8'

services:
  # Service pour les embeddings locaux (version CPU)
  sentence-transformers:
    image: ghcr.io/huggingface/text-embeddings-inference:latest
    command: --model-id BAAI/bge-small-en-v1.5
    environment:
      - USE_CUDA=0
    ports:
      - "8080:80"
    volumes:
      - hf-cache:/data
    restart: unless-stopped
    networks:
      - kreacity-ai

volumes:
  hf-cache:

networks:
  kreacity-ai:
    external: true
EOF

# Version Apple Silicon (Mac M1/M2 avec MPS)
cat > docker-compose.apple-silicon.yml << 'EOF'
version: '3.8'

services:
  # Version spécifique pour Apple Silicon avec MPS
  sentence-transformers:
    image: ghcr.io/huggingface/text-embeddings-inference:latest
    command: --model-id BAAI/bge-small-en-v1.5
    environment:
      - HF_ACCELERATOR=mps
    ports:
      - "8080:80"
    volumes:
      - hf-cache:/data
    restart: unless-stopped
    networks:
      - kreacity-ai

volumes:
  hf-cache:

networks:
  kreacity-ai:
    external: true
EOF

# Démarrer les services principaux
echo "Démarrage des services de base (n8n, Qdrant, PostgreSQL, Flowise)..."
docker-compose up -d n8n qdrant db supabase flowise

# Attendre que les services soient prêts
echo "Attente du démarrage des services (10 secondes)..."
sleep 10

# Démarrer le service d'embeddings avec la configuration appropriée
if [ "$USE_GPU" = true ]; then
    echo "Démarrage du service d'embeddings avec GPU NVIDIA..."
    docker-compose -f docker-compose.gpu.yml up -d sentence-transformers
else
    # Détecter si nous sommes sur un Mac M1/M2
    if [[ $(uname -m) == 'arm64' && $(uname -s) == 'Darwin' ]]; then
        echo "Mac Apple Silicon (M1/M2) détecté, utilisation de MPS..."
        docker-compose -f docker-compose.apple-silicon.yml up -d sentence-transformers
    else
        echo "Démarrage du service d'embeddings en mode CPU uniquement..."
        docker-compose -f docker-compose.cpu.yml up -d sentence-transformers
    fi
fi

echo "Tous les services sont démarrés !"
echo "URLs des services :"
echo "- n8n: http://localhost:5678"
echo "- Flowise: http://localhost:3000"
echo "- Qdrant API: http://localhost:6333"
echo "- Embeddings API: http://localhost:8080"
echo "- PostgreSQL/Supabase: localhost:5432 (utiliser un client PostgreSQL)"
