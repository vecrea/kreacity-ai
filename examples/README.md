# Exemples d'utilisation de Kreacity AI Stack

Ce répertoire contient des exemples prêts à l'emploi pour exploiter la puissance de Kreacity AI Stack.

## Exemples n8n

### Traitement de documents (`document-processing.json`)

Ce workflow permet de :
1. Lire un document (PDF, texte, etc.)
2. Extraire son contenu textuel
3. Générer des embeddings avec le service local
4. Stocker le document dans PostgreSQL
5. Stocker les embeddings dans Qdrant

**Comment l'utiliser :**
1. Importez le workflow dans n8n
2. Configurez les informations d'authentification pour PostgreSQL
3. Testez avec un document PDF ou texte

### Recherche sémantique (`semantic-search.json`)

Ce workflow expose un webhook qui permet de :
1. Recevoir une requête de recherche
2. Transformer cette requête en embeddings
3. Rechercher les documents similaires dans Qdrant
4. Récupérer les documents complets depuis PostgreSQL
5. Renvoyer les résultats les plus pertinents

**Comment l'utiliser :**
1. Importez le workflow dans n8n
2. Activez le webhook
3. Faites une requête POST avec un payload JSON comme ceci :
   ```json
   {
     "query": "Votre question ou recherche ici",
     "limit": 5,
     "threshold": 0.7
   }
   ```

## Exemples Flowise

### Workflow RAG (`rag-workflow.json`)

Ce workflow illustre comment implémenter un système de Retrieval Augmented Generation (RAG) avec :
1. Un service d'embeddings local
2. Qdrant comme base de données vectorielle
3. Un modèle de langage (Ollama est utilisé dans l'exemple)

**Comment l'utiliser :**
1. Importez le workflow dans Flowise
2. Assurez-vous que la collection "vectors" dans Qdrant contient déjà des documents (utilisez le workflow n8n de traitement de documents pour les ajouter)
3. Remplacez la configuration du modèle de langage selon vos besoins
4. Posez des questions sur vos documents !

## Personnalisation des exemples

Ces exemples sont conçus pour être faciles à personnaliser :

- **Changement de modèle d'embeddings** : Si vous changez de modèle avec le script `update-dimension.sh`, assurez-vous de mettre à jour la dimension dans les configurations (384 par défaut pour bge-small)
- **Adaptation des chaînes de traitement** : Les workflows peuvent être adaptés pour des cas d'usage spécifiques
- **Intégration avec d'autres services** : Vous pouvez facilement connecter ces workflows à d'autres outils de votre stack