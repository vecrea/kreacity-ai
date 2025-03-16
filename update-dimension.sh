#!/bin/bash

# Script pour mettre à jour la dimension des vecteurs dans Qdrant
# Utilisez ce script si vous changez de fournisseur d'embeddings

# Configuration
EMBEDDING_PROVIDER=$1
DIMENSION=$2

if [ -z "$EMBEDDING_PROVIDER" ] || [ -z "$DIMENSION" ]; then
  echo "Usage: ./update-dimension.sh <embedding_provider> <dimension>"
  echo "Example: ./update-dimension.sh mistral 1024"
  echo
  echo "Fournisseurs d'embeddings courants et leurs dimensions:"
  echo "- mistral: 1024"
  echo "- openai: 1536"
  echo "- cohere: 1024"
  echo "- vertexai: 768"
  exit 1
fi

# Mettre à jour la configuration Qdrant
echo "Mise à jour de la configuration Qdrant pour utiliser des vecteurs de dimension $DIMENSION..."
sed -i.bak "s/\"size\": [0-9][0-9]*/\"size\": $DIMENSION/g" docker-compose.yml
rm -f docker-compose.yml.bak

echo "Redémarrage de Qdrant..."
# Arrêter Qdrant
docker-compose stop qdrant

# Supprimer les données Qdrant existantes pour éviter les problèmes de dimension
echo "Suppression des données Qdrant existantes..."
docker volume rm kreacity-ai_qdrant_data || true

# Redémarrer Qdrant
echo "Redémarrage de Qdrant avec la nouvelle dimension..."
docker-compose up -d qdrant

echo "Mise à jour terminée ! Le système est maintenant configuré pour utiliser $EMBEDDING_PROVIDER avec des vecteurs de dimension $DIMENSION."
echo "Assurez-vous de configurer le même fournisseur d'embeddings dans Flowise."
