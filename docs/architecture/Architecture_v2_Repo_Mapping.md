# SMEPro COS Architecture v2 — Repository & Service Mapping
## Code Organization, Docker Images, and Deployment Units
## Version: 2026.06.20-LAMAR-ARCH-v2.0
## Date: 2026-06-20

---

## 1. Repository Structure

```
smepro-cos/
├── README.md                          # Project overview, quickstart, architecture links
├── ARCHITECTURE.md                    # Link to v2 narrative, spec, diagram, repo mapping
├── LICENSE                            # Proprietary — SMEPro, LLC
├── .gitignore
├── docker-compose.yml                 # Local development stack
├── docker-compose.prod.yml            # Production stack (K8s equivalent)
├── Makefile                           # Common commands: build, test, deploy, migrate
│
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                     # Lint, test, build on PR
│   │   ├── cd-staging.yml             # Deploy to staging on merge to develop
│   │   ├── cd-production.yml          # Deploy to production on merge to main
│   │   └── security-scan.yml          # Snyk, Trivy, dependency audit
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── CODEOWNERS                     # Module ownership: @db-team, @backend-team, etc.
│
├── docs/                              # All architecture and design docs
│   ├── architecture/
│   │   ├── v2-narrative.md            # Buyer-legible architecture story
│   │   ├── v2-deployment-spec.md      # Formal engineering specification
│   │   ├── v2-diagram-layout.md       # Text boxes for designer
│   │   └── v2-repo-mapping.md         # This file
│   ├── api/
│   │   ├── openapi-compliance.yaml    # Module 1 API spec
│   │   ├── openapi-module2.yaml       # Module 2 API spec
│   │   └── openapi-module3.yaml       # Module 3 API spec
│   ├── runbooks/
│   │   ├── incident-response.md
│   │   ├── disaster-recovery.md
│   │   └── database-operations.md
│   └── adr/                           # Architecture Decision Records
│       ├── 001-connector-taxonomy.md
│       ├── 002-on-prem-trust-boundary.md
│       ├── 003-ai-orchestration-pattern.md
│       ├── 004-trace-chain-selection.md
│       └── 005-bias-audit-methodology.md
│
├── infra/                             # Infrastructure as Code
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── modules/
│   │   │   ├── vpc/                   # Lamar VPC or on-prem network
│   │   │   ├── eks/                   # Kubernetes cluster (or K3s for on-prem)
│   │   │   ├── rds/                   # PostgreSQL primary + replicas
│   │   │   ├── elasticsearch/         # UDM search cluster
│   │   │   ├── redis/                 # Session cache
│   │   │   ├── kafka/                 # Event bus
│   │   │   ├── s3/                    # Artifact storage
│   │   │   └── waf/                   # Cloudflare / AWS WAF
│   │   └── environments/
│   │       ├── dev/
│   │       ├── staging/
│   │       └── production/
│   ├── kubernetes/
│   │   ├── namespaces/
│   │   │   ├── connector-ingestion.yaml
│   │   │   ├── normalization-pipeline.yaml
│   │   │   ├── rules-workflow.yaml
│   │   │   ├── ml-jobs.yaml
│   │   │   ├── trust-model.yaml
│   │   │   ├── api-gateway.yaml
│   │   │   └── frontend-apps.yaml
│   │   ├── configmaps/
│   │   │   ├── app-config.yaml
│   │   │   ├── database-config.yaml
│   │   │   └── kafka-config.yaml
│   │   ├── secrets/
│   │   │   ├── database-credentials.yaml
│   │   │   ├── api-keys.yaml
│   │   │   └── jwt-signing-key.yaml
│   │   ├── ingress/
│   │   │   ├── api-ingress.yaml
│   │   │   └── frontend-ingress.yaml
│   │   └── monitoring/
│   │       ├── prometheus-config.yaml
│   │       ├── grafana-dashboards.yaml
│   │       └── alertmanager-config.yaml
│   └── ansible/                         # On-prem server provisioning (if bare metal)
│       ├── playbook.yml
│       └── roles/
│           ├── postgres/
│           ├── docker/
│           └── kubernetes/
│
├── db/
│   ├── migrations/                      # Flyway migrations
│   │   ├── V11__mini_udm_lamar_operationalization.sql
│   │   ├── V12__module1_regulatory_reporting.sql
│   │   ├── V13__module2_objectives_student_facing.sql
│   │   ├── V14__module3_ai_governance.sql
│   │   └── V15__baseline_seed_data.sql  # Seed data for all systems
│   ├── seeds/
│   │   ├── cip_soc_state_license.csv
│   │   ├── compact_participation.csv
│   │   ├── accreditation_standards/     # SACSCOC, AACSB, ABET, ACEN, CCNE PDFs + NLP index
│   │   ├── equivalency_rules/             # SJC, LIT, Houston CC canonical rules
│   │   └── udm_index/                     # 399 UCO_NODE_IDs JSON
│   ├── tests/
│   │   ├── e2e_lookup_test.sql
│   │   ├── cross_mart_validation_test.sql
│   │   └── data_quality_test.sql
│   └── schema-docs/
│       ├── er-diagram.md
│       ├── table-descriptions.md
│       └── index-analysis.md
│
├── backend/
│   ├── api-gateway/                     # Node.js / Fastify
│   │   ├── src/
│   │   │   ├── index.ts
│   │   │   ├── routes/
│   │   │   │   ├── compliance.ts        # /v1/compliance/* (Module 1)
│   │   │   │   ├── module2.ts           # /v1/module2/* (Module 2)
│   │   │   │   ├── module3.ts           # /v1/module3/* (Module 3)
│   │   │   │   └── health.ts            # /v1/health/*
│   │   │   ├── middleware/
│   │   │   │   ├── auth.ts              # JWT validation, RBAC
│   │   │   │   ├── rate-limit.ts
│   │   │   │   ├── logging.ts
│   │   │   │   └── error-handler.ts
│   │   │   ├── services/
│   │   │   │   ├── route-resolver.ts    # Routes to internal services
│   │   │   │   └── context-builder.ts   # Builds bounded context for AI queries
│   │   │   └── types/
│   │   │       └── api-types.ts
│   │   ├── tests/
│   │   │   ├── integration/
│   │   │   └── unit/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   ├── services/
│   │   ├── canonical-layer/             # Go / Rust (high throughput)
│   │   │   ├── src/
│   │   │   │   ├── main.go
│   │   │   │   ├── handlers/
│   │   │   │   │   ├── student.go
│   │   │   │   │   ├── course.go
│   │   │   │   │   ├── instructor.go
│   │   │   │   │   └── ... (17 canonical definitions)
│   │   │   │   ├── db/
│   │   │   │   │   ├── connection.go
│   │   │   │   │   └── queries.go
│   │   │   │   └── models/
│   │   │   │       └── canonical.go
│   │   │   ├── Dockerfile
│   │   │   └── go.mod
│   │   │
│   │   ├── udm-query/                   # Go / Rust
│   │   │   ├── src/
│   │   │   │   ├── main.go
│   │   │   │   ├── handlers/
│   │   │   │   │   ├── query.go         # UCO_NODE_ID resolution
│   │   │   │   │   ├── chain.go         # Compliance chain traversal
│   │   │   │   │   └── search.go        # Full-text search
│   │   │   │   ├── db/
│   │   │   │   │   ├── connection.go
│   │   │   │   │   └── elasticsearch.go
│   │   │   │   └── models/
│   │   │   │       └── udm.go
│   │   │   ├── Dockerfile
│   │   │   └── go.mod
│   │   │
│   │   ├── evidence-chain/              # Go / Rust
│   │   │   ├── src/
│   │   │   │   ├── main.go
│   │   │   │   ├── handlers/
│   │   │   │   │   ├── log.go
│   │   │   │   │   ├── deploy.go        # Trace chain deployment
│   │   │   │   │   └── retrieve.go
│   │   │   │   ├── blockchain/
│   │   │   │   │   ├── ethereum.go
│   │   │   │   │   └── contract.go      # SMEProEvidenceChain smart contract
│   │   │   │   └── models/
│   │   │   │       └── evidence.go
│   │   │   ├── Dockerfile
│   │   │   └── go.mod
│   │   │
│   │   ├── rules-engine/                # Java (Drools)
│   │   │   ├── src/
│   │   │   │   ├── main/java/
│   │   │   │   │   ├── com/smepro/rules/
│   │   │   │   │   │   ├── RulesEngineApplication.java
│   │   │   │   │   │   ├── controllers/
│   │   │   │   │   │   ├── services/
│   │   │   │   │   │   └── rules/
│   │   │   │   │   │       ├── bias-audit-rules.drl
│   │   │   │   │   │       ├── risk-scoring-rules.drl
│   │   │   │   │   │       └── compliance-rules.drl
│   │   │   │   └── test/
│   │   │   ├── Dockerfile
│   │   │   └── pom.xml
│   │   │
│   │   ├── workflow-orchestrator/         # Java (Camunda / Temporal)
│   │   │   ├── src/
│   │   │   │   ├── main/java/
│   │   │   │   │   ├── com/smepro/workflow/
│   │   │   │   │   │   ├── WorkflowApplication.java
│   │   │   │   │   │   ├── controllers/
│   │   │   │   │   │   ├── services/
│   │   │   │   │   │   └── bpmn/
│   │   │   │   │   │       ├── regulatory-change-approval.bpmn
│   │   │   │   │   │       ├── ai-grader-tier-approval.bpmn
│   │   │   │   │   │       ├── bias-audit-remediation.bpmn
│   │   │   │   │   │       └── transcript-auto-approve.bpmn
│   │   │   │   └── test/
│   │   │   ├── Dockerfile
│   │   │   └── pom.xml
│   │   │
│   │   ├── notification-service/          # Node.js / TypeScript
│   │   │   ├── src/
│   │   │   │   ├── index.ts
│   │   │   │   ├── channels/
│   │   │   │   │   ├── email.ts           # SendGrid
│   │   │   │   │   ├── slack.ts
│   │   │   │   │   └── sms.ts             # Twilio
│   │   │   │   ├── templates/
│   │   │   │   │   ├── red-tier-digest.html
│   │   │   │   │   ├── compliance-alert.html
│   │   │   │   │   └── bias-audit-fail.html
│   │   │   │   └── queue/
│   │   │   │       └── kafka-consumer.ts
│   │   │   ├── Dockerfile
│   │   │   └── package.json
│   │   │
│   │   └── approval-queue/                # Node.js / TypeScript
│   │       ├── src/
│   │       │   ├── index.ts
│   │       │   ├── handlers/
│   │       │   │   ├── create.ts
│   │       │   │   ├── review.ts
│   │       │   │   └── approve.ts
│   │       │   ├── models/
│   │       │   │   └── approval.ts
│   │       │   └── db/
│   │       │       └── connection.ts
│   │       ├── Dockerfile
│   │       └── package.json
│   │
│   └── connectors/                        # Python (data engineering)
│       ├── workers/
│       │   ├── banner/
│       │   │   ├── __init__.py
│       │   │   ├── extract.py
│       │   │   ├── transform.py
│       │   │   └── load.py
│       │   ├── blackboard/
│       │   │   ├── __init__.py
│       │   │   ├── extract.py
│       │   │   ├── transform.py
│       │   │   └── load.py
│       │   ├── concourse/
│       │   ├── touchnet/
│       │   ├── starrez/
│       │   ├── peoplesoft/
│       │   ├── cayuse/
│       │   ├── omnigo/
│       │   ├── teammate/
│       │   ├── citi/
│       │   ├── nsc/
│       │   ├── sevis/
│       │   └── regulatory/
│       │       ├── __init__.py
│       │       ├── scraper.py             # Firecrawl integration
│       │       ├── change-detector.py
│       │       ├── nlp-extractor.py         # Claude MCP integration
│       │       └── udm-mapper.py
│       ├── cdc/
│       │   ├── debezium-config.yml
│       │   └── kafka-connect-config.yml
│       ├── scheduler/
│       │   ├── airflow-dags/
│       │   │   ├── banner-daily.py
│       │   │   ├── blackboard-daily.py
│       │   │   ├── regulatory-hourly.py
│       │   │   └── ml-jobs-weekly.py
│       │   └── Dockerfile
│       └── Dockerfile
│
├── ml/
│   ├── jobs/
│   │   ├── persistence/                   # UC-01
│   │   │   ├── train.py
│   │   │   ├── predict.py
│   │   │   ├── explain.py                 # SHAP
│   │   │   └── requirements.txt
│   │   ├── transcript-nlp/                # UC-02
│   │   │   ├── train-bert.py
│   │   │   ├── predict.py
│   │   │   └── requirements.txt
│   │   ├── accreditation-nlp/             # UC-03
│   │   │   ├── train-bert.py
│   │   │   ├── match-evidence.py
│   │   │   └── requirements.txt
│   │   ├── alignment/                     # UC-04
│   │   │   ├── scan.py
│   │   │   └── requirements.txt
│   │   ├── grading-load/                  # UC-05
│   │   │   ├── calculate-gli.py
│   │   │   └── requirements.txt
│   │   ├── ai-grader/                     # UC-06
│   │   │   ├── complexity-score.py
│   │   │   └── requirements.txt
│   │   ├── enrollment-funnel/             # UC-07
│   │   │   ├── analyze.py
│   │   │   └── requirements.txt
│   │   └── compliance-monitor/            # UC-08
│   │       ├── detect-change.py
│   │       ├── assess-impact.py
│   │       └── requirements.txt
│   │
│   ├── shared/
│   │   ├── explainability/
│   │   │   ├── shap-engine.py
│   │   │   ├── lime-engine.py
│   │   │   └── requirements.txt
│   │   ├── bias-audit/
│   │   │   ├── aequitas-runner.py
│   │   │   ├── fairlearn-runner.py
│   │   │   └── requirements.txt
│   │   ├── drift-detection/
│   │   │   ├── monitor.py
│   │   │   └── requirements.txt
│   │   └── model-registry/
│   │       ├── mlflow-tracking.py
│   │       └── requirements.txt
│   │
│   └── models/                            # Trained model artifacts (versioned)
│       ├── persistence/
│       │   ├── v1.0.0/
│       │   ├── v2.0.0/
│       │   └── v2.1.0/                    # Current production
│       ├── transcript-nlp/
│       │   └── v1.3.0/
│       ├── accreditation-nlp/
│       │   └── v1.0.0/
│       └── README.md                        # Model cards for all deployed models
│
├── frontend/
│   ├── shared/                              # Design system, components, utilities
│   │   ├── components/
│   │   │   ├── Button/
│   │   │   ├── Table/
│   │   │   ├── Chart/
│   │   │   ├── Modal/
│   │   │   └── Form/
│   │   ├── hooks/
│   │   │   ├── useAuth.ts
│   │   │   ├── useApi.ts
│   │   │   └── useRoleLens.ts
│   │   ├── utils/
│   │   │   ├── formatters.ts
│   │   │   └── validators.ts
│   │   └── types/
│   │       └── api.ts
│   │
│   ├── apps/
│   │   ├── advisor-dashboard/               # UC-01
│   │   │   ├── src/
│   │   │   │   ├── pages/
│   │   │   │   │   ├── index.tsx            # Red-tier digest
│   │   │   │   │   ├── student/[id].tsx     # Student detail
│   │   │   │   │   └── intervention/
│   │   │   │   ├── components/
│   │   │   │   │   ├── RiskTierBadge.tsx
│   │   │   │   │   ├── TopFactorsCard.tsx
│   │   │   │   │   └── InterventionLog.tsx
│   │   │   │   └── lib/
│   │   │   │       └── api.ts
│   │   │   ├── next.config.js
│   │   │   ├── package.json
│   │   │   └── Dockerfile
│   │   │
│   │   ├── registrar-portal/              # UC-02
│   │   │   ├── src/
│   │   │   │   ├── pages/
│   │   │   │   │   ├── index.tsx            # Transcript queue
│   │   │   │   │   ├── queue/[id].tsx       # Evaluation detail
│   │   │   │   │   └── rules/
│   │   │   │   ├── components/
│   │   │   │   │   ├── ConfidenceScore.tsx
│   │   │   │   │   └── EquivalencyRule.tsx
│   │   │   │   └── lib/
│   │   │   │       └── api.ts
│   │   │   ├── next.config.js
│   │   │   ├── package.json
│   │   │   └── Dockerfile
│   │   │
│   │   ├── accreditation-dashboard/         # UC-03
│   │   │   ├── src/
│   │   │   │   ├── pages/
│   │   │   │   │   ├── index.tsx            # Heat map
│   │   │   │   │   └── standard/[id].tsx    # Standard detail
│   │   │   │   ├── components/
│   │   │   │   │   ├── HeatMap.tsx
│   │   │   │   │   └── EvidenceCard.tsx
│   │   │   │   └── lib/
│   │   │   │       └── api.ts
│   │   │   ├── next.config.js
│   │   │   ├── package.json
│   │   │   └── Dockerfile
│   │   │
│   │   ├── chair-dashboard/                 # UC-04, UC-05, UC-06
│   │   │   ├── src/
│   │   │   │   ├── pages/
│   │   │   │   │   ├── index.tsx            # Overview
│   │   │   │   │   ├── alignment.tsx        # UC-04
│   │   │   │   │   ├── grading-load.tsx     # UC-05
│   │   │   │   │   └── ai-grader.tsx        # UC-06
│   │   │   │   ├── components/
│   │   │   │   │   ├── AlignmentFlags.tsx
│   │   │   │   │   ├── GLIDashboard.tsx
│   │   │   │   │   └── CrunchWeekHeatMap.tsx
│   │   │   │   └── lib/
│   │   │   │       └── api.ts
│   │   │   ├── next.config.js
│   │   │   ├── package.json
│   │   │   └── Dockerfile
│   │   │
│   │   ├── dean-dashboard/                  # UC-05 aggregate, UC-07
│   │   │   ├── src/
│   │   │   │   ├── pages/
│   │   │   │   │   ├── index.tsx            # Executive overview
│   │   │   │   │   ├── enrollment.tsx       # UC-07
│   │   │   │   │   └── faculty.tsx          # UC-05 aggregate
│   │   │   │   └── lib/
│   │   │   │       └── api.ts
│   │   │   ├── next.config.js
│   │   │   ├── package.json
│   │   │   └── Dockerfile
│   │   │
│   │   ├── compliance-dashboard/            # UC-08, Module 3
│   │   │   ├── src/
│   │   │   │   ├── pages/
│   │   │   │   │   ├── index.tsx            # Alert queue
│   │   │   │   │   ├── alerts/[id].tsx      # Alert detail
│   │   │   │   │   ├── sources.tsx          # Monitored sources
│   │   │   │   │   └── governance.tsx       # Module 3 dashboard
│   │   │   │   ├── components/
│   │   │   │   │   ├── AlertCard.tsx
│   │   │   │   │   ├── SourceStatus.tsx
│   │   │   │   │   └── GovernanceSummary.tsx
│   │   │   │   └── lib/
│   │   │   │       └── api.ts
│   │   │   ├── next.config.js
│   │   │   ├── package.json
│   │   │   └── Dockerfile
│   │   │
│   │   └── edu-reporter/                    # Module 1 unified reporting
│   │       ├── src/
│   │       │   ├── pages/
│   │       │   │   ├── index.tsx            # Portal home
│   │       │   │   ├── marts/
│   │       │   │   │   ├── [martId].tsx     # Individual mart view
│   │       │   │   │   └── index.tsx
│   │       │   │   ├── reports/
│   │       │   │   │   └── [reportId].tsx   # Generated report
│   │       │   │   └── cross-mart/
│   │       │   │       └── validation.tsx
│   │       │   ├── components/
│   │       │   │   ├── MartSelector.tsx
│   │       │   │   ├── ReportBuilder.tsx
│   │       │   │   └── ValidationStatus.tsx
│   │       │   └── lib/
│   │       │       └── api.ts
│   │       ├── next.config.js
│   │       ├── package.json
│   │       └── Dockerfile
│   │
│   └── package.json                         # Workspace root (Turborepo / Nx)
│
├── tests/
│   ├── e2e/
│   │   ├── cypress/
│   │   │   ├── integration/
│   │   │   │   ├── advisor-dashboard.cy.ts
│   │   │   │   ├── registrar-portal.cy.ts
│   │   │   │   └── compliance-dashboard.cy.ts
│   │   │   └── fixtures/
│   │   │       └── users.json
│   │   └── playwright/
│   │       ├── advisor-dashboard.spec.ts
│   │       └── compliance-dashboard.spec.ts
│   │
│   ├── load/
│   │   ├── k6/
│   │   │   ├── api-load.js
│   │   │   └── dashboard-load.js
│   │   └── artillery/
│   │       └── load-test.yml
│   │
│   └── security/
│       ├── zap/
│       │   └── zap-scan.sh
│       └── burp/
│           └── burp-scan.sh
│
└── monitoring/
    ├── prometheus/
    │   ├── prometheus.yml
    │   └── rules/
    │       ├── api-alerts.yml
    │       ├── ml-alerts.yml
    │       └── database-alerts.yml
    ├── grafana/
    │   ├── dashboards/
    │   │   ├── api-performance.json
    │   │   ├── ml-metrics.json
    │   │   ├── data-quality.json
    │   │   ├── compliance-status.json
    │   │   └── ai-governance.json
    │   └── datasources.yml
    └── loki/
        └── loki-config.yml
```

