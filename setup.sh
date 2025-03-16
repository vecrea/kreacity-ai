#!/bin/bash

# Créer les répertoires nécessaires
mkdir -p postgres-init
mkdir -p embeddings-api

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

# Créer un service d'embeddings simplifié (qui retourne des vecteurs aléatoires)
cat > embeddings-api/app.py << 'EOF'
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import numpy as np

app = FastAPI(title="Embeddings API - Simulation")

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
    Génère des embeddings simulés (vecteurs aléatoires).
    """
    try:
        # Dimension pour le modèle all-MiniLM-L6-v2
        dim = 384
        
        # Générer des embeddings aléatoires pour chaque texte en entrée
        embeddings = [list(np.random.rand(dim).astype(float)) for _ in request.inputs]
        
        return EmbeddingResponse(
            data=embeddings,
            model="random-embeddings-simulator",
            dimensions=dim
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def root():
    """
    Point de terminaison racine qui renvoie des informations sur l'API.
    """
    return {
        "name": "Embeddings API Simulator",
        "model": "random-embeddings-simulator",
        "device": "simulation",
        "endpoints": {
            "/embeddings": "POST - Générer des embeddings simulés"
        }
    }
EOF

# Créer le fichier requirements.txt pour le service d'embeddings
cat > embeddings-api/requirements.txt << 'EOF'
fastapi
uvicorn
numpy
pydantic
EOF

# Créer un Dockerfile pour le service d'embeddings
cat > embeddings-api/Dockerfile << 'EOF'
FROM python:3.10-slim

WORKDIR /app

COPY app.py /app/
COPY requirements.txt /app/

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 80

CMD ["python", "-m", "uvicorn", "app:app", "--host", "0.0.0.0", "--port", "80"]
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

  flowise:
    image: flowiseai/flowise:latest
    ports:
      - "3000:3000"
    environment:
      - PORT=3000
      - DATABASE_PATH=/root/.flowise
      - APIKEY_PATH=/root/.flowise
      - SECRETKEY_PATH=/root/.flowise
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

  # Service d'embeddings simplifié (pas de modèle lourd, juste un service qui retourne des vecteurs aléatoires)
  embeddings:
    build: ./embeddings-api
    ports:
      - "8080:80"
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
echo "- Embeddings API: http://localhost:8080"
echo "- PostgreSQL: localhost:5432 (utiliser un client PostgreSQL comme pgAdmin)"
