DROP FUNCTION get_song_details_by_title;

CREATE OR REPLACE FUNCTION get_song_details_by_title(song_name TEXT)
RETURNS TABLE (
    id INT,
    creators TEXT[],
    pitch_class_histogram FLOAT8[],
    interval_histogram FLOAT8[],
    melodic_contour FLOAT8[],
    chord_progressions TEXT[],
    key_signature TEXT,
    mode TEXT,
    note_duration_histogram FLOAT8[],
    average_duration FLOAT8,
    tempo FLOAT8,
    measures INT,
    time_signatures TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT music_features.id,
           music_features.creators,
           music_features.pitch_class_histogram,
           music_features.interval_histogram,
           music_features.melodic_contour,
           music_features.chord_progressions,
           music_features.key_signature,
           music_features.mode,
           music_features.note_duration_histogram,
           music_features.average_duration,
           music_features.tempo,
           music_features.measures,
           music_features.time_signatures
    FROM music_features
    WHERE LOWER(music_features.title) = LOWER(song_name)
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;