---

## 2. Service-to-Docker Image Mapping

| Service Name | Docker Image | Language | Port | Replicas | CPU | Memory | GPU |
|-------------|--------------|----------|------|----------|-----|--------|-----|
| `api-gateway` | `smepro/api-gateway:latest` | TypeScript/Node.js | 8080 | 3 | 2 | 4GB | No |
| `canonical-layer` | `smepro/canonical-layer:latest` | Go | 8081 | 2 | 4 | 8GB | No |
| `udm-query` | `smepro/udm-query:latest` | Go | 8082 | 2 | 2 | 4GB | No |
| `evidence-chain` | `smepro/evidence-chain:latest` | Go | 8083 | 2 | 2 | 4GB | No |
| `rules-engine` | `smepro/rules-engine:latest` | Java | 8084 | 2 | 2 | 4GB | No |
| `workflow-orchestrator` | `smepro/workflow-orchestrator:latest` | Java | 8085 | 2 | 2 | 4GB | No |
| `notification-service` | `smepro/notification-service:latest` | TypeScript/Node.js | 8086 | 2 | 1 | 2GB | No |
| `approval-queue` | `smepro/approval-queue:latest` | TypeScript/Node.js | 8087 | 2 | 1 | 2GB | No |
| `connector-worker-banner` | `smepro/connector-worker:latest` | Python | — | 2 | 2 | 4GB | No |
| `connector-worker-blackboard` | `smepro/connector-worker:latest` | Python | — | 2 | 2 | 4GB | No |
| `connector-worker-regulatory` | `smepro/connector-worker:latest` | Python | — | 3 | 2 | 4GB | No |
| `connector-worker-ai-orchestration` | `smepro/connector-ai-orchestration:latest` | Python | — | 2 | 4 | 8GB | Optional |
| `ml-job-persistence` | `smepro/ml-persistence:latest` | Python | — | 1 | 4 | 16GB | No |
| `ml-job-transcript-nlp` | `smepro/ml-transcript-nlp:latest` | Python | — | 1 | 8 | 32GB | **Yes** |
| `ml-job-accreditation-nlp` | `smepro/ml-accreditation-nlp:latest` | Python | — | 1 | 8 | 32GB | **Yes** |
| `ml-job-alignment` | `smepro/ml-alignment:latest` | Python | — | 1 | 2 | 4GB | No |
| `ml-job-grading-load` | `smepro/ml-grading-load:latest` | Python | — | 1 | 2 | 4GB | No |
| `ml-job-ai-grader` | `smepro/ml-ai-grader:latest` | Python | — | 1 | 2 | 4GB | Optional |
| `ml-job-enrollment-funnel` | `smepro/ml-enrollment-funnel:latest` | Python | — | 1 | 2 | 4GB | No |
| `ml-job-compliance-monitor` | `smepro/ml-compliance-monitor:latest` | Python | — | 2 | 2 | 4GB | No |
| `ml-job-explainability` | `smepro/ml-explainability:latest` | Python | — | 2 | 4 | 8GB | Optional |
| `ml-job-bias-audit` | `smepro/ml-bias-audit:latest` | Python | — | 1 | 4 | 8GB | No |
| `frontend-advisor` | `smepro/frontend-advisor:latest` | TypeScript/Next.js | 3000 | 2 | 1 | 2GB | No |
| `frontend-registrar` | `smepro/frontend-registrar:latest` | TypeScript/Next.js | 3001 | 2 | 1 | 2GB | No |
| `frontend-accreditation` | `smepro/frontend-accreditation:latest` | TypeScript/Next.js | 3002 | 2 | 1 | 2GB | No |
| `frontend-chair` | `smepro/frontend-chair:latest` | TypeScript/Next.js | 3003 | 2 | 1 | 2GB | No |
| `frontend-dean` | `smepro/frontend-dean:latest` | TypeScript/Next.js | 3004 | 2 | 1 | 2GB | No |
| `frontend-compliance` | `smepro/frontend-compliance:latest` | TypeScript/Next.js | 3005 | 2 | 1 | 2GB | No |
| `frontend-edu-reporter` | `smepro/frontend-edu-reporter:latest` | TypeScript/Next.js | 3006 | 2 | 1 | 2GB | No |
| `postgres-primary` | `postgres:16` | C | 5432 | 2 | 8 | 32GB | No |
| `postgres-replica` | `postgres:16` | C | 5432 | 2 | 8 | 32GB | No |
| `elasticsearch` | `elasticsearch:8` | Java | 9200 | 3 | 4 | 16GB | No |
| `redis` | `redis:7` | C | 6379 | 2 | 2 | 8GB | No |
| `kafka` | `kafka:3` | Java | 9092 | 3 | 4 | 8GB | No |
| `prometheus` | `prom/prometheus:latest` | Go | 9090 | 1 | 2 | 4GB | No |
| `grafana` | `grafana/grafana:latest` | TypeScript/Go | 3000 | 1 | 1 | 2GB | No |
| `loki` | `grafana/loki:latest` | Go | 3100 | 1 | 1 | 2GB | No |

