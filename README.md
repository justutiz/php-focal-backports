# php-focal-backports

Patched PHP packages for **Ubuntu 20.04 (focal), amd64**, rebuilt from the [ondrej/php](https://launchpad.net/~ondrej/+archive/ubuntu/php) PPA sources. They include the fixes for the critical remote code execution vulnerabilities **CVE-2026-109618** and **CVE-2026-109619** published on 2026-10-21.

| PHP | Built version | Based on (ondrej/php, Ubuntu 22.04) |
|---|---|---|
| 8.1 | `8.1.34-9+ubuntu20.04.1+backport1` | `8.1.34-9` |
| 8.0 | `1:8.0.30-25+ubuntu20.04.1+backport1` | `1:8.0.30-25` |
| 7.4 | `1:7.4.33-31+ubuntu20.04.1+backport1` | `1:7.4.33-31` |
| 7.3 | `7.3.33-35+ubuntu20.04.1+backport1` | `7.3.33-35` |
| 5.6 | `5.6.40-104+ubuntu20.04.1+backport1` | `5.6.40-104` |

## Why this exists

PHP's advisory ([php.net](https://www.php.net/archive/2026.php#2026-10-21-5)) fixes both CVEs in PHP 8.2 and later, and publishes minimal source backports for 8.1, 8.0 and 7.4. The ondrej/php PPA applies those fixes to every PHP version it maintains, but it no longer publishes packages for Ubuntu 20.04. Ubuntu 20.04 servers that run PHP from that PPA therefore have no patched package to install.

This repository takes the patched Ubuntu 22.04 source packages from the PPA and rebuilds them, unchanged, on Ubuntu 20.04. The only modification is the version number. Because the base versions are the latest ones, the packages also include every earlier security fix the PPA shipped after it stopped publishing for Ubuntu 20.04.

## Included packages

Every PHP version ships the same set of packages that the ondrej/php PPA builds from that source. Extensions maintained as separate source packages (for example `imagick`, `redis`, `memcached`, `xdebug` or `mongodb`) are not included. The extensions you already have installed keep working, because the PHP API version does not change within a minor release.

**Runtimes and SAPIs** (every version): `phpX.Y` (metapackage), `phpX.Y-cli`, `phpX.Y-fpm`, `phpX.Y-cgi`, `libapache2-mod-phpX.Y`, `phpX.Y-phpdbg`, `libphpX.Y-embed`, `phpX.Y-litespeed`, `phpX.Y-common`, `phpX.Y-dev`.

**Extensions** (every version): `bcmath`, `bz2`, `curl`, `dba`, `enchant`, `gd`, `gmp`, `imap`, `interbase`, `intl`, `ldap`, `mbstring`, `mysql`, `odbc`, `opcache`, `pgsql`, `pspell`, `readline`, `snmp`, `soap`, `sqlite3`, `sybase`, `tidy`, `xml`, `xsl`, `zip`.

**Extra extensions by version:**

| PHP | Extra packages |
|---|---|
| 8.1 | none |
| 8.0 | none |
| 7.4 | `json`, `xmlrpc` |
| 7.3 | `json`, `xmlrpc`, `recode` |
| 5.6 | `json`, `xmlrpc`, `recode`, `mcrypt` |

## Download

The packages are published in the [Releases](../../releases) page, one archive per PHP version (for example `php8.1-focal-amd64.tar.gz`), plus a `SHA256SUMS` file. Each archive also contains a `SHA256SUMS` file for its `.deb` files.

## Installation

Requirements:

- Ubuntu 20.04, `x86_64` (`uname -m`).
- PHP installed from the ondrej/php PPA (versions ending in `+deb.sury.org+1`), or Ubuntu's own `php7.4` packages (see below).

1. **List the PHP packages installed** on the server:

   ```bash
   dpkg -l 'php*' 'libapache2-mod-php*' | awk '/^ii/{print $2, $3}'
   ```

2. **Download and verify** the archive for your PHP version:

   ```bash
   curl -LO https://github.com/nanoarmando/php-focal-backports/releases/latest/download/php8.1-focal-amd64.tar.gz
   curl -LO https://github.com/nanoarmando/php-focal-backports/releases/latest/download/SHA256SUMS
   sha256sum --check --ignore-missing SHA256SUMS
   mkdir php8.1 && tar -xzf php8.1-focal-amd64.tar.gz -C php8.1
   ```

3. **Install only the packages that are already installed.** Installing extra packages pulls in dependencies you do not need. This command upgrades exactly the installed `php8.1*` packages:

   ```bash
   cd php8.1
   installed=$(dpkg-query -W -f='${Package} ${Status}\n' 'php8.1*' 'libapache2-mod-php8.1' 'libphp8.1-embed' 2>/dev/null | awk '/ installed$/{print $1}')
   debs=$(for p in $installed; do ls ${p}_*.deb 2>/dev/null; done)
   sudo dpkg -i $debs
   sudo apt-get -f install   # only if dpkg reports missing dependencies
   ```

4. **Restart the services** that run PHP:

   ```bash
   sudo systemctl restart php8.1-fpm      # PHP-FPM
   sudo systemctl restart apache2         # if Apache uses mod_php (libapache2-mod-php8.1)
   ```

5. **Verify** the installed version. It must end in `+backport1`:

   ```bash
   dpkg -s php8.1-common | grep Version
   ```

Repeat the steps for every PHP version installed on the server, replacing `8.1` with the version.

### Replacing Ubuntu's own php7.4

Ubuntu 20.04 ships its own `php7.4` packages (versions like `7.4.3-4ubuntu2.x`). The `php7.4` packages from this repository can replace them with the same steps: the epoch (`1:`) makes `dpkg` treat them as an upgrade, and Ubuntu's `php-common` (`2:75`) satisfies their `php-common (>= 1:81~)` dependency. After the upgrade the server runs PHP 7.4 from these rebuilds and keeps Ubuntu's `php-common` and metapackages such as `php-xml` or `php-mbstring`.

### Rolling back

Keep a copy of the current packages before installing, so you can reinstall them if needed:

```bash
sudo apt-get install --download-only --reinstall $(dpkg-query -W -f='${Package}=${Version} ' 'php8.1*')
ls /var/cache/apt/archives/php8.1*
```

If the PPA no longer serves your installed version, use `dpkg-repack` (from the `dpkg-repack` package) to rebuild `.deb` files from the installed packages.

## How the packages are built

The GitHub Actions workflow (`.github/workflows/build.yml`) runs on every push to `main` and on manual dispatch. For each PHP version it runs `build.sh` inside an `ubuntu:20.04` container, which:

1. Downloads the Ubuntu 22.04 source package from Launchpad.
2. Installs the build dependencies from the Ubuntu 20.04 archive.
3. Sets the new version with a `+backport1` suffix.
4. Builds the binary packages with `dpkg-buildpackage`, skipping the upstream test suite.

A final job packs each version into an archive and publishes it to the release.

## Limitations

- **Ubuntu 20.04, amd64 only.** A `.deb` links against the libraries of the release it was built on, so these packages do not install on other releases. Ubuntu 22.04 and later receive patched packages through `apt` from Ubuntu or the ondrej/php PPA.
- **Unofficial.** These are rebuilds of upstream sources by a third party, without the PPA's signatures. Review the workflow and verify the checksums before installing.
- **Temporary.** Ubuntu 20.04 and PHP 8.1 and older no longer receive regular security support. Plan the upgrade to a supported Ubuntu release and PHP version.

## License

The build scripts in this repository are provided as-is, without warranty. PHP is distributed under the PHP License and the Debian packaging under its own terms; see the `debian/copyright` file in each source package.
