CREATE OR REPLACE FUNCTION match_similar_songs(input_vector vector(128), top_n INT DEFAULT 10)
RETURNS TABLE(
    id INT,
    title TEXT,
    similarity FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        id,
        title,
        1 - (feature_vector <=> input_vector) AS similarity
    FROM
        music_features
    ORDER BY
        feature_vector <=> input_vector
    LIMIT top_n;
END;
$$ LANGUAGE plpgsql STABLE;