# Operations Handoff Guide

**Project:** SMEPro COS / Lamar IOS+  
**Version:** 1.0  
**Date:** 2026-06-21  
**Purpose:** Runbooks, incident response procedures, on-call responsibilities, and day-to-day operational guidance for the Lamar team.

---

## 1. On-Call & Escalation

### Team Structure

| Role | Team | Responsibility | Contact |
|------|------|---------------|---------|
| Primary On-Call | Lamar IOS+ Ops | First responder, triage, initial diagnosis | PagerDuty / OpsGenie rotation |
| Secondary On-Call | Lamar IOS+ Dev | Code-level fixes, deployment rollbacks | Slack #ios-plus-alerts |
| SMEPro Support | SMEPro Technologies | Architecture guidance, complex bugs | support@smepro.io (SLA-based) |
| Lamar Leadership | Lamar IT Leadership | Decision authority, vendor escalation | Emergency contact list |

### Escalation Matrix

| Severity | Response Time | Resolution Target | Escalation Path |
|----------|--------------|-------------------|-----------------|
| P1 — Critical | 15 min | 4 hours | Primary → Secondary → SMEPro → Leadership |
| P2 — High | 1 hour | 24 hours | Primary → Secondary → SMEPro |
| P3 — Medium | 4 hours | 72 hours | Secondary → SMEPro (next business day) |
| P4 — Low | 24 hours | 1 week | Backlog / SMEPro (next sprint) |

### P1 Criteria
- Complete platform outage (all users cannot access)
- Data loss or corruption in progress
- Security breach or unauthorized access detected
- FERPA-sensitive data exposure
- Database unavailability with no failover

### P2 Criteria
- Single service failure affecting >50% of users
- Performance degradation (p95 latency >5s)
- Backup failure
- Certificate expiry within 24 hours
- Auth failure for >10% of users

### P3 Criteria
- Single service failure affecting <50% of users
- Non-critical job failures
- Monitoring/alerting gaps
- Minor UI bugs

### P4 Criteria
- Documentation updates
- Feature requests
- Performance optimizations
- Technical debt

---

## 2. Incident Response Runbook

### Phase 1: Detect & Triage (0–15 min)

1. **Alert fires** (PagerDuty, Slack, email)
2. **Acknowledge alert** within 15 minutes (P1) or 1 hour (P2)
3. **Assess severity** using criteria above
4. **Create incident channel** (Slack: `#incident-YYYY-MM-DD-shortname`)
5. **Notify stakeholders**:
   - P1: Page primary on-call + secondary + SMEPro + leadership
   - P2: Slack #ios-plus-alerts + SMEPro (if needed)
   - P3/P4: Ticket in backlog

### Phase 2: Diagnose (15–45 min)

**Quick health checks:**
```bash
# Check all pods
kubectl get pods --all-namespaces

# Check recent events
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -50

# Check ingress
kubectl get ingress -A

# Check database
kubectl exec -it deployment/api-gateway -n api-gateway -- \
  wget -qO- http://localhost:8080/health

# Check logs
kubectl logs -l app=api-gateway -n api-gateway --tail=100

# Check metrics
curl -s http://prometheus.monitoring:9090/api/v1/query?query=up
```

**Common diagnostic patterns:**

| Symptom | Likely Cause | Check |
|---------|-------------|-------|
| All pods "Pending" | Resource exhaustion / node pool issue | `kubectl describe nodes` |
| Pods "CrashLoopBackOff" | App error / misconfig | `kubectl logs` + `kubectl describe pod` |
| 502/503 from ingress | Backend unavailable | `kubectl get endpoints` + pod health |
| DB connection errors | Cloud SQL proxy / network policy | `kubectl logs` on SQL proxy sidecar |
| High latency | Resource saturation / DB slow queries | Grafana dashboard + Cloud SQL insights |
| Auth failures | IdP issue / cert expiry / clock skew | IdP logs + cert expiry date |
| Memory pressure | Memory leak / insufficient limits | `kubectl top pods` + memory graphs |

### Phase 3: Mitigate (30–120 min)

**Immediate actions (do not require approval):**
- Scale up replicas: `kubectl scale deployment/api-gateway --replicas=5`
- Restart failing pods: `kubectl rollout restart deployment/<name>`
- Switch DNS to maintenance page
- Enable circuit breakers if configured
- Increase resource limits (temporary)

