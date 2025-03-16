# Exemples d'utilisation de Kreacity AI avec Mistral AI

Ce répertoire contient des exemples prêts à l'emploi pour exploiter la puissance de Kreacity AI Stack avec Mistral AI pour les embeddings.

## Exemples n8n

### Traitement de documents (`document-processing-mistral.json`)

Ce workflow permet de :
1. Lire un document (PDF, texte, etc.)
2. Extraire son contenu textuel
3. Générer des embeddings avec Mistral AI
4. Stocker le document dans PostgreSQL
5. Stocker les embeddings dans Qdrant

**Comment l'utiliser :**
1. Importez le workflow dans n8n
2. Configurez vos informations d'authentification pour PostgreSQL
3. Ajoutez votre clé API Mistral AI comme credential "HTTP Header Auth"
4. Testez avec un document PDF ou texte

### Recherche sémantique (`semantic-search-mistral.json`)

Ce workflow expose un webhook qui permet de :
1. Recevoir une requête de recherche
2. Transformer cette requête en embeddings via Mistral AI
3. Rechercher les documents similaires dans Qdrant
4. Récupérer les documents complets depuis PostgreSQL
5. Renvoyer les résultats les plus pertinents

**Comment l'utiliser :**
1. Importez le workflow dans n8n
2. Configurez votre clé API Mistral AI
3. Activez le webhook
4. Faites une requête POST avec un payload JSON comme ceci :
   ```json
   {
     "query": "Votre question ou recherche ici",
     "limit": 5,
     "threshold": 0.7
   }
   ```

## Exemples Flowise

### Workflow RAG (`rag-workflow-mistral.json`)

Ce workflow illustre comment implémenter un système de Retrieval Augmented Generation (RAG) avec :
1. Mistral AI pour les embeddings
2. Qdrant comme base de données vectorielle
3. Le modèle de langage Mistral Medium pour la génération

**Comment l'utiliser :**
1. Importez le workflow dans Flowise
2. Remplacez "YOUR_MISTRAL_API_KEY" par votre clé API Mistral AI
3. Assurez-vous que la collection "vectors" dans Qdrant contient déjà des documents (utilisez le workflow n8n de traitement de documents pour les ajouter)
4. Posez des questions sur vos documents !

## Notes sur l'utilisation de Mistral AI

- **Modèle d'embeddings** : Mistral AI utilise le modèle "mistral-embed" qui génère des vecteurs de dimension 1024.
- **Coût** : L'utilisation de l'API Mistral AI est payante après une période d'essai. Consultez leur site web pour les informations de tarification à jour.
- **Avantages** : Mistral AI est une entreprise européenne, ce qui peut être préférable pour la conformité RGPD.
- **Performance** : Les embeddings de Mistral offrent une très bonne performance pour la recherche sémantique.
