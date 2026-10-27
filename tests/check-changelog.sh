#!/usr/bin/env bash
# Run with: bash tests/check-changelog.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECKER="${CHECKER:-$ROOT_DIR/check-changelog.sh}"
failures=0

assert_status() {
  local expected="$1" label="$2" actual
  if bash "$CHECKER" > /dev/null; then
    actual=0
  else
    actual=$?
  fi
  if [ "$actual" -eq "$expected" ]; then
    echo "PASS: $label"
  else
    echo "FAIL: $label (expected status $expected, got $actual)" >&2
    failures=$((failures + 1))
  fi
}

# Excerpt from the ondrej/php Jammy source package's debian/changelog:
# php8.3_8.3.36-1+ubuntu22.04.1+deb.sury.org+1.debian.tar.xz
assert_status 0 'PHP 8.3 upstream entry with parentheses' <<'EOF'
php8.3 (8.3.36-1) unstable; urgency=medium

  * New upstream version 8.3.36
   + (CVE-2026-109618, CVE-2026-109619): Avoid state corruption via
     bailout.
EOF

# Excerpt from the existing PHP 8.1 source package's debian/changelog:
# php8.1_8.1.34-9+ubuntu22.04.1+deb.sury.org+1.debian.tar.xz
assert_status 0 'existing upstream entry with square brackets' <<'EOF'
  * Backported from 8.2.35
   + [CVE-2026-109618, CVE-2026-109619]: Avoid state corruption via
     bailout
EOF

assert_status 1 'rebuild entry alone does not prove upstream fixes' <<'EOF'
php8.3 (8.3.36-1+ubuntu20.04.1+backport1) focal; urgency=medium

  * Rebuild of 8.3.36-1 for Ubuntu 20.04 (includes CVE-2026-109618 and CVE-2026-109619 fixes).
EOF

assert_status 1 'first CVE alone is insufficient' <<'EOF'
   + [CVE-2026-109618]: Avoid state corruption via bailout.
EOF

assert_status 1 'second CVE alone is insufficient' <<'EOF'
   + (CVE-2026-109619): Avoid state corruption via bailout.
EOF

assert_status 1 'entry without the CVEs fails' <<'EOF'
  * New upstream version 8.3.35
EOF

[ "$failures" -eq 0 ]
