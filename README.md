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
| n8n | 5678 | Automatizaciones deterministas + MCP server para creacion de flujos con IA |
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
- **Agno -> n8n**: MCP Server (crear, listar, ejecutar workflows de n8n con IA)
- **n8n -> Directus**: Nodo Directus nativo (CRUD + triggers)
- **Prefect -> Directus**: HTTP REST API
- **Frontend -> Agno**: AG-UI protocol (HTTP/SSE)
- **WhatsApp -> Agno**: Interfaz nativa de AgentOS

---

## Roadmap

### Fase 1 — Funcional minimo (`docker compose up` end-to-end)

- [ ] Agregar MCP tool de n8n al agente de automatizacion (crear flujos con IA)
- [ ] Crear frontend funcional (Next.js + CopilotKit conectado a Agno via AG-UI)
- [ ] Configurar colecciones iniciales en Directus (contacts, companies, tickets, tasks, conversations, payments)
- [ ] Script de setup inicial (`setup.sh`: crea .env, levanta servicios, verifica health)
- [ ] Abrir puertos en firewall de Hetzner (80/443 para Traefik) via mastra-infra

### Fase 2 — Portar agentes del nexus_legacy.py

- [ ] Portar automation_agent (n8n MCP + Directus MCP)
- [ ] Portar cerebro team (router entre research, knowledge, automation)
- [ ] Portar whatsapp_support_team (whabi, docflow, aurora support agents)
- [ ] Portar content_team (trend_scout, scriptwriter, creative_director, analytics)
- [ ] Portar product_dev_team, creative_studio, marketing_latam teams
- [ ] Portar workflows (client_research, content_production, deep_research, seo_content, social_media, competitor_intel, media_generation)
- [ ] Portar agentes individuales (dash, pal, onboarding, email, scheduler, invoice)
- [ ] Portar structured output models (Pydantic: ResearchReport, LeadReport, ContentBrief, VideoStoryboard, SupportTicket, PaymentConfirmation)
- [ ] Portar ResponseQualityEval y registry

### Fase 3 — Workers de Prefect (ingesta determinista, sin IA)

- [ ] Implementar flow de scraping LATAM completo (Crawl4AI + parseo + Directus)
- [ ] Implementar flow de re-embedding (leer Directus -> generar embeddings -> pgvector)
- [ ] Implementar flow de ETL de documentos (PDF/CSV -> parse -> Directus)
- [ ] Configurar schedules en Prefect (cron: scraping cada 6h, re-embedding diario)

### Fase 4 — Integraciones n8n (deterministas, sin IA, sin tokens)

- [ ] Workflow: Gmail -> Directus (ingesta de emails)
- [ ] Workflow: WhatsApp webhook -> Directus (backup de conversaciones)
- [ ] Workflow: Directus trigger -> notificaciones (Slack/Telegram)

### Fase 5 — Produccion y seguridad

- [ ] Configurar dominio + SSL (Let's Encrypt via Traefik)
- [ ] Configurar Tailscale en el VPS para acceso seguro
- [ ] Backups automaticos de PostgreSQL (pg_dump + Prefect flow)
- [ ] Configurar WhatsApp Business API (Meta credentials, webhook HTTPS)
- [ ] Monitoring basico (Uptime Kuma o healthcheck endpoints)
- [ ] Documentar proceso de actualizacion de cada servicio

### Fase 6 — Optimizacion

- [ ] Ajustar memory limits basado en uso real (`docker stats`)
- [ ] Configurar PgBouncer si las conexiones a PostgreSQL se saturan
- [ ] Implementar sandbox tool con limites de red configurables
