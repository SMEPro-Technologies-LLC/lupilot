# Transfer Inventory Report

**Generated:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Purpose:** Inventory of all SMEPro-specific references that must be parameterized before transfer to Lamar University.

## Action Items

   ...

## Summary

| Check | Status |
|-------|--------|
| Hard-coded org names | ❌ Found |
| Hard-coded project IDs | ❌ Found |
| Hard-coded domains | ❌ Found |
| SMEPro emails | ❌ Found |
| Slack webhooks | ❌ Found |
| Potential secrets | ⚠️ Review |
| Registry URLs | ❌ Found |
| Terraform parameterization | ❌ Found |
| K8s parameterization | ✅ Clean |

**Total Issues Found:** 12

## Recommended Actions

1. Replace all hard-coded `SMEPro-Technologies-LLC` with `${GITHUB_ORG}` or parameterized variable
2. Replace all `smepro-cos-*` project IDs with Terraform variables
3. Replace all `smepro.` domains with `${DOMAIN}` or env var
4. Replace all SMEPro emails with `${SUPPORT_EMAIL}` or env var
5. Replace all Slack webhooks with Secret Manager references
6. Replace all registry URLs with `${REGISTRY}` or env var
7. Review seed files for real data; replace with synthetic fixtures
8. Run `git-secrets` or `truffleHog` to scan for hidden secrets
9. Verify all CI/CD workflows use repository variables, not hard-coded values
10. Add `CODEOWNERS` and `CONTRIBUTING.md` before transfer
