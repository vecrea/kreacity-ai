# Kreacity AI

Une stack d'IA complète, auto-hébergée et entièrement locale, combinant :

- **n8n** (port 5678) : Automatisation de workflows
- **Qdrant** (port 6333) : Base de données vectorielle
- **Supabase/PostgreSQL** (port 5432) : Base de données SQL
- **Flowise** (port 3000) : Construction de flux IA sans code
- **Embeddings locaux** (port 8080) : Service d'embeddings indépendant

## 🚀 Installation rapide

```bash
# Cloner le dépôt
git clone https://github.com/vecrea/kreacity-ai.git
cd kreacity-ai
chmod +x setup.sh update-dimension.sh


# Lancer l'installation
./setup.sh
```

Le script détecte automatiquement votre matériel et configure le système en conséquence.

## 💻 Configuration matérielle

Le système s'adapte automatiquement à votre matériel :

- **Mac M1/M2 (Apple Silicon)** : Utilise MPS pour l'accélération
- **PC avec GPU NVIDIA** : Utilise CUDA pour l'accélération (activez avec `USE_GPU=true` dans setup.sh)
- **PC sans GPU** : Utilise le CPU uniquement (configuration par défaut)

## 🔗 Accès aux services

Une fois installé, les services sont disponibles aux adresses suivantes :

- **n8n** : http://localhost:5678
- **Flowise** : http://localhost:3000
- **Qdrant API** : http://localhost:6333
- **Embeddings API** : http://localhost:8080
- **PostgreSQL** : localhost:5432 (utilisez un client PostgreSQL comme pgAdmin)

## 📋 Fonctionnalités

- **100% local** : Aucune dépendance à des services cloud
- **Communication inter-services** : Tous les services peuvent communiquer entre eux
- **Préconfiguration** : Base de données "documents" et collection "vectors" créées automatiquement
- **Multi-plateforme** : Fonctionne sur Linux, macOS et Windows (avec Docker)

## 🛠️ Personnalisation

### Changer le modèle d'embeddings

Pour utiliser un modèle d'embeddings différent :

```bash
./update-dimension.sh sentence-transformers/all-MiniLM-L6-v2 384
```

Modèles recommandés :
- `BAAI/bge-small-en-v1.5` : 384 dimensions (défaut)
- `sentence-transformers/all-MiniLM-L6-v2` : 384 dimensions
- `intfloat/e5-large-v2` : 1024 dimensions
- `intfloat/multilingual-e5-large` : 1024 dimensions

## 📚 Exemples d'utilisation

### n8n + Embeddings + Qdrant

Vous trouverez dans le dossier `examples/n8n` des workflows pour :
- Traiter des documents avec extraction de texte
- Générer des embeddings et les stocker dans Qdrant
- Effectuer des recherches sémantiques

### Flowise + Embeddings locaux

Dans le dossier `examples/flowise` :
- Configuration pour utiliser le service d'embeddings local
- Workflows RAG (Retrieval Augmented Generation)

## Nettoyage total, si tu veux tout éliminer pour recommencer
⚠️ Attention : Cette commande arrête et supprime tous les conteneurs, volumes et réseaux Docker. N'utilisez cette commande que si vous êtes sûr de ne pas avoir de données importantes dans vos conteneurs Docker existants.

```bash
docker stop $(docker ps -a -q) || true \
&& docker rm $(docker ps -a -q) || true \
&& docker volume prune -f \
&& docker network prune -f \
&& docker image prune -a -f \
&& echo "Vérification des ports utilisés:" \
&& echo "Port 5678 (n8n):" && lsof -i :5678 || echo "Libre" \
&& echo "Port 6333 (Qdrant):" && lsof -i :6333 || echo "Libre" \
&& echo "Port 5432 (PostgreSQL):" && lsof -i :5432 || echo "Libre" \
&& echo "Port 3000 (Flowise):" && lsof -i :3000 || echo "Libre" \
&& echo "Port 8080 (Embeddings):" && lsof -i :8080 || echo "Libre" \
&& echo "Docker est maintenant nettoyé et prêt pour un test."
```

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.

## 📄 Licence

Ce projet est sous licence MIT.