**Actions requiring approval:**
- Database restore from backup
- Certificate rotation
- Deployment rollback
- IdP configuration changes
- Firewall rule changes
- Secret rotation

### Phase 4: Resolve & Verify (120+ min)

1. **Apply fix** (code fix, config change, rollback)
2. **Verify service health**:
   ```bash
   curl https://ios.lamar.edu/health
   curl https://api.ios.lamar.edu/health
   # Run smoke tests
   npm run test:smoke -- --env=production
   ```
3. **Monitor for 30 minutes** after fix
4. **Close incident channel** with summary
5. **Schedule post-mortem** within 48 hours (for P1/P2)

### Phase 5: Post-Mortem (within 48 hours)

Document in `docs/incidents/YYYY-MM-DD-incident-name.md`:
- Timeline (detect, diagnose, mitigate, resolve)
- Root cause (5 Whys)
- Impact (users affected, data lost, duration)
- What went well
- What went poorly
- Action items (with owners and deadlines)
- Follow-up monitoring/alerts needed

---

## 3. Deployment Procedures

### Standard Deployment (Staging)

**Prerequisites:**
- PR approved and merged to `develop`
- CI pipeline passed (build, test, security scan)
- No open P1/P2 incidents

**Steps:**
```bash
# 1. Tag the release
git checkout develop
git pull origin develop
git tag -a v0.2.0-staging -m "Staging release v0.2.0"
git push origin v0.2.0-staging

# 2. CI/CD pipeline triggers automatically
# Or manually:
gcloud deploy releases create v0.2.0-staging \
  --delivery-pipeline=ios-plus-pipeline \
  --target=staging \
  --source=k8s/overlays/staging

# 3. Verify deployment
kubectl get pods -n api-gateway
kubectl rollout status deployment/api-gateway -n api-gateway

# 4. Run smoke tests
npm run test:smoke -- --env=staging

# 5. Notify team in Slack #ios-plus-deployments
```

### Production Deployment (Approved)

**Prerequisites:**
- Staging deployment verified for 24+ hours
- Change request approved (for regulated environments)
- Security scan clean
- Backup completed within last 4 hours
- Rollback plan documented
- Deployment window agreed (low-traffic period)

**Approval Gate:**
- Requires 2 approvers: Lamar Dev Lead + Lamar Ops Lead
- SMEPro support notified (optional for Wave 1+)
- Automated deployment blocked until manual approval in GitHub Environments

**Steps:**
```bash
# 1. Create production release from verified staging tag
git tag -a v0.2.0 -m "Production release v0.2.0"
git push origin v0.2.0

# 2. GitHub Environment protection requires manual approval
# Approver clicks "Approve" in GitHub Actions

# 3. Pipeline deploys with canary
# 25% → 50% → 75% → 100% (with automated health checks at each stage)

# 4. Monitor canary metrics
# Grafana dashboard: "Canary Health"
# Key metrics: error rate <0.1%, p95 latency <500ms, 5xx rate <0.01%

# 5. If canary fails at any stage, pipeline auto-rolls back
# If manual abort needed:
gcloud deploy rollouts abort rollout-id --release=v0.2.0 --delivery-pipeline=ios-plus-pipeline

# 6. Verify production
kubectl get pods -n api-gateway
kubectl rollout status deployment/api-gateway -n api-gateway
curl https://api.ios.lamar.edu/health
npm run test:smoke -- --env=production

# 7. Notify stakeholders
# Slack #ios-plus-deployments + email to leadership
```

### Rollback Procedure

**When to rollback:**
- Error rate >1% after deployment
- P1 incident directly caused by deployment
- Data integrity issues detected
- Performance degradation >3x baseline

**Steps:**
```bash
# 1. Identify last known good tag
# Example: v0.1.9 was last stable, v0.2.0 is broken

# 2. Trigger rollback
git tag -a v0.2.0-rollback -m "Rollback to v0.1.9"
git push origin v0.2.0-rollback

# Or manually:
kubectl rollout undo deployment/api-gateway -n api-gateway
kubectl rollout undo deployment/udm-query -n api-gateway
# ... etc for all affected deployments

# 3. Verify rollback
kubectl get pods -n api-gateway
kubectl rollout status deployment/api-gateway -n api-gateway
curl https://api.ios.lamar.edu/health
npm run test:smoke -- --env=production

# 4. If rollback fails, use break-glass procedure (see BREAK_GLASS_RUNBOOK.md)
```

