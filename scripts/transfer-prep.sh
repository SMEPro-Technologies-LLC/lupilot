#!/bin/bash
# transfer-prep.sh
# Inventory and scrub SMEPro-specific references for Lamar transfer
# Run this before any repository transfer or external deployment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORT_FILE="$REPO_ROOT/docs/TRANSFER_INVENTORY_REPORT.md"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "========================================"
echo "SMEPro COS Transfer Preparation Script"
echo "========================================"
echo ""

# Create report header
cat > "$REPORT_FILE" << 'EOF'
# Transfer Inventory Report

**Generated:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Purpose:** Inventory of all SMEPro-specific references that must be parameterized before transfer to Lamar University.

## Action Items

EOF

# Counter for issues
FOUND_ISSUES=0

echo "Scanning repository for SMEPro-specific references..."
echo ""

# 1. Check for hard-coded org names
echo -e "${YELLOW}1. Checking for hard-coded organization names...${NC}"
ORG_REFS=$(grep -rI "SMEPro-Technologies-LLC" "$REPO_ROOT" --exclude-dir=.git --exclude-dir=node_modules --exclude="*.png" --exclude="*.jpg" --exclude="*.gif" --exclude="TRANSFER_INVENTORY_REPORT.md" || true)
if [ -n "$ORG_REFS" ]; then
    echo -e "${RED}   Found SMEPro-Technologies-LLC references:${NC}"
    echo "$ORG_REFS" | head -20
    echo "   ..." >> "$REPORT_FILE"
    FOUND_ISSUES=$((FOUND_ISSUES + 1))
else
    echo -e "${GREEN}   ✓ No hard-coded org references found${NC}"
fi

# 2. Check for hard-coded project IDs
echo -e "${YELLOW}2. Checking for hard-coded GCP project IDs...${NC}"
PROJECT_REFS=$(grep -rI "smepro-cos-" "$REPO_ROOT" --exclude-dir=.git --exclude-dir=node_modules --exclude="TRANSFER_INVENTORY_REPORT.md" || true)
if [ -n "$PROJECT_REFS" ]; then
    echo -e "${RED}   Found smepro-cos- project ID references:${NC}"
    echo "$PROJECT_REFS" | head -20
    FOUND_ISSUES=$((FOUND_ISSUES + 1))
else
    echo -e "${GREEN}   ✓ No hard-coded project IDs found${NC}"
fi

# 3. Check for hard-coded domains
echo -e "${YELLOW}3. Checking for hard-coded SMEPro domains...${NC}"
DOMAIN_REFS=$(grep -rI "smepro\." "$REPO_ROOT" --exclude-dir=.git --exclude-dir=node_modules --exclude="TRANSFER_INVENTORY_REPORT.md" || true)
if [ -n "$DOMAIN_REFS" ]; then
    echo -e "${RED}   Found smepro. domain references:${NC}"
    echo "$DOMAIN_REFS" | head -20
    FOUND_ISSUES=$((FOUND_ISSUES + 1))
else
    echo -e "${GREEN}   ✓ No hard-coded SMEPro domains found${NC}"
fi

# 4. Check for email references
echo -e "${YELLOW}4. Checking for SMEPro email addresses...${NC}"
EMAIL_REFS=$(grep -rI "@smepro\." "$REPO_ROOT" --exclude-dir=.git --exclude-dir=node_modules --exclude="TRANSFER_INVENTORY_REPORT.md" || true)
if [ -n "$EMAIL_REFS" ]; then
    echo -e "${RED}   Found SMEPro email references:${NC}"
    echo "$EMAIL_REFS" | head -20
    FOUND_ISSUES=$((FOUND_ISSUES + 1))
else
    echo -e "${GREEN}   ✓ No SMEPro email addresses found${NC}"
fi

# 5. Check for Slack webhooks or notification channels
echo -e "${YELLOW}5. Checking for Slack/notification channel references...${NC}"
SLACK_REFS=$(grep -rI "hooks\.slack\.com" "$REPO_ROOT" --exclude-dir=.git --exclude-dir=node_modules --exclude="TRANSFER_INVENTORY_REPORT.md" || true)
if [ -n "$SLACK_REFS" ]; then
    echo -e "${RED}   Found Slack webhook references:${NC}"
    echo "$SLACK_REFS" | head -10
    FOUND_ISSUES=$((FOUND_ISSUES + 1))
else
    echo -e "${GREEN}   ✓ No hard-coded Slack webhooks found${NC}"
fi

# 6. Check for hard-coded passwords or secrets patterns
echo -e "${YELLOW}6. Checking for potential secrets in code...${NC}"
SECRET_PATTERNS=("password.*=" "api_key.*=" "secret.*=" "token.*=" "private_key")
for pattern in "${SECRET_PATTERNS[@]}"; do
    SECRET_REFS=$(grep -rI "$pattern" "$REPO_ROOT" --exclude-dir=.git --exclude-dir=node_modules --exclude="TRANSFER_INVENTORY_REPORT.md" | grep -v "example" | grep -v "template" | grep -v "placeholder" | head -10 || true)
    if [ -n "$SECRET_REFS" ]; then
        echo -e "${RED}   Found potential secret patterns ($pattern):${NC}"
        echo "$SECRET_REFS"
        FOUND_ISSUES=$((FOUND_ISSUES + 1))
    fi
done

