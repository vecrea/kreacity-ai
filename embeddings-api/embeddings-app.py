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
