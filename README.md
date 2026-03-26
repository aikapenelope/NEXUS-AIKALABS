# NEXUS-AIKALABS — El Cerebro Corporativo

Plataforma empresarial unificada que separa tres responsabilidades: ingesta determinista de datos, gestion del estado, y razonamiento cognitivo.

## Quick Start

```bash
git clone https://github.com/aikapenelope/NEXUS-AIKALABS.git
cd NEXUS-AIKALABS
chmod +x setup.sh && ./setup.sh
```

El script genera secretos aleatorios, construye las imagenes, y levanta los 12 servicios. Despues edita `.env` para agregar tus API keys de LLM.

## Servicios (12)

| Servicio | Puerto | Acceso | Funcion |
|----------|--------|--------|---------|
| PostgreSQL | 5432 | Interno | DB unica con schemas aislados (directus, agno_memory, n8n, prefect) |
| Redis | 6379 | Interno | Cache (Directus) + colas |
| Reranker | 7997 | Interno | Infinity (BAAI/bge-reranker-base, local, sin API key) |
| RustFS | 9000/9001 | Tailscale | Object storage S3-compatible |
| Directus | 8055 | Tailscale | CMS + REST/GraphQL API + MCP Server |
| Agno | 8000 | Tailscale + os.agno.com | AgentOS (AI agents, WhatsApp, AG-UI) |
| Frontend | 3000 | Internet | Next.js + CopilotKit (unico servicio publico) |
| n8n | 5678 | Tailscale | Automatizaciones deterministas |
| Prefect | 4200 | Tailscale | Orquestacion de workers |
| Prefect Worker | - | Interno | Ejecuta flows (scraping, ETL, embeddings) |
| Uptime Kuma | 3001 | Tailscale | Health monitoring |
| Traefik | 80/443 | Internet | Reverse proxy + SSL (solo frontend + WhatsApp webhook) |

## Comunicacion

- **Agno -> Directus**: MCP Server (auto-discovery) + REST tools (logica de negocio)
- **Agno -> Reranker**: Infinity local (hybrid search + reranking)
- **Agno -> Prefect**: Trigger tool (dispara flows on-demand)
- **Agno -> Docling**: Tool nativo (parseo de documentos on-demand)
- **Agno -> Sandbox**: Docker-in-Docker (microcomputador persistente para IA)
- **n8n -> Directus**: Nodo nativo verificado (CRUD + triggers)
- **Prefect -> Directus**: HTTP REST API (ingesta batch)
- **Prefect -> Docling**: ETL de documentos (batch)
- **Frontend -> Agno**: AG-UI protocol (CopilotKit)
- **WhatsApp -> Agno**: Interfaz nativa de AgentOS (via Traefik HTTPS)
- **Directus -> RustFS**: S3 storage adapter

---

## Roadmap

### Fase 1 — Funcional minimo

- [x] Estructura base (docker-compose, configs, Dockerfiles)
- [x] 12 servicios con healthchecks, memory limits, restart policies
- [x] Schema isolation (agno_memory, n8n, prefect, app, public)
- [x] Agno con 3 agentes core + knowledge isolation por proyecto
- [x] Reranker local (Infinity) + hybrid search + chunking corto
- [x] RustFS, Uptime Kuma, Docling, sandbox DinD
- [x] n8n memory leak prevention + Directus rate limiting
- [x] Frontend (nexus-ui con CopilotKit + AG-UI)
- [x] setup.sh para primer deploy
- [ ] Primer deploy en VPS y correccion de errores
- [ ] Crear colecciones en Directus (contacts, companies, tickets, tasks, conversations, payments, documents)
- [ ] Abrir puertos 80/443 en firewall Hetzner

### Fase 2 — Portar agentes del nexus_legacy.py

- [ ] automation_agent (n8n MCP + Directus MCP)
- [ ] cerebro team (router)
- [ ] whatsapp_support_team (whabi, docflow, aurora)
- [ ] content_team (trend_scout, scriptwriter, creative_director, analytics)
- [ ] product_dev_team, creative_studio, marketing_latam
- [ ] workflows (7)
- [ ] agentes individuales (dash, pal, onboarding, email, scheduler, invoice)
- [ ] structured output models + ResponseQualityEval + registry

### Fase 3 — Workers de Prefect

- [x] Flow de ETL de documentos con Docling
- [x] Flow de scraping LATAM (estructura)
- [ ] Completar scraping con URLs reales
- [ ] Flow de re-embedding periodico
- [ ] Flow de backup PostgreSQL -> RustFS
- [ ] Configurar schedules (cron)

### Fase 4 — Integraciones n8n

- [ ] Gmail -> Directus
- [ ] WhatsApp backup -> Directus
- [ ] Directus trigger -> notificaciones
- [ ] Nuevo archivo en RustFS -> trigger ETL

### Fase 5 — Produccion

- [ ] Dominio + SSL (Let's Encrypt via Traefik)
- [ ] Tailscale en VPS
- [ ] WhatsApp Business API
- [ ] Uptime Kuma monitors
- [ ] Conectar os.agno.com

### Fase 6 — Optimizacion

- [ ] Ajustar memory limits (`docker stats`)
- [ ] Reranker: evaluar modelo mas grande si hay RAM
- [ ] PgBouncer si conexiones se saturan