---

## 3. Kubernetes Namespace Mapping

| Namespace | Services | Purpose | Network Policy |
|-----------|----------|---------|--------------|
| `connector-ingestion` | All connector workers, CDC, Airflow | Data ingestion from external sources | Egress to campus systems + public internet; no ingress from outside |
| `normalization-pipeline` | dbt, Spark, Great Expectations | Data quality and canonicalization | Internal only; no external access |
| `rules-workflow` | Drools, Camunda, Temporal, notification | Business rules and approval workflows | Internal only; egress to notification channels (email, Slack) |
| `ml-jobs` | All ML inference and training jobs | Model scoring, NLP, explainability | Internal only; GPU nodes scheduled here |
| `trust-model` | PostgreSQL, Elasticsearch, Redis, evidence-chain | Core data storage and UDM | Internal only; API gateway access only |
| `api-gateway` | API gateway, auth service | External API surface | Ingress from DMZ; egress to all internal namespaces |
| `frontend-apps` | All Next.js applications | User-facing web apps | Ingress from DMZ; egress to API gateway only |
| `monitoring` | Prometheus, Grafana, Loki, Alertmanager | Observability | Internal only; read-only access |

---

## 4. Environment Configuration

### 4.1 Development

```yaml
# docker-compose.dev.yml
version: '3.8'
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: smepro_dev
      POSTGRES_USER: smepro
      POSTGRES_PASSWORD: dev_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_dev_data:/var/lib/postgresql/data
      - ../db/migrations:/docker-entrypoint-initdb.d

  redis:
    image: redis:7
    ports:
      - "6379:6379"

  elasticsearch:
    image: elasticsearch:8
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - "9200:9200"

  api-gateway:
    build: ./backend/api-gateway
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://smepro:dev_password@postgres:5432/smepro_dev
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=dev_secret
    depends_on:
      - postgres
      - redis

  frontend-advisor:
    build: ./frontend/apps/advisor-dashboard
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8080
```

