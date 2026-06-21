# Break-Glass Runbook

**Project:** SMEPro COS / Lamar IOS+  
**Version:** 1.0  
**Date:** 2026-06-21  
**Purpose:** Emergency procedures for when normal operations fail. This is the "what to do when everything is on fire" guide.

---

## ⚠️ When to Use This Runbook

Use this runbook **only** when:
- Normal procedures are not working (e.g., CI/CD is broken, GitHub is down)
- You need emergency access to fix a P1 incident
- Standard authentication is failing (e.g., IdP outage, SAML misconfiguration)
- You need to manually restore from backup
- You need to bypass normal approval gates to stop an ongoing incident

**Every break-glass action must be:**
- Logged to the evidence chain
- Approved by two people (if possible, or one + post-hoc review)
- Reverted as soon as the emergency is resolved
- Documented in the incident post-mortem

---

## 1. Emergency Contacts

| Role | Name | Phone | Email | Slack |
|------|------|-------|-------|-------|
| Lamar On-Call Primary | [TBD] | [TBD] | [TBD] | @on-call |
| Lamar On-Call Secondary | [TBD] | [TBD] | [TBD] | @on-call-secondary |
| Lamar CISO / Security Lead | [TBD] | [TBD] | [TBD] | @security-lead |
| Lamar IT Leadership | [TBD] | [TBD] | [TBD] | @it-leadership |
| SMEPro Emergency | [TBD] | [TBD] | support@smepro.io | @smepro-support |
| GCP Support (P1) | N/A | N/A | N/A | Console → Support |
| GitHub Support | N/A | N/A | N/A | support.github.com |

---

## 2. Break-Glass Access Procedures

### Scenario A: Normal Admin Access Fails (IdP Outage)

**Symptom:** SAML/OIDC is down. No one can log in. You need to fix the IdP config.

**Procedure:**

1. **Get emergency credentials from Secret Manager**
   ```bash
   gcloud secrets versions access latest --secret=break-glass-admin-password
   ```

2. **Access the Kubernetes node directly**
   ```bash
   gcloud compute ssh <node-name> --zone=<zone>
   ```

3. **Use kubectl from the node** (has local credentials)
   ```bash
   sudo kubectl exec -it deployment/api-gateway -n api-gateway -- /bin/sh
   ```

4. **Fix the IdP config (e.g., update metadata URL)**
   ```bash
   kubectl edit configmap auth-config -n api-gateway
   # Update SAML metadata URL or certificate
   ```

5. **Restart auth service**
   ```bash
   kubectl rollout restart deployment/api-gateway -n api-gateway
   ```

6. **Verify login works**
   ```bash
   curl -I https://ios.lamar.edu
   ```

7. **Revoke emergency access**
   ```bash
   gcloud secrets versions destroy latest --secret=break-glass-admin-password
   # Generate new password and store as new version
   ```

8. **Log to evidence chain**
   ```bash
   # Use evidence-chain CLI or API to log:
   # "Break-glass access used: IdP outage, config fixed, new password rotated"
   ```

### Scenario B: Database is Down and Auto-Failover Failed

**Symptom:** Cloud SQL primary is unhealthy. Replica did not promote. App cannot connect.

**Procedure:**

1. **Verify primary status**
   ```bash
   gcloud sql instances describe $DB_INSTANCE
   ```

2. **If primary is truly down, manually promote replica**
   ```bash
   gcloud sql instances promote-replica $REPLICA_INSTANCE
   ```

3. **Update application connection string**
   ```bash
   # If using Cloud SQL proxy, it auto-detects. If using IP, update:
   kubectl edit configmap db-config -n api-gateway
   # Update DB_HOST to new primary IP
   ```

4. **Restart dependent services**
   ```bash
   kubectl rollout restart deployment/api-gateway -n api-gateway
   kubectl rollout restart deployment/udm-query -n api-gateway
   ```

5. **Verify connectivity**
   ```bash
   kubectl exec -it deployment/api-gateway -n api-gateway -- \
     wget -qO- http://localhost:8080/health
   ```

6. **Log to evidence chain**
   ```bash
   # Log: "Manual failover executed: old primary [X], new primary [Y], reason [Z]"
   ```

7. **Create new replica**
   ```bash
   gcloud sql instances create $NEW_REPLICA --source-instance=$NEW_PRIMARY
   ```

8. **Investigate why auto-failover failed** (post-mortem action)

### Scenario C: Deployment is Broken and Rollback Fails

**Symptom:** v0.2.0 broke production. `kubectl rollout undo` is failing. You need to manually revert.

