"""
NEXUS Cerebro — Shared configuration.

Centralizes database connections, model selection, and feature flags.
All agents, teams, and workflows import from here.
"""

import os

from agno.db.postgres import PostgresDb
from agno.knowledge.embedder.voyageai import VoyageAIEmbedder
from agno.knowledge.knowledge import Knowledge
from agno.models.groq import Groq
from agno.models.openai import OpenAIChat
from agno.vectordb.pgvector import PgVector, SearchType

# ---------------------------------------------------------------------------
# Database (PostgreSQL — production)
# ---------------------------------------------------------------------------
# Agno uses a dedicated user (agno_user) with search_path=agno_memory,public.
# This user can ONLY read from Directus tables (app/public schemas).
# All writes to business data go through Directus REST API (RBAC + audit).
# Agno has full CRUD on its own schema (agno_memory) for sessions, memory, etc.

AGNO_DB_URL = os.getenv(
    "AGNO_DB_URL",
    "postgresql+psycopg://agno_user:agno_password@postgres:5432/directus",
)
AGNO_VECTOR_DB_URL = os.getenv("AGNO_VECTOR_DB_URL", AGNO_DB_URL)

db = PostgresDb(db_url=AGNO_DB_URL)

# ---------------------------------------------------------------------------
# Embeddings
# ---------------------------------------------------------------------------

embedder = VoyageAIEmbedder(id="voyage-3-lite", dimensions=512)

# ---------------------------------------------------------------------------
# Knowledge Base (pgvector — production)
# ---------------------------------------------------------------------------

vector_db = PgVector(
    table_name="nexus_knowledge",
    db_url=AGNO_VECTOR_DB_URL,
    search_type=SearchType.hybrid,
    embedder=embedder,
)

knowledge_base = Knowledge(
    name="NEXUS Knowledge",
    description="Internal documents, research, and reference material",
    vector_db=vector_db,
    contents_db=db,
)

# Learnings vector DB (separate table for agent learnings over time)
learnings_vector_db = PgVector(
    table_name="nexus_learnings",
    db_url=AGNO_VECTOR_DB_URL,
    search_type=SearchType.hybrid,
    embedder=embedder,
)

learnings_knowledge = Knowledge(
    name="NEXUS Learnings",
    description="Accumulated agent learnings, patterns, and corrections",
    vector_db=learnings_vector_db,
    contents_db=db,
)

# ---------------------------------------------------------------------------
# Model Configuration
# ---------------------------------------------------------------------------
# Hybrid strategy: MiniMax (subscription, unlimited) for most agents.
# OpenAI via OpenRouter (pay-per-token) for features MiniMax can't do.
# Groq (free) for routing and background tasks.

_openrouter_kwargs = {
    "api_key": os.getenv("OPENROUTER_API_KEY"),
    "base_url": "https://openrouter.ai/api/v1",
}

_minimax_role_map = {
    "system": "system",
    "user": "user",
    "assistant": "assistant",
    "tool": "tool",
    "model": "assistant",
}

_minimax_kwargs = {
    "api_key": os.getenv("MINIMAX_API_KEY"),
    "base_url": "https://api.minimax.io/v1",
    "role_map": _minimax_role_map,
    "supports_native_structured_outputs": False,
    "supports_json_schema_outputs": False,
}

# MiniMax (subscription, use for everything that works)
TOOL_MODEL = OpenAIChat(id="MiniMax-M2.7", **_minimax_kwargs)
FAST_MODEL = OpenAIChat(id="MiniMax-M2.7", **_minimax_kwargs)

# OpenAI via OpenRouter (pay-per-token, only for incompatible features)
REASONING_MODEL = OpenAIChat(id="openai/gpt-5-mini", **_openrouter_kwargs)
FOLLOWUP_MODEL = OpenAIChat(id="openai/gpt-5-nano", **_openrouter_kwargs)
LEARNING_MODEL = OpenAIChat(id="openai/gpt-4o-mini", **_openrouter_kwargs)

# Groq (free, for routing and background tasks)
GROQ_FAST_MODEL = Groq(id="llama-3.1-8b-instant")
GROQ_ROUTING_MODEL = Groq(id="openai/gpt-oss-20b")

# ---------------------------------------------------------------------------
# Directus connection
# ---------------------------------------------------------------------------

DIRECTUS_URL = os.getenv("DIRECTUS_URL", "http://directus:8055")
DIRECTUS_TOKEN = os.getenv("DIRECTUS_TOKEN", "")