### 4.2 Staging

```yaml
# kubernetes/overlays/staging/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: smepro-staging
resources:
  - ../../base
patches:
  - target:
      kind: Deployment
      name: api-gateway
    patch: |
      - op: replace
        path: /spec/replicas
        value: 2
  - target:
      kind: Deployment
      name: ml-job-transcript-nlp
    patch: |
      - op: replace
        path: /spec/template/spec/containers/0/resources/limits/nvidia.com~1gpu
        value: 1
```

### 4.3 Production

```yaml
# kubernetes/overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: smepro-production
resources:
  - ../../base
patches:
  - target:
      kind: Deployment
      name: api-gateway
    patch: |
      - op: replace
        path: /spec/replicas
        value: 3
  - target:
      kind: Deployment
      name: postgres-primary
    patch: |
      - op: replace
        path: /spec/replicas
        value: 2
  - target:
      kind: Deployment
      name: ml-job-transcript-nlp
    patch: |
      - op: replace
        path: /spec/template/spec/containers/0/resources/limits/nvidia.com~1gpu
        value: 2
```

---

## 5. CI/CD Pipeline

### 5.1 Pull Request Workflow

```yaml
# .github/workflows/ci.yml
name: CI
on:
  pull_request:
    branches: [develop, main]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Lint
        run: make lint
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Unit Tests
        run: make test-unit
      - name: Integration Tests
        run: make test-integration
  build:
    runs-on: ubuntu-latest
    needs: [lint, test]
    steps:
      - uses: actions/checkout@v4
      - name: Build Docker Images
        run: make build
      - name: Push to Registry
        run: make push-staging
  security:
    runs-on: ubuntu-latest
    needs: [build]
    steps:
      - uses: actions/checkout@v4
      - name: Snyk Scan
        run: make scan-snyk
      - name: Trivy Scan
        run: make scan-trivy
```