# 7. Check for hard-coded registry URLs
echo -e "${YELLOW}7. Checking for hard-coded container registry URLs...${NC}"
REGISTRY_REFS=$(grep -rI "artifact-registry" "$REPO_ROOT" --exclude-dir=.git --exclude-dir=node_modules --exclude="TRANSFER_INVENTORY_REPORT.md" || true)
if [ -n "$REGISTRY_REFS" ]; then
    echo -e "${RED}   Found hard-coded registry references:${NC}"
    echo "$REGISTRY_REFS" | head -20
    FOUND_ISSUES=$((FOUND_ISSUES + 1))
else
    echo -e "${GREEN}   ✓ No hard-coded registry URLs found${NC}"
fi

# 8. Check for hard-coded branch assumptions
echo -e "${YELLOW}8. Checking for hard-coded branch assumptions...${NC}"
BRANCH_REFS=$(grep -rI "main\|develop\|master" "$REPO_ROOT/.github" --exclude-dir=node_modules 2>/dev/null || true)
if [ -n "$BRANCH_REFS" ]; then
    echo -e "${YELLOW}   Found branch references in GitHub Actions (review for transfer):${NC}"
    echo "$BRANCH_REFS" | head -10
else
    echo -e "${GREEN}   ✓ No concerning branch assumptions found${NC}"
fi

# 9. Check for missing environment parameterization
echo -e "${YELLOW}9. Checking for environment parameterization gaps...${NC}"
# Check if Terraform uses variables instead of hard-coded values
if grep -rI "smepro-cos-" "$REPO_ROOT/infra/terraform" >/dev/null 2>&1; then
    echo -e "${RED}   Terraform modules have hard-coded project references${NC}"
    FOUND_ISSUES=$((FOUND_ISSUES + 1))
else
    echo -e "${GREEN}   ✓ Terraform appears parameterized${NC}"
fi

# Check if K8s manifests use ConfigMaps/Secrets
if grep -rI "value: smepro" "$REPO_ROOT/k8s" >/dev/null 2>&1; then
    echo -e "${RED}   K8s manifests have hard-coded SMEPro values${NC}"
    FOUND_ISSUES=$((FOUND_ISSUES + 1))
else
    echo -e "${GREEN}   ✓ K8s manifests appear parameterized${NC}"
fi

# 10. Check for real data in fixtures/seeds
echo -e "${YELLOW}10. Checking for real data in fixtures/seeds...${NC}"
if [ -d "$REPO_ROOT/db/seeds" ]; then
    SEED_FILES=$(find "$REPO_ROOT/db/seeds" -type f 2>/dev/null | wc -l)
    if [ "$SEED_FILES" -gt 0 ]; then
        echo -e "${YELLOW}   Found $SEED_FILES seed files. Review for real data.${NC}"
        echo "   Review these files for real PII before transfer:"
        find "$REPO_ROOT/db/seeds" -type f | head -10
    else
        echo -e "${GREEN}   ✓ No seed files found${NC}"
    fi
else
    echo -e "${GREEN}   ✓ No seeds directory found${NC}"
fi

# Generate report
cat >> "$REPORT_FILE" << EOF

## Summary

| Check | Status |
|-------|--------|
| Hard-coded org names | $([ -z "$ORG_REFS" ] && echo "✅ Clean" || echo "❌ Found") |
| Hard-coded project IDs | $([ -z "$PROJECT_REFS" ] && echo "✅ Clean" || echo "❌ Found") |
| Hard-coded domains | $([ -z "$DOMAIN_REFS" ] && echo "✅ Clean" || echo "❌ Found") |
| SMEPro emails | $([ -z "$EMAIL_REFS" ] && echo "✅ Clean" || echo "❌ Found") |
| Slack webhooks | $([ -z "$SLACK_REFS" ] && echo "✅ Clean" || echo "❌ Found") |
| Potential secrets | $([ $FOUND_ISSUES -eq 0 ] && echo "✅ Clean" || echo "⚠️ Review") |
| Registry URLs | $([ -z "$REGISTRY_REFS" ] && echo "✅ Clean" || echo "❌ Found") |
| Terraform parameterization | $([ -z "$(grep -rI 'smepro-cos-' "$REPO_ROOT/infra/terraform" 2>/dev/null || true)" ] && echo "✅ Clean" || echo "❌ Found") |
| K8s parameterization | $([ -z "$(grep -rI 'value: smepro' "$REPO_ROOT/k8s" 2>/dev/null || true)" ] && echo "✅ Clean" || echo "❌ Found") |

**Total Issues Found:** $FOUND_ISSUES

## Recommended Actions

EOF

if [ $FOUND_ISSUES -eq 0 ]; then
    echo "✅ Repository is clean. Ready for transfer." >> "$REPORT_FILE"
    echo -e "${GREEN}"
    echo "========================================"
    echo "✅ REPOSITORY IS CLEAN"
    echo "========================================"
    echo -e "${NC}"
    echo "Report saved to: $REPORT_FILE"
    exit 0
else
    cat >> "$REPORT_FILE" << 'EOF'
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
EOF

    echo -e "${RED}"
    echo "========================================"
    echo "❌ FOUND $FOUND_ISSUES ISSUE(S)"
    echo "========================================"
    echo -e "${NC}"
    echo "Review and fix the issues above before transfer."
    echo "Detailed report saved to: $REPORT_FILE"
    exit 1
fi