---

## 4. Backup & Restore

### Backup Schedule

| Data | Frequency | Retention | Method | Owner |
|------|-----------|-----------|--------|-------|
| PostgreSQL | Daily + continuous WAL | 30 days | Cloud SQL automated backups / pgBackRest | Lamar Ops |
| Redis | Hourly snapshots | 7 days | Redis RDB + GCS sync | Lamar Ops |
| GCS Buckets | Cross-region replication | 90 days | Object versioning + lifecycle policy | Lamar Ops |
| K8s manifests | On every deployment | 30 days | Git tags + Velero | Lamar Ops |
| Secrets | On rotation | 90 days | Secret Manager versions / Vault snapshots | Lamar Ops |

### Restore Procedure — PostgreSQL

```bash
# 1. Identify backup to restore from
# Cloud SQL: Console → SQL → Backups
# On-prem: pgBackRest list

# 2. For Cloud SQL (point-in-time recovery)
gcloud sql instances clone source-instance target-instance \
  --point-in-time='2026-06-21T12:00:00Z'

# Or restore from backup:
gcloud sql backups restore BACKUP_ID --instance=source-instance

# 3. For on-prem (pgBackRest)
pgbackrest --stanza=ios-plus restore --type=time --target="2026-06-21 12:00:00"

# 4. Verify restore
psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT count(*) FROM students;"
# Should match expected count

# 5. Update application to point to restored DB (if different instance)
# Edit ConfigMap or env vars, restart pods
kubectl rollout restart deployment/api-gateway -n api-gateway

# 6. Run smoke tests
npm run test:smoke -- --env=production
```

### Restore Drill Schedule
- **Monthly:** Restore PostgreSQL to a temporary instance and verify data integrity
- **Quarterly:** Full environment restore to a new namespace / project
- **Annually:** DR failover to secondary region (if configured)

---

## 5. Monitoring & Alerting

### Dashboards (Grafana)

| Dashboard | URL | Purpose | Refresh |
|-----------|-----|---------|---------|
| Platform Overview | `https://grafana.ios.lamar.edu/d/platform` | All services, health, traffic | 30s |
| API Gateway | `https://grafana.ios.lamar.edu/d/api-gateway` | Latency, error rate, throughput | 10s |
| Database | `https://grafana.ios.lamar.edu/d/database` | Connections, slow queries, replication | 30s |
| Redis | `https://grafana.ios.lamar.edu/d/redis` | Memory, connections, hit rate | 30s |
| Kubernetes | `https://grafana.ios.lamar.edu/d/k8s` | Nodes, pods, resources | 30s |
| Compliance | `https://grafana.ios.lamar.edu/d/compliance` | Audit events, auth failures, access patterns | 60s |
| Cost | `https://grafana.ios.lamar.edu/d/cost` | GCP spend by service | 1h |

### Alerts

| Alert Name | Condition | Severity | Channel | Runbook |
|------------|-----------|----------|---------|---------|
| ServiceDown | `up == 0` for 2m | P1 | PagerDuty + Slack | `RUNBOOK_ServiceDown.md` |
| HighErrorRate | `rate(http_requests_total{status=~"5.."}[5m]) > 0.01` | P1 | PagerDuty + Slack | `RUNBOOK_HighErrorRate.md` |
| HighLatency | `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 5` | P2 | Slack | `RUNBOOK_HighLatency.md` |
| DBConnectionsHigh | `pg_stat_activity_count > 80` | P2 | Slack | `RUNBOOK_DBConnections.md` |
| DBReplicationLag | `pg_replication_lag_seconds > 10` | P2 | Slack | `RUNBOOK_DBReplication.md` |
| RedisMemoryHigh | `redis_memory_used_percent > 80` | P2 | Slack | `RUNBOOK_RedisMemory.md` |
| CertificateExpiry | `certmanager_certificate_expiration_seconds < 86400 * 7` | P2 | Slack | `RUNBOOK_CertExpiry.md` |
| BackupFailed | `backup_last_successful_timestamp < now() - 86400` | P2 | Slack | `RUNBOOK_BackupFailed.md` |
| DiskSpaceLow | `node_filesystem_avail_percent < 10` | P2 | Slack | `RUNBOOK_DiskSpace.md` |
| MemoryPressure | `container_memory_working_set_bytes / container_spec_memory_limit_bytes > 0.9` | P3 | Slack | `RUNBOOK_MemoryPressure.md` |
| FailedJob | `kube_job_status_failed > 0` | P3 | Slack | `RUNBOOK_FailedJob.md` |

