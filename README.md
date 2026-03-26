# NEXUS-AIKALABS — El Cerebro Corporativo

Plataforma empresarial unificada que separa tres responsabilidades: ingesta determinista de datos, gestion del estado, y razonamiento cognitivo.

## Arquitectura

```
Internet (HTTPS via Traefik)
         |
    +---------+
    | Traefik | (solo frontend + WhatsApp webhook)
    +---------+
         |
    +----+----+
    |         |
  Next.js   WhatsApp
  :3000     webhook
    |         |
    +----+----+
         |  (red interna Docker)
    +----+----------+----------+--------+
    |    |          |          |        |
  Agno  Directus   n8n      Prefect  Docling
  :8000  :8055     :5678    :4200   (on-demand)
    |       |         |        |        |
    |  MCP  |  Node   |  REST  |  parse |
    +-------+---------+--------+--------+
         |         |         |
    +----+---------+----+----+----+
    |         |         |        |
  PostgreSQL Redis    RustFS   Uptime
  +pgvector  :6379    :9000    Kuma
  :5432               (S3)    :3001
    |
  DBs: directus, agno, n8n, prefect
```

**Acceso a internet**: Solo frontend (CopilotKit) y WhatsApp webhook.
**Todo lo demas**: Solo via Tailscale (dashboards de Directus, n8n, Prefect, Agno via os.agno.com, Uptime Kuma, RustFS console).

## Servicios

| Servicio | Puerto | Acceso | Funcion |
|----------|--------|--------|---------|
| PostgreSQL | 5432 | Interno | Base de datos (databases: directus, agno, n8n, prefect) |
| Redis | 6379 | Interno | Cache (Directus) + colas |
| RustFS | 9000/9001 | Tailscale | Object storage S3-compatible (documentos, media, backups) |
| Directus | 8055 | Tailscale | CMS + REST/GraphQL API + MCP Server (fuente de verdad) |
| Agno | 8000 | Tailscale + os.agno.com | AgentOS (AI agents, WhatsApp, AG-UI) |
| Frontend | 3000 | Internet | Next.js + CopilotKit (unico servicio publico) |
| n8n | 5678 | Tailscale | Automatizaciones deterministas + MCP para crear flujos con IA |
| Prefect | 4200 | Tailscale | Orquestacion de workers (scraping, ETL con Docling, embeddings) |
| Uptime Kuma | 3001 | Tailscale | Health monitoring de todos los servicios |
| Traefik | 80/443 | Internet | Reverse proxy + SSL (solo frontend + WhatsApp webhook) |

## Quick Start

```bash
cp .env.example .env
# Edit .env with your credentials
docker compose up -d
```

## Comunicacion entre servicios

- **Agno -> Directus**: MCP Server (auto-discovery de colecciones) + REST tools para logica de negocio
- **Agno -> n8n**: MCP Server (crear, listar, ejecutar workflows de n8n con IA)
- **Agno -> Docling**: Tool nativo (parseo de documentos on-demand desde chat/WhatsApp)
- **n8n -> Directus**: Nodo Directus nativo verificado (CRUD + triggers)
- **Prefect -> Directus**: HTTP REST API (ingesta batch)
- **Prefect -> Docling**: Libreria Python (ETL de documentos -> Directus + pgvector)
- **Frontend -> Agno**: AG-UI protocol (HTTP/SSE)
- **WhatsApp -> Agno**: Interfaz nativa de AgentOS (via Traefik HTTPS)
- **Directus -> RustFS**: S3 storage adapter (archivos, media, uploads)
- **Agno -> os.agno.com**: Control plane (tracing, monitoring, chat) via Tailscale

## Dashboards (todos via Tailscale)

| Dashboard | URL | Funcion |
|-----------|-----|---------|
| os.agno.com | Conecta a `http://<tailscale-ip>:8000` | Agentes, tracing, chat, monitoring |
| Directus | `http://<tailscale-ip>:8055` | Datos, colecciones, RBAC, admin |
| n8n | `http://<tailscale-ip>:5678` | Workflows de automatizacion |
| Prefect | `http://<tailscale-ip>:4200` | Workers, flows, schedules |
| Uptime Kuma | `http://<tailscale-ip>:3001` | Health monitoring, alertas |
| RustFS Console | `http://<tailscale-ip>:9001` | Object storage, buckets |
| Traefik | `http://<tailscale-ip>:8080` | Reverse proxy dashboard |

---

## Roadmap

### Fase 1 — Funcional minimo (`docker compose up` end-to-end)

- [x] Estructura base del proyecto (docker-compose, configs, Dockerfiles)
- [x] Agno AgentOS con 3 agentes core (research, knowledge, support)
- [x] Directus con MCP Server + RustFS storage
- [x] Docling tool para Agno + ETL flow para Prefect
- [x] RustFS (S3 storage), Uptime Kuma (monitoring)
- [x] Traefik configurado: solo frontend + WhatsApp webhook expuestos
- [ ] Agregar MCP tool de n8n al agente de automatizacion (crear flujos con IA)
- [ ] Crear frontend funcional (Next.js + CopilotKit conectado a Agno via AG-UI)
- [ ] Configurar colecciones iniciales en Directus (contacts, companies, tickets, tasks, conversations, payments, documents)
- [ ] Script de setup inicial (`setup.sh`: crea .env, crea buckets en RustFS, levanta servicios, verifica health)
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

### Fase 3 — Workers de Prefect (ingesta determinista, sin IA, sin tokens)

- [ ] Completar flow de scraping LATAM (Crawl4AI + parseo + Directus)
- [ ] Implementar flow de re-embedding (leer Directus -> generar embeddings -> pgvector)
- [x] Flow de ETL de documentos con Docling (PDF/DOCX/PPTX -> parse -> Directus + pgvector)
- [ ] Configurar schedules en Prefect (cron: scraping cada 6h, re-embedding diario)
- [ ] Flow de backup PostgreSQL (pg_dump -> RustFS)

### Fase 4 — Integraciones n8n (deterministas, sin IA, sin tokens)

- [ ] Workflow: Gmail -> Directus (ingesta de emails)
- [ ] Workflow: WhatsApp webhook -> Directus (backup de conversaciones)
- [ ] Workflow: Directus trigger -> notificaciones (Slack/Telegram)
- [ ] Workflow: Nuevo archivo en RustFS -> trigger ETL en Prefect

### Fase 5 — Produccion y seguridad

- [ ] Configurar dominio + SSL (Let's Encrypt via Traefik)
- [ ] Configurar Tailscale en el VPS
- [ ] Configurar WhatsApp Business API (Meta credentials, webhook HTTPS)
- [ ] Configurar Uptime Kuma con monitors para todos los servicios
- [ ] Conectar AgentOS a os.agno.com via Tailscale
- [ ] Documentar proceso de actualizacion de cada servicio

### Fase 6 — Optimizacion

- [ ] Ajustar memory limits basado en uso real (`docker stats`)
- [ ] Agregar reranker a pgvector (Cohere API o cross-encoder local)
- [ ] Configurar PgBouncer si las conexiones a PostgreSQL se saturan
- [ ] Configurar limites de red en sandbox tool (permitir acceso controlado a internet)
