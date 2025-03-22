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
