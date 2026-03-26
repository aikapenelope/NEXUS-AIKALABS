-- =============================================================================
-- NEXUS-AIKALABS — PostgreSQL Initialization
-- =============================================================================
-- Single database, multiple schemas. Each service has its own user.
-- Agno can read business data but cannot delete or modify it.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS app;
CREATE SCHEMA IF NOT EXISTS agno_memory;
CREATE SCHEMA IF NOT EXISTS n8n;
CREATE SCHEMA IF NOT EXISTS prefect;

CREATE EXTENSION IF NOT EXISTS vector;

-- Roles
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'agno_role') THEN CREATE ROLE agno_role; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'n8n_role') THEN CREATE ROLE n8n_role; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'prefect_role') THEN CREATE ROLE prefect_role; END IF; END $$;

-- Agno: full CRUD on agno_memory, READ-ONLY on app/public
GRANT ALL ON SCHEMA agno_memory TO agno_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA agno_memory GRANT ALL ON TABLES TO agno_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA agno_memory GRANT ALL ON SEQUENCES TO agno_role;
GRANT USAGE ON SCHEMA app TO agno_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA app GRANT SELECT ON TABLES TO agno_role;
GRANT USAGE ON SCHEMA public TO agno_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO agno_role;

-- n8n: full CRUD on n8n schema
GRANT ALL ON SCHEMA n8n TO n8n_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA n8n GRANT ALL ON TABLES TO n8n_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA n8n GRANT ALL ON SEQUENCES TO n8n_role;

-- Prefect: full CRUD on prefect schema
GRANT ALL ON SCHEMA prefect TO prefect_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA prefect GRANT ALL ON TABLES TO prefect_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA prefect GRANT ALL ON SEQUENCES TO prefect_role;

-- Users
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'agno_user') THEN CREATE USER agno_user WITH PASSWORD 'agno_password' IN ROLE agno_role; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'n8n_user') THEN CREATE USER n8n_user WITH PASSWORD 'n8n_password' IN ROLE n8n_role; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'prefect_user') THEN CREATE USER prefect_user WITH PASSWORD 'prefect_password' IN ROLE prefect_role; END IF; END $$;

-- Search paths
ALTER USER agno_user SET search_path TO agno_memory, public;
ALTER USER n8n_user SET search_path TO n8n, public;
ALTER USER prefect_user SET search_path TO prefect, public;
