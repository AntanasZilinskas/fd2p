CREATE OR REPLACE FUNCTION match_similar_titles(
    input_embedding vector(384),
    top_n INT DEFAULT 10
)
RETURNS TABLE(
    title TEXT,
    similarity FLOAT
) AS $$
    SELECT
        st.title,
        1 - (st.title_embedding <#> input_embedding) AS similarity
    FROM
        song_titles st
    ORDER BY
        st.title_embedding <#> input_embedding
    LIMIT top_n;
$$ LANGUAGE SQL STABLE;