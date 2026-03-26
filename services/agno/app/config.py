"""
NEXUS Cerebro — Shared configuration.

Centralizes database connections, model selection, knowledge bases,
and feature flags. All agents, teams, and workflows import from here.
"""

import os
from pathlib import Path

from agno.db.postgres import PostgresDb
from agno.knowledge.chunking.fixed_size_chunking import FixedSizeChunking
from agno.knowledge.embedder.voyageai import VoyageAIEmbedder
from agno.knowledge.knowledge import Knowledge
from agno.knowledge.reranker.cohere import CohereReranker
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
# Reranker (optional — set COHERE_API_KEY to enable)
# ---------------------------------------------------------------------------

_cohere_key = os.getenv("COHERE_API_KEY")
reranker = CohereReranker() if _cohere_key else None

# ---------------------------------------------------------------------------
# Chunking — short chunks (2000 chars) for precise retrieval.
# Docling handles document parsing; Agno chunks the resulting Markdown.
# ---------------------------------------------------------------------------

chunking = FixedSizeChunking(chunk_size=2000, overlap=200)

# ---------------------------------------------------------------------------
# Knowledge Bases (pgvector, isolated per project)
# ---------------------------------------------------------------------------
# Each project gets its own Knowledge instance with isolate_vector_search=True.
# They share the same pgvector table but are filtered by the linked_to tag.

_vector_db_kwargs = {
    "db_url": AGNO_VECTOR_DB_URL,
    "search_type": SearchType.hybrid,
    "embedder": embedder,
    "reranker": reranker,
}

knowledge_base = Knowledge(
    name="nexus-general",
    description="General company documents, research, and reference material",
    vector_db=PgVector(table_name="nexus_knowledge", **_vector_db_kwargs),
    contents_db=db,
    isolate_vector_search=True,
)

whabi_knowledge = Knowledge(
    name="nexus-whabi",
    description="Whabi product documentation, pricing, and support FAQs",
    vector_db=PgVector(table_name="nexus_knowledge", **_vector_db_kwargs),
    contents_db=db,
    isolate_vector_search=True,
)

docflow_knowledge = Knowledge(
    name="nexus-docflow",
    description="Docflow EHR documentation, compliance guides, and clinical workflows",
    vector_db=PgVector(table_name="nexus_knowledge", **_vector_db_kwargs),
    contents_db=db,
    isolate_vector_search=True,
)

aurora_knowledge = Knowledge(
    name="nexus-aurora",
    description="Aurora voice-first PWA documentation and integration guides",
    vector_db=PgVector(table_name="nexus_knowledge", **_vector_db_kwargs),
    contents_db=db,
    isolate_vector_search=True,
)

learnings_knowledge = Knowledge(
    name="nexus-learnings",
    description="Accumulated agent learnings, patterns, and corrections",
    vector_db=PgVector(table_name="nexus_learnings", **_vector_db_kwargs),
    contents_db=db,
    isolate_vector_search=True,
)

# ---------------------------------------------------------------------------
# Knowledge Loading (initial documents from knowledge/ folder)
# ---------------------------------------------------------------------------

KNOWLEDGE_DIR = Path(__file__).parent.parent / "knowledge"


def load_initial_knowledge() -> None:
    """Load documents from knowledge/ into the general knowledge base on startup."""
    if not KNOWLEDGE_DIR.exists():
        return

    from agno.knowledge.reader.markdown import MarkdownReader
    from agno.knowledge.reader.pdf import PDFReader
    from agno.knowledge.reader.csv import CSVReader
    from agno.knowledge.reader.json import JSONReader

    _readers = {
        ".md": MarkdownReader(chunking_strategy=chunking),
        ".pdf": PDFReader(chunking_strategy=chunking),
        ".csv": CSVReader(),
        ".json": JSONReader(),
        ".txt": MarkdownReader(chunking_strategy=chunking),
    }

    for file_path in sorted(KNOWLEDGE_DIR.iterdir()):
        if file_path.is_dir() or file_path.name.startswith("."):
            continue
        reader = _readers.get(file_path.suffix.lower())
        if reader:
            knowledge_base.insert(
                path=str(file_path), reader=reader, skip_if_exists=True,
            )


# ---------------------------------------------------------------------------
# Model Configuration
# ---------------------------------------------------------------------------

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

TOOL_MODEL = OpenAIChat(id="MiniMax-M2.7", **_minimax_kwargs)
FAST_MODEL = OpenAIChat(id="MiniMax-M2.7", **_minimax_kwargs)
REASONING_MODEL = OpenAIChat(id="openai/gpt-5-mini", **_openrouter_kwargs)
FOLLOWUP_MODEL = OpenAIChat(id="openai/gpt-5-nano", **_openrouter_kwargs)
LEARNING_MODEL = OpenAIChat(id="openai/gpt-4o-mini", **_openrouter_kwargs)
GROQ_FAST_MODEL = Groq(id="llama-3.1-8b-instant")
GROQ_ROUTING_MODEL = Groq(id="openai/gpt-oss-20b")

# ---------------------------------------------------------------------------
# Directus connection
# ---------------------------------------------------------------------------

DIRECTUS_URL = os.getenv("DIRECTUS_URL", "http://directus:8055")
DIRECTUS_TOKEN = os.getenv("DIRECTUS_TOKEN", "")
