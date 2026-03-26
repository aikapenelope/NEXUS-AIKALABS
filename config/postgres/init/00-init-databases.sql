-- =============================================================================
-- NEXUS-AIKALABS — PostgreSQL Initialization
-- =============================================================================
-- Runs ONCE on first container start.
--
-- Architecture: single database, multiple schemas.
--   public       — Directus system tables (directus_*)
--   app          — Business data managed by Directus
--   agno_memory  — Agno sessions, memory, knowledge, pgvector embeddings
--   n8n          — n8n workflow state, executions, credentials
--   prefect      — Prefect flow runs, task state, logs
-- =============================================================================

-- Schemas
CREATE SCHEMA IF NOT EXISTS app;
CREATE SCHEMA IF NOT EXISTS agno_memory;
CREATE SCHEMA IF NOT EXISTS n8n;
CREATE SCHEMA IF NOT EXISTS prefect;

-- pgvector extension (for Agno knowledge base embeddings)
CREATE EXTENSION IF NOT EXISTS vector;

-- Roles with restricted permissions
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'agno_role') THEN CREATE ROLE agno_role; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'n8n_role') THEN CREATE ROLE n8n_role; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'prefect_role') THEN CREATE ROLE prefect_role; END IF; END $$;

-- Agno: full CRUD on agno_memory, READ-ONLY on app/public (cannot delete business data)
GRANT ALL ON SCHEMA agno_memory TO agno_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA agno_memory GRANT ALL ON TABLES TO agno_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA agno_memory GRANT ALL ON SEQUENCES TO agno_role;
GRANT USAGE ON SCHEMA app TO agno_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA app GRANT SELECT ON TABLES TO agno_role;
GRANT USAGE ON SCHEMA public TO agno_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO agno_role;

-- n8n: full CRUD on n8n schema only
GRANT ALL ON SCHEMA n8n TO n8n_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA n8n GRANT ALL ON TABLES TO n8n_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA n8n GRANT ALL ON SEQUENCES TO n8n_role;

-- Prefect: full CRUD on prefect schema only
GRANT ALL ON SCHEMA prefect TO prefect_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA prefect GRANT ALL ON TABLES TO prefect_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA prefect GRANT ALL ON SEQUENCES TO prefect_role;

-- Service users
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'agno_user') THEN CREATE USER agno_user WITH PASSWORD 'agno_password' IN ROLE agno_role; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'n8n_user') THEN CREATE USER n8n_user WITH PASSWORD 'n8n_password' IN ROLE n8n_role; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'prefect_user') THEN CREATE USER prefect_user WITH PASSWORD 'prefect_password' IN ROLE prefect_role; END IF; END $$;

-- Search paths (each service sees its own tables by default)
ALTER USER agno_user SET search_path TO agno_memory, public;
ALTER USER n8n_user SET search_path TO n8n, public;
ALTER USER prefect_user SET search_path TO prefect, public;