---

## 6. Maintenance Windows

### Scheduled Maintenance

| Window | Frequency | Activities | Notification |
|--------|-----------|------------|-------------|
| Tuesday 2:00–4:00 AM CST | Weekly | Patch Tuesday updates, minor version bumps | 48 hours ahead |
| First Saturday 2:00–6:00 AM CST | Monthly | Major upgrades, database maintenance | 1 week ahead |
| Quarterly | Quarterly | Security audits, DR drills, certificate renewals | 2 weeks ahead |

### Change Management

All changes to production require:
1. **Change Request (CR)** ticket
2. **Risk assessment** (impact, rollback plan, test results)
3. **Approval** from 2 people (Dev Lead + Ops Lead)
4. **Deployment window** outside peak hours
5. **Verification** after deployment
6. **Post-change review** within 24 hours

**Exceptions:**
- Security patches (P1) — fast-track with post-hoc review
- Rollbacks — immediate, review within 4 hours

---

## 7. Security Operations

### Daily Security Checks
- [ ] Review failed auth attempts (Grafana compliance dashboard)
- [ ] Review unauthorized access alerts
- [ ] Check for new CVEs in base images (Trivy/Dependabot)
- [ ] Verify backup completion

### Weekly Security Checks
- [ ] Rotate logs and verify retention
- [ ] Review IAM access (who has what)
- [ ] Check for leaked secrets (GitHub secret scanning)
- [ ] Review firewall rules and network policies

### Monthly Security Checks
- [ ] Run vulnerability scan on all images
- [ ] Generate SBOMs for all services
- [ ] Review access logs for anomalies
- [ ] Update threat model if architecture changed
- [ ] Test break-glass access

### Quarterly Security Checks
- [ ] Penetration test (internal or third-party)
- [ ] FERPA compliance audit
- [ ] Role access review (RBAC cleanup)
- [ ] Certificate inventory and renewal
- [ ] Disaster recovery drill

---

## 8. Capacity Planning

### Current Capacity Baseline

| Resource | Current | Limit | Headroom | Action Threshold |
|----------|---------|-------|----------|-----------------|
| GKE Nodes | 3 | 100 | 97 | Scale at 80% |
| PostgreSQL Connections | 50 | 100 | 50 | Scale at 80% |
| Redis Memory | 2 GB | 8 GB | 6 GB | Scale at 80% |
| GCS Storage | 500 GB | 10 TB | 9.5 TB | Alert at 80% |
| Ingress Throughput | 100 Mbps | 1 Gbps | 900 Mbps | Scale at 80% |

### Scaling Procedures

**Horizontal Pod Autoscaling:**
```bash
kubectl autoscale deployment api-gateway \
  --cpu-percent=70 \
  --min=3 \
  --max=10 \
  -n api-gateway
```

**Vertical Pod Scaling:**
```bash
kubectl patch deployment api-gateway -n api-gateway -p \
  '{"spec":{"template":{"spec":{"containers":[{"name":"api-gateway","resources":{"requests":{"cpu":"500m","memory":"1Gi"},"limits":{"cpu":"2","memory":"4Gi"}}}]}}}}'
```

**Node Pool Scaling:**
```bash
gcloud container clusters resize $CLUSTER_NAME \
  --node-pool $POOL_NAME \
  --num-nodes=5 \
  --region=$REGION
```

**Database Scaling:**
- Cloud SQL: Edit instance → increase tier (e.g., db-g1-small → db-n1-standard-2)
- On-prem: Add read replicas, partition tables, or scale hardware

---

*This guide is a living document. Update it as operational procedures evolve. Every incident teaches something — document it.*
