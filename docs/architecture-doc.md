# Architecture de Kreacity AI Stack

Ce document explique l'architecture globale de Kreacity AI Stack, comment les différents composants interagissent et les principes de conception.

## Vue d'ensemble

Kreacity AI Stack est une solution complète pour déployer une infrastructure d'IA locale avec les composants suivants :

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    n8n      │     │   Flowise   │     │  Embeddings │
│  Workflows  │◄────►  AI Flows   │◄────► Local Model │
└─────┬───────┘     └─────┬───────┘     └─────────────┘
      │                   │                    ▲
      │                   │                    │
      │                   │                    │
      ▼                   ▼                    │
┌─────────────┐     ┌─────────────┐           │
│   Qdrant    │◄────►  PostgreSQL │           │
│  Vectors DB │     │    DB       │◄──────────┘
└─────────────┘     └─────────────┘
```

## Composants principaux

### n8n (Port 5678)
- **Rôle** : Orchestration des workflows et automatisation
- **Responsabilités** :
  - Traitement de documents
  - Extraction de texte
  - Génération d'embeddings via le service local
  - Stockage de documents dans PostgreSQL et Qdrant
  - Exposition d'APIs pour la recherche sémantique

### Flowise (Port 3000)
- **Rôle** : Construction de flux d'IA sans code
- **Responsabilités** :
  - Création de chatbots
  - Construction de systèmes RAG (Retrieval Augmented Generation)
  - Connexion aux bases de données et aux services d'embeddings

### Service d'embeddings (Port 8080)
- **Rôle** : Transformation de texte en vecteurs numériques
- **Responsabilités** :
  - Fourniture d'embeddings via une API standardisée
  - Support de différents modèles (bge-small-en-v1.5 par défaut)
  - Optimisation selon le matériel (GPU, CPU, MPS)

### Qdrant (Port 6333)
- **Rôle** : Stockage et recherche de vecteurs d'embeddings
- **Responsabilités** :
  - Stockage efficace des vecteurs d'embeddings
  - Recherche rapide par similarité cosinus
  - Gestion de la collection "vectors"

### PostgreSQL/Supabase (Port 5432)
- **Rôle** : Stockage relationnel de documents et métadonnées
- **Responsabilités** :
  - Stockage du texte complet des documents
  - Gestion des métadonnées associées
  - Maintien de la base de données "documents"

## Flux de données

### Indexation de documents
1. Un document est soumis à n8n
2. n8n extrait le texte du document
3. Le service d'embeddings génère des vecteurs pour le texte
4. Les vecteurs sont stockés dans Qdrant
5. Le texte complet et les métadonnées sont stockés dans PostgreSQL

### Recherche sémantique
1. Une requête est soumise à l'API de recherche
2. Le service d'embeddings génère un vecteur pour la requête
3. Qdrant trouve les documents similaires en fonction de la similarité vectorielle
4. PostgreSQL récupère le texte complet des documents trouvés
5. Les résultats sont renvoyés, classés par pertinence

## Principes de conception

### 1. Isolation des services
Chaque service fonctionne dans son propre conteneur Docker, assurant une isolation et une portabilité optimales.

### 2. Communication inter-services
Les services communiquent via un réseau Docker nommé "kreacity-ai", permettant une découverte de service par nom.

### 3. Persistance des données
Toutes les données sont stockées dans des volumes Docker nommés pour assurer la persistance entre les redémarrages.

### 4. Adaptation au matériel
Le système détecte automatiquement le matériel disponible (GPU NVIDIA, Apple Silicon, CPU) et optimise la configuration en conséquence.

### 5. Configuration centralisée
Les paramètres principaux sont regroupés en haut des scripts pour faciliter la personnalisation.

## Sécurité

La configuration actuelle est optimisée pour un déploiement local. Pour un déploiement en production, considérez les améliorations suivantes :

- Ajouter une authentification aux services exposés
- Utiliser des mots de passe forts pour les bases de données
- Mettre en place un reverse proxy avec HTTPS
- Limiter l'exposition des ports aux seuls nécessaires

## Extensions possibles

L'architecture est conçue pour être extensible. Voici quelques extensions possibles :

- Ajout d'un service LLM local (Ollama, LM Studio, etc.)
- Intégration d'un service OCR pour les documents numérisés
- Ajout d'un système de monitoring et de logging
- Intégration avec d'autres bases de données ou services
