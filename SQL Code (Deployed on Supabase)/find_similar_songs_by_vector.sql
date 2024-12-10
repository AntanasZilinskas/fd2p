-- Create or Replace the function
CREATE OR REPLACE FUNCTION find_similar_songs_by_vector(
    input_vector vector(128),
    top_n INT DEFAULT 10
) RETURNS TABLE (
    id INT,
    title TEXT,
    creators TEXT[],
    similarity FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        mf.id,
        mf.title,
        mf.creators,
        1 - (mf.feature_vector <=> input_vector) AS similarity
    FROM
        music_features mf
    ORDER BY
        mf.feature_vector <=> input_vector
    LIMIT top_n;
END;
$$ LANGUAGE plpgsql STABLE;