-- =============================================================================
-- NEXUS-AIKALABS — PostgreSQL Initialization
-- =============================================================================
-- This script runs ONCE on first container start.
-- Creates isolated databases for each service.
-- =============================================================================

-- Directus database (created by POSTGRES_DB env var, but ensure pgvector)
-- Note: The "directus" database is created automatically by the postgres image
-- via the POSTGRES_DB environment variable.

-- Agno database (sessions, memory, knowledge with pgvector)
CREATE DATABASE agno;

-- n8n database (workflow state, executions, credentials)
CREATE DATABASE n8n;

-- Prefect database (workflow runs, task state, logs)
CREATE DATABASE prefect;

-- Enable pgvector extension in the agno database (for embeddings/knowledge)
\c agno
CREATE EXTENSION IF NOT EXISTS vector;

-- Enable pgvector in directus too (future-proofing for semantic search)
\c directus
CREATE EXTENSION IF NOT EXISTS vector;
