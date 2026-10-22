# php-focal-backports

Rebuilds of the [ondrej/php](https://launchpad.net/~ondrej/+archive/ubuntu/php) PHP 8.1 and PHP 7.4 packages for **Ubuntu 20.04 (focal), amd64**.

## Why

On 2026-10-21 PHP released fixes for two critical remote code execution vulnerabilities, CVE-2026-109618 and CVE-2026-109619 ([advisory](https://www.php.net/archive/2026.php#2026-10-21-5)). The ondrej/php PPA ships patched PHP 8.1 and 7.4 packages, but only for Ubuntu 22.04 and later, because it no longer publishes for Ubuntu 20.04. Servers that still run Ubuntu 20.04 with PHP from that PPA have no patched package available.

This repository takes the patched Ubuntu 22.04 source packages and rebuilds them on Ubuntu 20.04. The result is a drop-in upgrade for servers that already use the ondrej/php packages on Ubuntu 20.04.

| Source package | Based on (jammy) | Built version |
|---|---|---|
| php8.1 | 8.1.34-9 | 8.1.34-9+ubuntu20.04.1+backport1 |
| php7.4 | 1:7.4.33-31 | 1:7.4.33-31+ubuntu20.04.1+backport1 |

Both base versions include the fixes for CVE-2026-109618 and CVE-2026-109619, plus earlier security fixes.

## How it works

The GitHub Actions workflow (`.github/workflows/build.yml`) runs on every push to `main` and on manual dispatch. For each source package it runs `build.sh` inside an `ubuntu:20.04` container, which:

1. Downloads the jammy source package from Launchpad.
2. Installs the build dependencies.
3. Sets a new version with a `+backport1` suffix.
4. Builds the binary packages without running the test suite.

The `.deb` files are published as workflow artifacts (`php8.1-focal-amd64` and `php7.4-focal-amd64`).

## Installing on a server

These packages only work on **Ubuntu 20.04, amd64**, on servers that already use the ondrej/php PPA.

1. Check the server: `uname -m` must print `x86_64` and `lsb_release -ds` must print Ubuntu 20.04.
2. List the installed PHP packages: `dpkg -l 'php*' | awk '/^ii/{print $2, $3}'`.
3. Download the artifact from the latest successful workflow run and copy to the server only the `.deb` files whose package names are already installed.
4. Install them together, then restart PHP-FPM (or Apache if it uses `mod_php`):

   ```bash
   sudo dpkg -i php8.1-*.deb
   sudo systemctl restart php8.1-fpm
   ```

5. Verify the installed version: `dpkg -s php8.1-cli | grep Version` must show `+backport1`.

Extensions shipped as separate source packages (for example `php8.1-imagick` or `php8.1-redis`) are not rebuilt and keep working, because the PHP API version does not change.

## Limitations

- Ubuntu 20.04 amd64 only. A `.deb` links against the libraries of the release it was built on, so these packages do not install on other releases. Ubuntu 22.04 and later already receive patched packages through `apt`.
- These are unofficial rebuilds. Plan the upgrade to a supported Ubuntu release and PHP version.
