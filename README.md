# Kreacity AI

Une stack d'IA locale combinant :

- **n8n** (port 5678) : Automatisation de workflows
- **Qdrant** (port 6333) : Base de données vectorielle
- **PostgreSQL** (port 5432) : Base de données SQL
- **Flowise** (port 3000) : Construction de flux IA sans code


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

⚠️ **Attention** : Cette commande supprime tous les conteneurs, volumes et réseaux Docker, même ceux qui n'ont rien à voir avec projet.

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
(cela dit, ça ne fonctionne pas bien, donc j'ai repassé le tout en openAi avec des vecteurs de dimensions 3072)

## Exemples d'utilisation

### Workflow RAG typique dans Flowise
1. Importer des documents via "Document Loader"
2. Découper les documents en chunks avec "Text Splitter"
3. Générer des embeddings avec "MistralAI Embeddings"
4. Stocker dans "Qdrant Vector Store"
5. Configurer un nœud "Conversational Retrieval Chain"
6. Connecter à un modèle de langage (LLM) de votre choix
