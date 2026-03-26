-- =============================================================================
-- NEXUS-AIKALABS — PostgreSQL Initialization
-- =============================================================================
-- Runs ONCE on first container start.
--
-- Architecture:
--   One PostgreSQL instance, one database (corporate_brain), multiple schemas.
--   Each service gets its own schema with its own user role.
--   Directus has RBAC + audit log on every operation.
--   Agno agents can ONLY read/insert via Directus API — never delete directly.
--
-- Schemas:
--   public       — Directus system tables (directus_*)
--   app          — Business data managed by Directus (contacts, tickets, etc.)
--   agno_memory  — Agno sessions, chat history, memory, learnings, pgvector
--   n8n          — n8n workflow state, executions, credentials
--   prefect      — Prefect flow runs, task state, logs
-- =============================================================================

-- The default database "directus" is created by POSTGRES_DB env var.
-- We rename the concept: this single DB is the corporate brain.

-- =============================================================================
-- SCHEMAS
-- =============================================================================

-- Business data schema (Directus manages this via its admin UI)
CREATE SCHEMA IF NOT EXISTS app;

-- Agno agent memory and knowledge
CREATE SCHEMA IF NOT EXISTS agno_memory;

-- n8n workflow engine
CREATE SCHEMA IF NOT EXISTS n8n;

-- Prefect orchestration
CREATE SCHEMA IF NOT EXISTS prefect;

-- =============================================================================
-- EXTENSIONS
-- =============================================================================

-- pgvector for embeddings (used by Agno knowledge base in agno_memory schema)
CREATE EXTENSION IF NOT EXISTS vector;

-- =============================================================================
-- ROLES AND PERMISSIONS
-- =============================================================================

-- Role for Agno: can read business data, can write to its own schema,
-- CANNOT delete or update business data directly.
-- All business data mutations go through Directus REST API (which enforces RBAC).

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'agno_role') THEN
        CREATE ROLE agno_role;
    END IF;
END
$$;

-- Agno owns its memory schema (full CRUD)
GRANT ALL ON SCHEMA agno_memory TO agno_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA agno_memory GRANT ALL ON TABLES TO agno_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA agno_memory GRANT ALL ON SEQUENCES TO agno_role;

-- Agno can READ business data in app schema (for knowledge queries)
GRANT USAGE ON SCHEMA app TO agno_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA app GRANT SELECT ON TABLES TO agno_role;

-- Agno can READ Directus system tables (for MCP server compatibility)
GRANT USAGE ON SCHEMA public TO agno_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO agno_role;

-- Agno CANNOT delete or update anything in app or public schemas
-- (no INSERT, UPDATE, DELETE grants on app/public)

-- Role for n8n: owns its schema
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'n8n_role') THEN
        CREATE ROLE n8n_role;
    END IF;
END
$$;

GRANT ALL ON SCHEMA n8n TO n8n_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA n8n GRANT ALL ON TABLES TO n8n_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA n8n GRANT ALL ON SEQUENCES TO n8n_role;

-- Role for Prefect: owns its schema
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'prefect_role') THEN
        CREATE ROLE prefect_role;
    END IF;
END
$$;

GRANT ALL ON SCHEMA prefect TO prefect_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA prefect GRANT ALL ON TABLES TO prefect_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA prefect GRANT ALL ON SEQUENCES TO prefect_role;

-- =============================================================================
-- SERVICE USERS (login roles that inherit from the above)
-- =============================================================================

-- Agno user (inherits agno_role permissions)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'agno_user') THEN
        CREATE USER agno_user WITH PASSWORD 'agno_password' IN ROLE agno_role;
    END IF;
END
$$;

-- n8n user
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'n8n_user') THEN
        CREATE USER n8n_user WITH PASSWORD 'n8n_password' IN ROLE n8n_role;
    END IF;
END
$$;

-- Prefect user
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'prefect_user') THEN
        CREATE USER prefect_user WITH PASSWORD 'prefect_password' IN ROLE prefect_role;
    END IF;
END
$$;

-- =============================================================================
-- SEARCH PATH (so each service sees its own tables by default)
-- =============================================================================

ALTER USER agno_user SET search_path TO agno_memory, public;
ALTER USER n8n_user SET search_path TO n8n, public;
ALTER USER prefect_user SET search_path TO prefect, public;

-- The main POSTGRES_USER (nexus) is the superuser used by Directus.
-- Directus manages public (system) and app (business) schemas.
