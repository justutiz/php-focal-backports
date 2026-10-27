#!/usr/bin/env bash
# Read a Debian changelog from stdin and require the upstream CVE pair.
set -euo pipefail

# Older branches use square brackets; PHP 8.3 uses parentheses.
# Neither matches the rebuild-only note added by build.sh.
grep -F \
  -e '[CVE-2026-109618, CVE-2026-109619]' \
  -e '(CVE-2026-109618, CVE-2026-109619)'
