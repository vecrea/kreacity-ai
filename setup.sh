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

# Créer le fichier API wrapper pour les embeddings
mkdir -p embeddings-api
cat > embeddings-api/app.py << 'EOF'
import os
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import torch
from transformers import AutoTokenizer, AutoModel
import numpy as np

app = FastAPI(title="Embeddings API")

# Configurer le modèle
MODEL_ID = os.environ.get("MODEL_ID", "Xenova/all-MiniLM-L6-v2")
USE_MPS = os.environ.get("USE_MPS", "0") == "1"
USE_CUDA = os.environ.get("USE_CUDA", "0") == "1"

print(f"Chargement du modèle {MODEL_ID}")
print(f"USE_MPS: {USE_MPS}, USE_CUDA: {USE_CUDA}")

# Déterminer le device à utiliser
if USE_CUDA and torch.cuda.is_available():
    device = torch.device("cuda")
    print("Utilisation de CUDA")
elif USE_MPS and torch.backends.mps.is_available():
    device = torch.device("mps")
    print("Utilisation de MPS (Apple Silicon)")
else:
    device = torch.device("cpu")
    print("Utilisation du CPU")

# Charger le modèle
tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)
model = AutoModel.from_pretrained(MODEL_ID).to(device)

# Fonction pour calculer les embeddings
def get_embeddings(texts):
    inputs = tokenizer(texts, padding=True, truncation=True, return_tensors="pt").to(device)
    with torch.no_grad():
        outputs = model(**inputs)
    
    # Récupérer l'embedding de [CLS] ou faire une moyenne des tokens
    embeddings = outputs.last_hidden_state[:, 0, :].cpu().numpy()
    
    # Normaliser les embeddings
    norm = np.linalg.norm(embeddings, axis=1, keepdims=True)
    normalized_embeddings = embeddings / norm
    
    return normalized_embeddings.tolist()

# Classes pour les requêtes et réponses
class EmbeddingRequest(BaseModel):
    inputs: List[str]
    model: Optional[str] = None

class EmbeddingResponse(BaseModel):
    data: List[List[float]]
    model: str
    dimensions: int

# Routes API
@app.post("/embeddings")
async def create_embeddings(request: EmbeddingRequest):
    """
    Génère des embeddings pour les textes fournis.
    Compatible avec d'autres API d'embeddings.
    """
    try:
        embeddings = get_embeddings(request.inputs)
        dimensions = len(embeddings[0]) if embeddings else 0
        
        return EmbeddingResponse(
            data=embeddings,
            model=MODEL_ID,
            dimensions=dimensions
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def root():
    """
    Point de terminaison racine qui renvoie des informations sur l'API.
    """
    return {
        "name": "Embeddings API",
        "model": MODEL_ID,
        "device": str(device),
        "endpoints": {
            "/embeddings": "POST - Générer des embeddings pour les textes"
        }
    }

# Démarrer le serveur avec: python -m uvicorn app:app --host 0.0.0.0 --port 80
EOF

# Créer un Dockerfile personnalisé pour le service d'embeddings
cat > embeddings-api/Dockerfile << 'EOF'
FROM python:3.10-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY app.py /app/

RUN pip install --no-cache-dir fastapi uvicorn torch transformers numpy pydantic

EXPOSE 80

CMD ["python", "-m", "uvicorn", "app:app", "--host", "0.0.0.0", "--port", "80"]
EOF

# Créer les fichiers docker-compose mis à jour
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
      - ./qdrant-init:/qdrant-init
    restart: unless-stopped
    networks:
      - kreacity-ai
    command: >
      sh -c "
        qdrant --config-path /qdrant/config/config.yaml &
        sleep 10 &&
        curl -X PUT 'http://localhost:6333/collections/vectors' -H 'Content-Type: application/json' -d '{
          \"vectors\": {
            \"size\": 384,
            \"distance\": \"Cosine\"
          }
        }' &&
        tail -f /dev/null
      "

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

  supabase:
    image: supabase/supabase-postgres:15.1.0
    depends_on:
      - db
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: postgres
      PGPORT: 5432
      PGDATABASE: postgres
      PGHOST: db
      PGUSER: postgres
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

  # Le service d'embeddings est géré par des fichiers docker-compose séparés
  # Voir docker-compose.cpu.yml, docker-compose.gpu.yml, et docker-compose.apple-silicon.yml

volumes:
  n8n_data:
  qdrant_data:
  postgres_data:
  flowise_data:
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