### 5.2 Deployment Workflow

```yaml
# .github/workflows/cd-staging.yml
name: Deploy to Staging
on:
  push:
    branches: [develop]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Staging
        run: |
          kubectl apply -k k8s/overlays/staging
          kubectl rollout status deployment/api-gateway -n smepro-staging
          kubectl rollout status deployment/postgres-primary -n smepro-staging
      - name: Run Smoke Tests
        run: make test-smoke-staging
      - name: Run Migration
        run: kubectl exec -n smepro-staging deployment/api-gateway -- flyway migrate
```

---

## 6. Makefile Commands

```makefile
# Makefile
.PHONY: all build test lint deploy migrate clean

all: lint test build

lint:
	yarn lint:frontend
	go vet ./backend/services/...
	pylint ./backend/connectors/... ./ml/...
	mvn checkstyle:check -f ./backend/services/rules-engine/pom.xml

test:
	make test-unit
	make test-integration

test-unit:
	go test ./backend/services/...
	pytest ./backend/connectors/... ./ml/...
	jest ./frontend/apps/...

test-integration:
	docker-compose -f docker-compose.test.yml up --abort-on-container-exit

test-e2e:
	cypress run --spec "tests/e2e/cypress/integration/**/*.cy.ts"

build:
	docker build -t smepro/api-gateway:${VERSION} ./backend/api-gateway
	docker build -t smepro/canonical-layer:${VERSION} ./backend/services/canonical-layer
	docker build -t smepro/udm-query:${VERSION} ./backend/services/udm-query
	docker build -t smepro/connector-worker:${VERSION} ./backend/connectors
	docker build -t smepro/ml-persistence:${VERSION} ./ml/jobs/persistence
	docker build -t smepro/ml-transcript-nlp:${VERSION} ./ml/jobs/transcript-nlp
	for app in advisor-dashboard registrar-portal accreditation-dashboard chair-dashboard dean-dashboard compliance-dashboard edu-reporter; do \
		docker build -t smepro/frontend-$${app}:${VERSION} ./frontend/apps/$${app}; \
	done

push-staging:
	docker tag smepro/api-gateway:${VERSION} registry.staging.smepro.io/api-gateway:${VERSION}
	docker push registry.staging.smepro.io/api-gateway:${VERSION}
	# ... repeat for all images

push-production:
	docker tag smepro/api-gateway:${VERSION} registry.production.smepro.io/api-gateway:${VERSION}
	docker push registry.production.smepro.io/api-gateway:${VERSION}
	# ... repeat for all images

deploy-staging:
	kubectl apply -k k8s/overlays/staging

migrate:
	flyway -url=${DATABASE_URL} -locations=filesystem:db/migrations migrate

migrate-staging:
	kubectl exec -n smepro-staging deployment/api-gateway -- flyway migrate

migrate-production:
	kubectl exec -n smepro-production deployment/api-gateway -- flyway migrate

backup:
	pg_dump -h ${DB_HOST} -U ${DB_USER} -d ${DB_NAME} | gzip > backup-$(date +%Y%m%d).sql.gz

restore:
	gunzip -c ${BACKUP_FILE} | psql -h ${DB_HOST} -U ${DB_USER} -d ${DB_NAME}

clean:
	docker system prune -f
	docker volume prune -f
```

