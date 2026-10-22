# AGENTS.md

## Purpose

Rebuild ondrej/php Ubuntu 22.04 (jammy) PHP source packages for Ubuntu 20.04 (focal, amd64) and publish the `.deb` files as a GitHub release. The motivation is CVE-2026-109618 and CVE-2026-109619; the PPA no longer publishes for focal.

## Files

- `build.sh`: builds one source package. Arguments: `<source> <jammy-version-without-epoch> <new-version>`. Downloads the `.dsc` from Launchpad, installs build dependencies with `mk-build-deps`, sets the version with `dch --force-bad-version`, builds with `dpkg-buildpackage -b` and `nocheck`, and copies the `.deb` files to `$OUT_DIR` (default `./out`).
- `.github/workflows/build.yml`:
  - `build` job: one matrix entry per PHP version, runs `build.sh` inside `ubuntu:20.04`, uploads `out/*.deb` as the `<source>-focal-amd64` artifact.
  - `release` job: runs unless the run was cancelled, packs each artifact into `<source>-focal-amd64.tar.gz` with a `SHA256SUMS` inside, writes a top-level `SHA256SUMS`, and creates or updates the release `$RELEASE_TAG` (assets replaced with `--clobber`).
- `README.md`: public documentation: versions, included packages, download, installation, rollback, limitations.

## Conventions

- The jammy version in the matrix has no epoch, because Launchpad file names omit it. The new version keeps the epoch when the source has one (php8.0 and php7.4 use `1:`).
- New versions use the suffix `+ubuntu20.04.1+backportN`. `RELEASE_TAG` is `focal-backportN` and must match `N`.
- A rebuild that changes the packages (new base version or packaging fix) increments `N` in every matrix entry and in `RELEASE_TAG`, so `dpkg` treats it as an upgrade and the previous release stays available.
- To add a PHP version, add a matrix entry and update the README tables (versions and extra packages). Get the package list from the `Package:` lines of the source's `debian/control`.
- All repository content is in English.

## Do not

- Do not add client names, project names, server hostnames, IP addresses or credentials. The repository is public.
- Do not modify the upstream sources or packaging beyond the version number.
- Do not run the PHP test suite in CI (`nocheck`); it takes hours and is not needed for a rebuild of tested sources.
- Do not build for other Ubuntu releases; they receive patched packages through `apt`.
- Do not pin actions to branches; use released major tags verified as described in the workflow review process.
