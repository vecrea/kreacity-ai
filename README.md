# Kreacity AI

Une stack d'IA complète, auto-hébergée et locale, combinant :

- **n8n** (port 5678) : Automatisation de workflows
- **Qdrant** (port 6333) : Base de données vectorielle
- **PostgreSQL** (port 5432) : Base de données SQL
- **Flowise** (port 3000) : Construction de flux IA sans code
- **Embeddings API** (port 8080) : Service d'embeddings simplifié

## Installation rapide

```bash
# Cloner le dépôt
git clone https://github.com/vecrea/kreacity-ai.git
cd kreacity-ai

# Lancer l'installation
chmod +x setup.sh
./setup.sh
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

⚠️ **Attention** : Cette commande supprime tous les conteneurs, volumes et réseaux Docker.

## Services disponibles

Une fois installé, les services sont disponibles aux adresses suivantes :

- **n8n** : http://localhost:5678
- **Flowise** : http://localhost:3000
- **Qdrant API** : http://localhost:6333
- **Embeddings API** : http://localhost:8080
- **PostgreSQL** : localhost:5432

## À propos du service d'embeddings

Cette version utilise un service d'embeddings simplifié qui génère des vecteurs aléatoires de dimension 384. Il est compatible avec les API d'embeddings standards mais ne fournit pas de véritables embeddings sémantiques.

Pour intégrer un vrai modèle d'embeddings, vous pouvez :
1. Utiliser une API externe comme OpenAI, Cohere ou Hugging Face
2. Intégrer un modèle léger compatible avec votre architecture
