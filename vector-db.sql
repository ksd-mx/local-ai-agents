-- Enable vector extension if available (for AI capabilities)
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;

-- Create dedicated schema for vector-related objects
CREATE SCHEMA IF NOT EXISTS ai;

-- Create a documents table for vector embeddings in the ai schema
CREATE TABLE IF NOT EXISTS ai.documents (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  embedding vector(384)
);

-- Create vector index
CREATE INDEX IF NOT EXISTS documents_embedding_index 
ON ai.documents USING hnsw (embedding vector_l2_ops);

-- Create a simple similarity search function
CREATE OR REPLACE FUNCTION ai.search_documents(query_embedding vector(384), match_threshold float, match_count int)
RETURNS TABLE (
  id int,
  title text,
  body text,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    documents.id,
    documents.title,
    documents.body,
    1 - (documents.embedding <=> query_embedding) AS similarity
  FROM ai.documents documents
  WHERE 1 - (documents.embedding <=> query_embedding) > match_threshold
  ORDER BY similarity DESC
  LIMIT match_count;
END;
$$;

-- Confirm to the user
DO $$
BEGIN
  RAISE NOTICE 'Supabase vector extensions and tables created successfully';
END
$$;