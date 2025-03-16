# Structure des dossiers du projet Kreacity AI

```
kreacity-ai/
├── docker-compose.yml          # Configuration principale des services Docker
├── setup.sh                    # Script d'installation principal
├── update-dimension.sh         # Script pour ajuster la dimension des vecteurs dans Qdrant
├── README.md                   # Documentation principale
├── postgres-init/              # Scripts d'initialisation PostgreSQL
│   └── init-documents-db.sql   # Création de la DB documents et tables
├── examples/                   # Exemples d'utilisation
│   ├── n8n/                    # Exemples pour n8n
│   │   ├── document-processing-mistral.json  # Workflow de traitement de documents
│   │   └── semantic-search-mistral.json      # Workflow de recherche sémantique
│   ├── flowise/                # Exemples pour Flowise
│   │   └── rag-workflow-mistral.json         # Workflow RAG
│   └── README.md               # Documentation des exemples
└── docs/                       # Documentation détaillée
    ├── mistral-embeddings.md   # Guide d'utilisation de Mistral AI
    └── architecture.md         # Explication de l'architecture
```

Cette structure organise le projet de manière logique et rend facile l'accès aux différentes parties:

- Les fichiers de configuration Docker et scripts d'installation sont à la racine
- Les exemples prêts à l'emploi sont dans le dossier `examples/`
- La documentation détaillée est dans le dossier `docs/`
- Les scripts d'initialisation sont dans leurs dossiers respectifs

Pour utiliser cette structure, clonez simplement le dépôt et exécutez le script `setup.sh` à la racine.
