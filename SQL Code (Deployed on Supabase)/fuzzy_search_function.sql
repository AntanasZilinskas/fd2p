CREATE OR REPLACE FUNCTION search_songs_by_title(
  search_query TEXT,
  max_results INT DEFAULT 10
) RETURNS TABLE (
  id INT,
  title TEXT,
  creators TEXT[],
  similarity NUMERIC
) LANGUAGE sql STABLE AS $$
  SELECT
    id,
    title,
    creators,
    similarity(title, search_query) AS similarity
  FROM
    music_features
  WHERE
    title ILIKE '%' || search_query || '%'
    OR similarity(title, search_query) > 0.2
  ORDER BY
    similarity DESC,
    title
  LIMIT max_results;
$$;