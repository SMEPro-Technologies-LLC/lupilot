# IOS+ Wave 1 MVP — On-Prem Edu Reporter

**Quick Start:** Run the entire stack locally with Docker Compose.

## Prerequisites

- Docker Desktop or Docker Engine + Compose
- 4 GB RAM available
- Port 80, 3000, 5432, 6379, 8080 free (or edit docker-compose.yml)

## Start the Stack

```bash
# Clone and enter repository
git clone https://github.com/SMEPro-Technologies-LLC/lupilot.git
cd lupilot

# Start all services
docker-compose up --build

# Or run in background
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop
docker-compose down
# Stop and remove volumes (deletes database data)
docker-compose down -v
```

## Access Points

| Service | URL | Notes |
|---------|-----|-------|
| **Edu Reporter Frontend** | http://localhost | Main dashboard (UC-01 to UC-05) |
| **API Gateway** | http://localhost:3000 | Routes, auth, health |
| **Edu Reporter API** | http://localhost:8080 | Direct API access |
| **PostgreSQL** | localhost:5432 | DB: ios_plus, user: ios_admin |
| **Redis** | localhost:6379 | Session cache |

## API Endpoints

```bash
# Health
curl http://localhost:3000/v1/health/live
curl http://localhost:3000/v1/health/ready

# UC-01: Predictive Persistence
curl http://localhost:3000/v1/uc/uc-01

# UC-02: Transcript Crosswalk
curl http://localhost:3000/v1/uc/uc-02

# UC-03: Accreditation Gap Analysis
curl http://localhost:3000/v1/uc/uc-03

# UC-04: Outcome Alignment Auditor
curl http://localhost:3000/v1/uc/uc-04

# UC-05: Grading Load Analyzer
curl http://localhost:3000/v1/uc/uc-05
```

## Architecture (MVP)

```
┌─────────────────────────────────────────────────────────────┐
│                    User (Browser)                           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Frontend (nginx:80) — React-style SPA, calls /api/*         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  API Gateway (Node.js:3000) — routing, auth, rate limit  │
│  Health: /v1/health/*                                      │
│  Proxy: /v1/edu-reporter/* → Edu Reporter API              │
│  Direct: /v1/uc/uc-01 … uc-05                              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Edu Reporter API (Python/FastAPI:8080)                   │
│  UC-01: Student risk scores (Green/Yellow/Red tiers)       │
│  UC-02: Transcript equivalency queue + confidence         │
│  UC-03: SACSCOC accreditation gap heat map                │
│  UC-04: CLO ↔ syllabus ↔ gradebook alignment flags       │
│  UC-05: Grading Load Index (GLI) computation              │
└─────────────────────────────────────────────────────────────┘
                     │
    ┌────────────────┼────────────────┐
    ▼                ▼                ▼
PostgreSQL      Redis           (Future: Kafka,
(16-alpine)    (7-alpine)       Pub/Sub, Vault)
```

## Data

- **Synthetic:** All data is generated on first startup by the mock-data-generator service
- **500 students, 200 courses, 150 transcripts** — seeded into PostgreSQL
- **Deterministic:** Same random seed every run for consistent demos
- **Realistic:** Data patterns match the Edu Reporter use case documents

## Environment Variables

Copy `.env.template` and customize:

```bash
cp environments/.env.template .env
# Edit .env with your values
```

## Development

### Modify the API
```bash
cd services/edu-reporter-api
# Edit main.py
docker-compose up -d --build edu-reporter-api
```

### Modify the Frontend
```bash
cd frontend/edu-reporter
# Edit index.html
docker-compose up -d --build frontend
```

### View Database
```bash
docker exec -it ios-plus-postgres psql -U ios_admin -d ios_plus
\dt
SELECT * FROM synthetic_students LIMIT 10;
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Port already in use | Edit `docker-compose.yml` ports or stop conflicting service |
| Database not ready | Mock data generator waits for postgres healthcheck; check `docker-compose logs postgres` |
| API returns 502 | Check `docker-compose logs edu-reporter-api` |
| Frontend blank | Check browser console; ensure API Gateway is reachable |

## Next Steps

1. **Wave 2:** Add real Banner/Blackboard connectors (replace synthetic data)
2. **Wave 3:** Add ML models for UC-01 risk scoring, UC-06 AI grading
3. **Production:** Deploy to GKE or on-prem K8s using Helm charts

See `docs/PRODUCTION_READINESS_AND_TRANSFER_PLAN.md` for the full roadmap.
