#!/bin/bash

# Script pour mettre à jour la dimension des vecteurs dans Qdrant
# Utilisez ce script si vous changez de modèle d'embeddings

# Configuration
MODEL_NAME=$1
DIMENSION=$2

if [ -z "$MODEL_NAME" ] || [ -z "$DIMENSION" ]; then
  echo "Usage: ./update-dimension.sh <model_name> <dimension>"
  echo "Example: ./update-dimension.sh Xenova/all-MiniLM-L6-v2 384"
  echo
  echo "Modèles courants et leurs dimensions:"
  echo "- Xenova/all-MiniLM-L6-v2: 384 (défaut)"
  echo "- Xenova/multilingual-e5-small: 384"
  echo "- Xenova/paraphrase-multilingual-MiniLM-L12-v2: 384"
  exit 1
fi

# Mettre à jour la configuration dans docker-compose.yml
echo "Mise à jour du modèle dans les fichiers docker-compose..."
for file in docker-compose.cpu.yml docker-compose.gpu.yml docker-compose.apple-silicon.yml; do
  if [ -f "$file" ]; then
    sed -i.bak "s/MODEL_ID=.*/MODEL_ID=$MODEL_NAME/g" "$file"
    rm -f "$file.bak"
    echo "  Fichier $file mis à jour"
  fi
done

# Mettre à jour la configuration Qdrant
echo "Mise à jour de la configuration Qdrant pour utiliser des vecteurs de dimension $DIMENSION..."
sed -i.bak "s/\"size\": [0-9][0-9]*/\"size\": $DIMENSION/g" docker-compose.yml
rm -f docker-compose.yml.bak

echo "Redémarrage de Qdrant et du service d'embeddings..."
# Arrêter les services
docker-compose stop qdrant
docker-compose -f docker-compose.cpu.yml stop sentence-transformers
docker-compose -f docker-compose.gpu.yml stop sentence-transformers
docker-compose -f docker-compose.apple-silicon.yml stop sentence-transformers

# Supprimer les données Qdrant existantes pour éviter les problèmes de dimension
echo "Suppression des données Qdrant existantes..."
docker volume rm kreacity-ai_qdrant_data || true
docker-compose up -d qdrant

echo "Création de la collection vectors avec la nouvelle dimension..."
sleep 5
curl -X PUT 'http://localhost:6333/collections/vectors' -H 'Content-Type: application/json' -d "{
  \"vectors\": {
    \"size\": $DIMENSION,
    \"distance\": \"Cosine\"
  }
}"

# Redémarrer le service d'embeddings approprié
echo "Redémarrage du service d'embeddings..."
./setup.sh

echo "Mise à jour terminée ! Le système utilise maintenant le modèle $MODEL_NAME avec des vecteurs de dimension $DIMENSION."