---

## 7. Development Environment Setup

```bash
# 1. Clone repository
git clone https://github.com/smepro/smepro-cos.git
cd smepro-cos

# 2. Start local development stack
make dev-up
# or:
docker-compose -f docker-compose.dev.yml up -d

# 3. Run migrations
make migrate

# 4. Seed test data
make seed-test

# 5. Start frontend development servers
cd frontend/apps/advisor-dashboard && yarn dev  # Port 3000
cd frontend/apps/registrar-portal && yarn dev   # Port 3001

# 6. Run tests
make test

# 7. Access services
# API Gateway: http://localhost:8080
# Advisor Dashboard: http://localhost:3000
# PostgreSQL: localhost:5432
# Redis: localhost:6379
# Elasticsearch: http://localhost:9200
# Grafana: http://localhost:3000 (admin/admin)
```

---

## 8. Service Dependencies Graph

```
api-gateway
├── canonical-layer
├── udm-query
├── evidence-chain
├── rules-engine
├── workflow-orchestrator
├── notification-service
└── approval-queue

canonical-layer
├── postgres-primary
└── redis

udm-query
├── postgres-primary
├── elasticsearch
└── redis

evidence-chain
├── postgres-primary
└── trace-chain-node

rules-engine
├── canonical-layer
└── udm-query

workflow-orchestrator
├── rules-engine
├── notification-service
└── approval-queue

ml-jobs (all)
├── postgres-primary
├── redis
└── mlflow

connector-workers
├── postgres-primary (staging tables)
├── kafka
└── external sources (Banner, Blackboard, etc.)

frontend-apps
├── api-gateway
└── (no direct DB access)
```

