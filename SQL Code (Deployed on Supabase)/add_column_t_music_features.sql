-- Add a new column for storing title embeddings
ALTER TABLE music_features ADD COLUMN title_embedding vector(384);

-- Ensure the pgvector extension is enabled
CREATE EXTENSION IF NOT EXISTS vector;