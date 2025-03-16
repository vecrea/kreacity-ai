# Guide d'utilisation des embeddings Mistral AI

Ce document explique comment configurer et utiliser Mistral AI comme service d'embeddings dans Kreacity AI Stack.

## Création d'un compte Mistral AI

1. Rendez-vous sur [https://console.mistral.ai/](https://console.mistral.ai/)
2. Inscrivez-vous et créez un compte
3. Une fois connecté, allez dans "API Keys" dans le menu de gauche
4. Cliquez sur "Create API Key" et donnez un nom à votre clé
5. Copiez la clé API générée (elle ne sera affichée qu'une seule fois)

## Configuration de Mistral AI dans n8n

### 1. Créer une credential HTTP Header Auth

1. Dans n8n, allez dans "Credentials" depuis le menu principal
2. Cliquez sur "Add Credential"
3. Sélectionnez "HTTP Header Auth"
4. Configurez comme suit :
   - Name: Mistral API Key
   - Parameter Name: Authorization
   - Parameter Value: Bearer VOTRE_CLE_API_MISTRAL
5. Sauvegardez la credential

### 2. Utilisation dans les workflows

Dans vos workflows n8n, vous pouvez maintenant accéder à l'API Mistral AI comme ceci:

```
URL: https://api.mistral.ai/v1/embeddings
Method: POST
Headers:
  - Content-Type: application/json
  - Authorization: Bearer VOTRE_CLE_API_MISTRAL (via credential)
Body:
  {
    "model": "mistral-embed",
    "input": "Votre texte à encoder"
  }
```

## Configuration de Mistral AI dans Flowise

1. Dans l'interface Flowise, ajoutez un nœud "MistralAI Embeddings" 
2. Dans les paramètres du nœud, entrez votre clé API Mistral
3. Sélectionnez le modèle "mistral-embed"
4. Connectez ce nœud à vos autres composants (par exemple, Qdrant Vector Store)

## Notes importantes

### Dimension des vecteurs

Les embeddings Mistral AI génèrent des vecteurs de dimension 1024. La configuration par défaut de Qdrant dans Kreacity AI est déjà configurée pour cette dimension.

Si vous aviez auparavant utilisé un autre service d'embeddings avec une dimension différente, vous devrez mettre à jour la dimension dans Qdrant:

```bash
./update-dimension.sh mistral 1024
```

### Tarification

Mistral AI propose une période d'essai gratuite, mais ensuite l'utilisation est facturée. Les embeddings ont généralement un coût par token moins élevé que les modèles LLM. Consultez leur [page de tarification](https://docs.mistral.ai/platform/pricing/) pour plus d'informations.

### Sécurité

Votre clé API Mistral AI est sensible. Ne la partagez pas et ne l'exposez pas dans du code public. Dans n8n et Flowise, utilisez toujours les mécanismes de gestion de credentials pour stocker cette clé.

## Exemples de requêtes directes à l'API

Pour tester l'API Mistral AI directement (par exemple, avec curl):

```bash
curl -X POST https://api.mistral.ai/v1/embeddings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer VOTRE_CLE_API_MISTRAL" \
  -d '{
    "model": "mistral-embed",
    "input": "Voici un exemple de texte à encoder en vecteur"
  }'
```

La réponse sera au format:

```json
{
  "id": "embd-12345...",
  "object": "embedding",
  "data": [
    {
      "object": "embedding",
      "embedding": [0.123, 0.456, ...],
      "index": 0
    }
  ],
  "model": "mistral-embed",
  "usage": {
    "prompt_tokens": 9,
    "total_tokens": 9
  }
}
```