---

## 9. Monitoring & Alerting Matrix

| Alert | Metric | Threshold | Severity | Notification |
|-------|--------|-----------|----------|--------------|
| API Latency High | `http_request_duration_seconds` p99 | > 500ms | WARNING | Slack #ops |
| API Error Rate High | `http_request_errors_total` rate | > 1% | CRITICAL | PagerDuty + Slack #ops |
| ETL Job Failed | `airflow_dag_run_failed` | > 0 | CRITICAL | PagerDuty + email |
| ETL Job Slow | `airflow_dag_run_duration` | > 4 hours | WARNING | Slack #data |
| ML Inference Slow | `ml_inference_duration_seconds` p99 | > 2s | WARNING | Slack #ml |
| Model Drift Detected | `model_accuracy` | Drop > 5% | HIGH | PagerDuty + email |
| Bias Audit Fail | `disparate_impact_ratio` | < 0.80 | CRITICAL | PagerDuty + Slack #compliance + email to CCO |
| Data Quality Low | `great_expectations_validation` | < 95% | HIGH | Slack #data + email |
| Trace Chain Latency | `trace_chain_deploy_duration` | > 30s | WARNING | Slack #ops |
| Connector Down | `connector_up` | == 0 | CRITICAL | PagerDuty + Slack #ops |
| PostgreSQL Lag | `pg_replication_lag` | > 60s | HIGH | PagerDuty + Slack #ops |
| Disk Space Low | `disk_usage_percent` | > 85% | WARNING | Slack #ops |
| Memory Pressure | `memory_usage_percent` | > 90% | HIGH | PagerDuty + Slack #ops |

