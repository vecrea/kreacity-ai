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
