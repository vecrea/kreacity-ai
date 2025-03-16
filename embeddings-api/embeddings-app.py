import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import torch
from sentence_transformers import SentenceTransformer
import numpy as np

app = FastAPI(title="Embeddings API")

# Configurer le modèle
MODEL_ID = os.environ.get("MODEL_ID", "all-MiniLM-L6-v2")
USE_MPS = os.environ.get("USE_MPS", "0") == "1"
USE_CUDA = os.environ.get("USE_CUDA", "0") == "1"

print(f"Chargement du modèle {MODEL_ID}")
print(f"USE_MPS: {USE_MPS}, USE_CUDA: {USE_CUDA}")

# Déterminer le device à utiliser
if USE_CUDA and torch.cuda.is_available():
    device = torch.device("cuda")
    print("Utilisation de CUDA")
elif USE_MPS and hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
    device = torch.device("mps")
    print("Utilisation de MPS (Apple Silicon)")
else:
    device = torch.device("cpu")
    print("Utilisation du CPU")

# Charger le modèle SentenceTransformer (plus simple que le code original)
model = SentenceTransformer(MODEL_ID, device=str(device))

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
    Compatible avec les API d'embeddings standards.
    """
    try:
        # Utiliser SentenceTransformer directement
        embeddings = model.encode(request.inputs, normalize_embeddings=True)
        
        # Convertir les embeddings en liste
        embeddings_list = embeddings.tolist()
        dimensions = len(embeddings_list[0]) if embeddings_list else 0
        
        return EmbeddingResponse(
            data=embeddings_list,
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
