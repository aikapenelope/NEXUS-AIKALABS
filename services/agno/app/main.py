"""
NEXUS Cerebro — AgentOS Entry Point.

Production entry point that registers all agents, teams, and workflows.
Uses PostgreSQL + pgvector (configured in app.config).

The modular agents in agents/ are the target architecture.
nexus_legacy.py contains the full original system and is imported here
until the full refactor is complete.
"""

import os
import sys

from agno.os import AgentOS

try:
    from agno.os.interfaces.agui import AGUI

    _agui_available = True
except ImportError:
    _agui_available = False

from agno.os.interfaces.whatsapp.whatsapp import Whatsapp

# ---------------------------------------------------------------------------
# Production database override
# ---------------------------------------------------------------------------
# The legacy nexus.py uses SqliteDb and LanceDb. We monkey-patch the db and
# vector_db objects BEFORE importing nexus_legacy so all agents use PostgreSQL.
# This is a transitional approach until the full modular refactor is done.

from app.config import db, knowledge_base, learnings_knowledge, vector_db

# Make config available as a module-level import for nexus_legacy
sys.modules["app.config"] = sys.modules[__name__]

# Import modular agents (production-ready, PostgreSQL-native)
from agents.research import research_agent
from agents.knowledge import knowledge_agent
from agents.support import support_agent

# ---------------------------------------------------------------------------
# Interfaces
# ---------------------------------------------------------------------------

interfaces: list = []

if _agui_available:
    interfaces.append(AGUI())

# WhatsApp interface (enabled when credentials are set)
if os.getenv("WHATSAPP_ACCESS_TOKEN"):
    interfaces.append(Whatsapp(agent=support_agent))

# ---------------------------------------------------------------------------
# AgentOS — Core agents (modular, production-ready)
# ---------------------------------------------------------------------------
# Start with the 3 core agents. Additional agents from nexus_legacy.py
# can be added incrementally as they are refactored into modules.

agent_os = AgentOS(
    id="nexus",
    description="NEXUS Cerebro Corporativo — Enterprise AI Workspace",
    agents=[
        research_agent,
        knowledge_agent,
        support_agent,
    ],
    teams=[],
    workflows=[],
    knowledge=[knowledge_base],
    interfaces=interfaces or None,
    db=db,
    tracing=True,
    scheduler=True,
    scheduler_poll_interval=30,
)

app = agent_os.get_app()
