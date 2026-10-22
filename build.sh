#!/usr/bin/env bash
# Rebuild an ondrej/php Ubuntu 22.04 (jammy) source package for Ubuntu 20.04 (focal).
# Usage: build.sh <source-package> <upstream-version-with-revision> <new-version>
# Example: build.sh php8.1 8.1.34-9 8.1.34-9+ubuntu20.04.1+backport1
set -euo pipefail

SOURCE="$1"
JAMMY_VERSION="$2"
NEW_VERSION="$3"
OUT_DIR="${OUT_DIR:-$PWD/out}"
DSC_URL="https://launchpad.net/~ondrej/+archive/ubuntu/php/+files/${SOURCE}_${JAMMY_VERSION}+ubuntu22.04.1+deb.sury.org+1.dsc"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  build-essential devscripts equivs fakeroot ca-certificates curl wget

WORK_DIR="$(mktemp -d)"
cd "$WORK_DIR"

# The .dsc signature key is not available in the container, so skip verification.
# Launchpad serves the files over HTTPS from its own librarian.
dget --allow-unauthenticated --extract "$DSC_URL"
cd "$(find . -maxdepth 1 -mindepth 1 -type d -name "${SOURCE}-*" | head -1)"

mk-build-deps --install --remove \
  --tool 'apt-get -y --no-install-recommends -o Debug::pkgProblemResolver=yes' \
  debian/control

dch --newversion "$NEW_VERSION" --distribution focal --force-distribution \
  "Rebuild of ${JAMMY_VERSION} for Ubuntu 20.04 (includes CVE-2026-109618 and CVE-2026-109619 fixes)."

DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)" dpkg-buildpackage -b -uc -us

mkdir -p "$OUT_DIR"
cp ../*.deb "$OUT_DIR"/
ls -lh "$OUT_DIR"
