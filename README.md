# NEXUS-AIKALABS — El Cerebro Corporativo

Plataforma empresarial unificada que separa tres responsabilidades: ingesta determinista de datos, gestion del estado, y razonamiento cognitivo.

## Arquitectura

```
Internet (HTTPS via Traefik)
         |
    +---------+
    | Traefik | (reverse proxy + SSL)
    +---------+
         |
    +----+----------+----------+--------+
    |    |          |          |        |
  Next.js Directus  Agno      n8n    Prefect
  :3000   :8055     :8000     :5678  :4200
    |       |         |         |       |
    |  AG-UI|   MCP   |Directus |       |
    |<------+-(SSE)---+  Node   |       |
    |       |         |<--------+       |
    |       |  REST   |                 |
    |       |<--------+                 |
    +-------+----+----+---------+---+---+
                 |                  |
          +------+------+   +------+------+
          | PostgreSQL  |   |   Redis 7   |
          | 16+pgvector |   | (cache+queue)|
          +-------------+   +-------------+
```

## Servicios

| Servicio | Puerto | Funcion |
|----------|--------|---------|
| PostgreSQL | 5432 | Base de datos (databases: directus, agno, n8n, prefect) |
| Redis | 6379 | Cache (Directus) + colas |
| Directus | 8055 | CMS + REST/GraphQL API + MCP Server |
| Agno | 8000 | AgentOS (AI agents, WhatsApp, AG-UI) |
| Frontend | 3000 | Next.js + CopilotKit |
| n8n | 5678 | Automatizaciones deterministas |
| Prefect | 4200 | Orquestacion de workers (scraping, ETL) |
| Traefik | 80/443 | Reverse proxy + SSL |

## Quick Start

```bash
cp .env.example .env
# Edit .env with your credentials
docker compose up -d
```

## Comunicacion entre servicios

- **Agno -> Directus**: MCP Server (auto-discovery de colecciones) + REST tools para logica de negocio
- **n8n -> Directus**: Nodo Directus nativo (CRUD + triggers)
- **Prefect -> Directus**: HTTP REST API
- **Frontend -> Agno**: AG-UI protocol (HTTP/SSE)
- **WhatsApp -> Agno**: Interfaz nativa de AgentOS