---

## 10. Key Files & Their Purposes

| File | Purpose | Who Owns |
|------|---------|----------|
| `docker-compose.yml` | Local development environment | DevOps |
| `docker-compose.prod.yml` | Production compose (if not using K8s) | DevOps |
| `k8s/base/*.yaml` | Base Kubernetes manifests | DevOps |
| `k8s/overlays/*/kustomization.yaml` | Environment-specific patches | DevOps |
| `db/migrations/V*.sql` | Database schema (Flyway) | DBA |
| `db/seeds/*.csv` | Reference data | Data Engineering |
| `backend/api-gateway/src/routes/*.ts` | External API surface | Backend Team |
| `backend/services/*/src/` | Internal microservices | Backend Team |
| `backend/connectors/workers/*/extract.py` | Data ingestion logic | Data Engineering |
| `ml/jobs/*/train.py` | Model training | ML Team |
| `ml/jobs/*/predict.py` | Model inference | ML Team |
| `frontend/apps/*/src/pages/` | User-facing pages | Frontend Team |
| `frontend/shared/components/` | Reusable UI components | Frontend Team |
| `tests/e2e/cypress/` | End-to-end tests | QA |
| `tests/load/k6/` | Performance tests | QA |
| `tests/security/zap/` | Security scans | Security |
| `monitoring/grafana/dashboards/` | Operational dashboards | DevOps |
| `docs/adr/*.md` | Architecture decisions | Architecture Team |
| `docs/runbooks/*.md` | Operational procedures | DevOps |

---

*End of Repository & Service Mapping.*
