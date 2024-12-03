-- Create a GIN index on the 'title' column using trigram operations
CREATE INDEX IF NOT EXISTS idx_music_features_title_trgm ON music_features USING GIN (title gin_trgm_ops);