**Procedure:**

1. **Get last known good image digest**
   ```bash
   # From Artifact Registry or GitHub Actions logs
   gcloud artifacts docker tags list $REGISTRY/api-gateway --format='table(tag)'
   ```

2. **Manually patch deployment to use last good image**
   ```bash
   kubectl patch deployment api-gateway -n api-gateway -p \
     '{"spec":{"template":{"spec":{"containers":[{"name":"api-gateway","image":"'$REGISTRY'/api-gateway:v0.1.9@sha256:..."}]}}}}'
   ```

3. **Or edit deployment directly**
   ```bash
   kubectl edit deployment api-gateway -n api-gateway
   # Change image tag to v0.1.9
   ```

4. **Verify rollout**
   ```bash
   kubectl rollout status deployment/api-gateway -n api-gateway
   kubectl get pods -n api-gateway
   ```

5. **Run smoke tests**
   ```bash
   curl https://api.ios.lamar.edu/health
   npm run test:smoke -- --env=production
   ```

6. **Log to evidence chain**
   ```bash
   # Log: "Manual rollback to v0.1.9, reason: [incident description]"
   ```

### Scenario D: Certificate Expired and Auto-Renewal Failed

**Symptom:** Users see certificate errors. `cert-manager` did not renew.

**Procedure:**

1. **Check cert-manager logs**
   ```bash
   kubectl logs -n cert-manager deployment/cert-manager
   ```

2. **Force certificate renewal**
   ```bash
   kubectl delete certificate ios-plus-cert -n api-gateway
   kubectl apply -f k8s/base/certificate.yaml
   ```

3. **If Let's Encrypt is rate-limited, use purchased cert**
   ```bash
   # Upload purchased cert as secret
   kubectl create secret tls ios-plus-tls-manual \
     --cert=/path/to/cert.pem \
     --key=/path/to/key.pem \
     -n api-gateway
   
   # Update ingress to use manual cert
   kubectl edit ingress ios-plus-ingress -n api-gateway
   # Change secretName to ios-plus-tls-manual
   ```

4. **Verify certificate**
   ```bash
   openssl s_client -connect ios.lamar.edu:443 -servername ios.lamar.edu < /dev/null | openssl x509 -noout -dates
   ```

5. **Log to evidence chain**

### Scenario E: Security Breach Detected

**Symptom:** Unauthorized access detected. Attacker may be in the system.

**Procedure:**

1. **Immediately revoke all active sessions**
   ```bash
   # Flush Redis sessions
   kubectl exec -it deployment/redis -n api-gateway -- redis-cli FLUSHALL
   ```

2. **Rotate all secrets immediately**
   ```bash
   ./scripts/emergency-rotate-secrets.sh
   # This script should rotate: DB password, JWT key, API keys, etc.
   ```

3. **Isolate affected systems**
   ```bash
   # Add network policy to block all ingress/egress except monitoring
   kubectl apply -f k8s/emergency/quarantine-policy.yaml
   ```

4. **Preserve evidence**
   ```bash
   # Snapshot affected pods
   kubectl get pods -o yaml -n api-gateway > /tmp/evidence-pods-$(date +%s).yaml
   
   # Export logs
   kubectl logs -l app=api-gateway -n api-gateway --since=24h > /tmp/evidence-logs-$(date +%s).log
   
   # Snapshot disk (if possible)
   gcloud compute disks snapshot $DISK_NAME --zone=$ZONE
   ```

5. **Contact security team**
   - Page CISO / Security Lead immediately
   - Contact SMEPro support
   - If FERPA data involved, prepare breach notification

6. **Do NOT destroy evidence** until forensic analysis is complete

7. **After containment, rebuild from clean images**
   ```bash
   # Delete all pods and let them recreate from clean images
   kubectl delete pods --all -n api-gateway
   ```

8. **Log everything to evidence chain**

### Scenario F: Complete Environment Destruction (DR)

**Symptom:** Entire environment is destroyed (e.g., GCP project deletion, ransomware, natural disaster).

**Procedure:**

1. **Create new GCP project (or use DR project)**
   ```bash
   gcloud projects create lamar-ios-dr --organization=$ORG_ID
   ```

2. **Restore Terraform state from GCS backup**
   ```bash
   gsutil cp gs://backup-bucket/terraform-state/latest.tfstate ./
   terraform init -backend-config="path=./latest.tfstate"
   ```

3. **Apply infrastructure**
   ```bash
   terraform apply -auto-approve
   ```

