Voici un README complet pour le projet Kreacity AI :

# Kreacity AI Platform

![Version](https://img.shields.io/badge/version-1.5.0-blue)

Kreacity AI est une plateforme locale d'intelligence artificielle tout-en-un, déployable via Docker pour une installation simple et rapide. Elle intègre des outils d'automatisation, de traitement vectoriel et de modèles d'IA locaux pour créer un environnement complet de développement et de déploiement d'applications IA.

## 🌟 Fonctionnalités

- **Modèles d'IA locaux** avec Ollama pour le traitement de langage naturel et embeddings
- **Base de données vectorielle** avec Qdrant pour la recherche sémantique
- **Workflows d'IA** avec une interface graphique intuitive via FloWise
- **Automatisation de flux** avec n8n pour créer des intégrations complexes
- **Dashboard unifié** pour accéder facilement à tous les services
- **Compatibilité ARM64** pour les machines Apple Silicon

## 📋 Prérequis

- Docker et Docker Compose
- 8 Go de RAM minimum (16 Go recommandés)
- 20 Go d'espace disque libre
- Une connexion internet pour le téléchargement initial

## 🚀 Installation

1. Clonez ce dépôt :
   ```bash
   git clone https://github.com/vecrea/kreacity-ai.git
   cd kreacity-ai
   ```

2. Lancez le script d'installation :
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. Une fois l'installation terminée, accédez au dashboard :
   ```
   http://localhost:8080
   ```

## 🔧 Services disponibles

| Service | Description | URL |
|---------|-------------|-----|
| FloWise | Plateforme de création de workflows d'IA | http://localhost:3000 |
| n8n | Automatisation et workflows | http://localhost:5678 |
| Qdrant | Base de données vectorielle | http://localhost:6333 |
| Ollama | Modèles d'IA locaux | http://localhost:11434 |
| PostgreSQL | Base de données relationnelle | localhost:5555 |

## 🌐 Webhooks & Tunneling

Kreacity AI intègre un service de tunneling pour exposer facilement vos workflows n8n à Internet. Pour voir l'URL publique générée :

```bash
docker logs webhook-forwarder
```

## 🔍 Structure des données

- **n8n-data/** : Stockage des workflows n8n
- **flowise-data/** : Configurations et données FloWise
- **qdrant-data/** : Base de données vectorielle
- **postgres-data/** : Base de données PostgreSQL
- **ollama-data/** : Modèles d'IA téléchargés

## 🧩 Modèles d'embedding disponibles

- **mxbai-embed-large** : Modèle principal pour la génération d'embeddings
- **nomic-embed-text** : Modèle de secours

## 🔐 Configuration des API externes (optionnel)

Si vous souhaitez intégrer des services externes, modifiez le fichier `.env.tokens` :

```bash
# Décommentez et ajoutez vos tokens API si nécessaire
# NOTION_API_KEY=your_token_here
# GOOGLE_APPLICATION_CREDENTIALS=./google-credentials.json
```

## 🛠️ Administration

### Redémarrer les services
```bash
docker-compose restart
```

### Voir les logs
```bash
docker-compose logs -f
```

### Mettre à jour les services
```bash
docker-compose pull
docker-compose up -d
```

## 📚 Exemples d'utilisation

1. **Analyse de documents** : Utilisez FloWise pour créer un workflow d'extraction et d'analyse de texte
2. **Recherche sémantique** : Stockez des embeddings dans Qdrant et recherchez du contenu par similarité
3. **Chatbot local** : Déployez un assistant IA utilisant les modèles Ollama sans dépendance externe
4. **Automatisation de données** : Créez des pipelines de traitement de données avec n8n et FloWise

## 🤝 Contribuer

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.

## 📜 Licence

Ce projet est distribué sous licence MIT. Voir le fichier `LICENSE` pour plus d'informations.

---

Développé avec ❤️ par Kreacity AI Team