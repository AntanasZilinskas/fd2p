-- Enable pgvector extension if not already done
CREATE EXTENSION IF NOT EXISTS vector;

-- Create the music_features table
CREATE TABLE music_features (
    id SERIAL PRIMARY KEY,           -- Unique identifier
    title TEXT NOT NULL,             -- Song title
    creators TEXT[],                 -- Array of creators
    pitch_class_histogram FLOAT[],   -- Array for pitch class histogram
    interval_histogram FLOAT[],      -- Array for interval histogram
    melodic_contour FLOAT[],         -- Array for contour (proportional counts)
    chord_progressions TEXT[],       -- Array of chord progressions
    key_signature TEXT,              -- Key signature
    mode TEXT,                       -- Major or minor
    note_duration_histogram FLOAT[], -- Array for note duration histogram
    average_duration FLOAT,          -- Average note duration
    tempo FLOAT,                     -- Tempo
    measures INTEGER,                -- Number of measures
    time_signatures TEXT[],          -- Array of time signatures
    feature_vector vector(128)      -- Fixed-length feature vector for similarity search
);