4. **Restore database from backup**
   ```bash
   gcloud sql backups restore $BACKUP_ID --instance=$NEW_INSTANCE
   # Or for on-prem:
   pgbackrest --stanza=ios-plus restore
   ```

5. **Restore secrets from Vault backup or emergency offline store**
   ```bash
   # Use emergency secret store (encrypted USB, HSM, etc.)
   ./scripts/restore-secrets-from-emergency-store.sh
   ```

6. **Deploy application from last known good image**
   ```bash
   helm install ios-plus ./k8s/helm --values values-production.yaml
   ```

7. **Run smoke tests**
   ```bash
   npm run test:smoke -- --env=production
   ```

8. **Update DNS to point to new environment**
   ```bash
   gcloud dns record-sets update ios.lamar.edu \
     --zone=lamar-zone \
     --type=A \
     --rrdatas=<NEW_INGRESS_IP>
   ```

9. **Notify all stakeholders**
   - Leadership
   - Users
   - SMEPro support
   - Regulators (if FERPA breach occurred)

10. **Run full incident response and post-mortem**

---

## 3. Emergency Scripts

### `scripts/emergency-rotate-secrets.sh`

Create this script and test it in staging before production:

```bash
#!/bin/bash
set -e

ENVIRONMENT=$1
PROJECT_ID=$2

echo "=== EMERGENCY SECRET ROTATION ==="
echo "Environment: $ENVIRONMENT"
echo "Project: $PROJECT_ID"
echo "Started: $(date)"
echo "Approved by: [ENTER YOUR NAME]"
read -p "Continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 1
fi

# Generate new secrets
DB_PASSWORD=$(openssl rand -base64 32)
JWT_KEY=$(openssl rand -base64 64)
REDIS_PASSWORD=$(openssl rand -base64 32)

# Update Secret Manager
gcloud secrets versions add db-password --data-file=<(echo -n "$DB_PASSWORD") --project=$PROJECT_ID
gcloud secrets versions add jwt-signing-key --data-file=<(echo -n "$JWT_KEY") --project=$PROJECT_ID
gcloud secrets versions add redis-password --data-file=<(echo -n "$REDIS_PASSWORD") --project=$PROJECT_ID

# Restart all pods to pick up new secrets
kubectl rollout restart deployment --all -n api-gateway
kubectl rollout restart deployment --all -n connector-ingestion
kubectl rollout restart deployment --all -n normalization
# ... etc for all namespaces

echo "=== SECRET ROTATION COMPLETE ==="
echo "Completed: $(date)"
echo "Log this to evidence chain immediately."
```

### `scripts/emergency-quarantine.sh`

```bash
#!/bin/bash
NAMESPACE=$1

echo "Quarantining namespace: $NAMESPACE"
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: emergency-quarantine
  namespace: $NAMESPACE
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  # Deny all by default (no ingress/egress rules = deny all)
EOF

echo "Namespace $NAMESPACE quarantined. Only pods within namespace can communicate."
```

### `scripts/emergency-restore.sh`

```bash
#!/bin/bash
BACKUP_ID=$1
INSTANCE_NAME=$2

echo "Restoring database from backup: $BACKUP_ID"
gcloud sql backups restore $BACKUP_ID --instance=$INSTANCE_NAME

echo "Restore initiated. Monitor with:"
echo "  gcloud sql operations list --instance=$INSTANCE_NAME"
```

---

## 4. Evidence Chain Logging

Every break-glass action must be logged to the evidence chain:

```bash
# Example: log break-glass access
./scripts/log-evidence.sh \
  --action="break-glass-access" \
  --actor="ops-on-call@lamar.edu" \
  --reason="IdP outage, manual config fix required" \
  --scope="api-gateway/auth-config" \
  --outcome="Config updated, service restored" \
  --approver="it-leadership@lamar.edu"
```

If the evidence chain service is down, log to a secure file and backfill when service is restored:

```bash
# Emergency log file (append-only, tamper-evident)
echo "$(date) | break-glass | $(whoami) | [reason] | [action] | [outcome]" >> /var/log/emergency-evidence.log
chmod 400 /var/log/emergency-evidence.log
```

---

## 5. Post-Emergency Review

Within 24 hours of any break-glass use:

1. **Schedule post-mortem**
2. **Review evidence chain logs**
3. **Verify no unauthorized access occurred during break-glass window**
4. **Rotate any secrets that were exposed**
5. **Fix root cause so break-glass is not needed again**
6. **Update runbook with lessons learned**
7. **Sign-off from CISO / Security Lead**

---

*This runbook is tested quarterly. If you use it, improve it. If you don't use it, test it anyway.*
