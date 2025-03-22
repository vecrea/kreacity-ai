-- Création de la base de données documents
CREATE DATABASE documents;

-- Connexion à la base de données documents
\c documents;

-- Création d'une table pour stocker les documents
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB,
    embedding_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Création d'un index pour la recherche plein texte
CREATE INDEX idx_documents_content ON documents USING GIN (to_tsvector('english', content));

-- Création d'un index pour la recherche dans les métadonnées
CREATE INDEX idx_documents_metadata ON documents USING GIN (metadata);

-- Fonction pour mettre à jour le timestamp updated_at
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour updated_at automatiquement
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON documents
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- Création d'une table pour les chunks de documents
CREATE TABLE chunks (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES documents(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    metadata JSONB,
    embedding_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Création d'un index pour la recherche plein texte sur les chunks
CREATE INDEX idx_chunks_content ON chunks USING GIN (to_tsvector('english', content));
