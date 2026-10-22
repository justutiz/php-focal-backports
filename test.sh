#!/usr/bin/env bash
# Install the rebuilt packages of one PHP version on a clean Ubuntu 20.04 and check that they work.
# Usage: test.sh <source-package> <deb-dir> <release-suffix> [upgrade]
# With "upgrade", Ubuntu's own packages are installed first and replaced with the README Quick start commands.
# Example: test.sh php7.4 debs backport1 upgrade
set -euo pipefail

SOURCE="$1"
DEB_DIR="$(realpath "$2")"
SUFFIX="$3"
UPGRADE="${4:-}"
V="${SOURCE#php}"
PACKAGES="cli fpm common opcache readline json gd mysql mbstring xml curl zip bcmath"
EXTENSIONS="readline json gd mysqli pdo_mysql mbstring dom curl zip bcmath"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends libfcgi-bin

# json is built in since PHP 8.0, so only the packages present in the build are used.
debs=()
for p in $PACKAGES; do
  for f in "$DEB_DIR/php${V}-${p}"_*.deb; do [ -e "$f" ] && debs+=("$f"); done
done

if [ "$UPGRADE" = upgrade ]; then
  apt-get install -y --no-install-recommends $(for f in "${debs[@]}"; do basename "$f" | cut -d_ -f1; done)
  # Same commands as the README Quick start; dpkg-query fails when a pattern matches nothing.
  set +o pipefail
  cd "$DEB_DIR"
  installed=$(dpkg-query -W -f='${Package} ${Status}\n' "php${V}*" "libapache2-mod-php${V}" "libphp${V}-embed" 2>/dev/null | awk '/ installed$/{print $1}')
  dpkg -i $(for p in $installed; do ls "${p}"_*.deb; done)
  cd - > /dev/null
  set -o pipefail
else
  apt-get install -y --no-install-recommends "${debs[@]}"
fi

echo "--- Every installed php${V} package comes from the rebuild"
dpkg-query -W -f='${db:Status-Abbrev} ${Package} ${Version}\n' "php${V}*"
not_rebuilt=$(dpkg-query -W -f='${db:Status-Abbrev} ${Package} ${Version}\n' "php${V}*" \
  | awk -v s="$SUFFIX" '$1 == "ii" && $3 !~ ("\\+" s "$")')
[ -z "$not_rebuilt" ] || { echo "Not rebuilt: $not_rebuilt"; exit 1; }

echo "--- Extensions load"
"php${V}" -v
# Capture the list once: with pipefail, "php -m | grep -q" fails when grep exits before php stops writing.
modules=$("php${V}" -m)
for ext in $EXTENSIONS; do
  grep -qix "$ext" <<< "$modules" || { echo "Missing extension: $ext"; exit 1; }
done

echo "--- PHP-FPM serves a FastCGI request"
"php-fpm${V}" -t
mkdir -p /run/php /var/www
"php-fpm${V}" -D
for _ in $(seq 10); do [ -S "/run/php/php${V}-fpm.sock" ] && break; sleep 1; done
echo '<?php echo "fpm ok ", PHP_VERSION;' > /var/www/test.php
response=$(SCRIPT_FILENAME=/var/www/test.php REQUEST_METHOD=GET cgi-fcgi -bind -connect "/run/php/php${V}-fpm.sock")
echo "$response"
grep -q "fpm ok" <<< "$response"

echo "--- The upstream changelog lists the fixes"
# The Ubuntu image does not install /usr/share/doc, so read it from the package.
# The bracketed form only appears in the upstream entry, not in the one added by build.sh.
dpkg-deb --fsys-tarfile "$DEB_DIR/php${V}-common"_*.deb \
  | tar -xO "./usr/share/doc/php${V}-common/changelog.Debian.gz" \
  | gunzip | grep -F '[CVE-2026-109618, CVE-2026-109619]'
