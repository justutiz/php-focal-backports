# AGENTS.md

## Purpose

Rebuild ondrej/php jammy (Ubuntu 22.04) source packages for focal (Ubuntu 20.04, amd64) and publish the `.deb` files as GitHub Actions artifacts.

## Files

- `build.sh`: builds one source package. Arguments: `<source> <jammy-version-without-epoch> <new-version>`. Writes `.deb` files to `$OUT_DIR` (default `./out`).
- `.github/workflows/build.yml`: runs `build.sh` once per matrix entry inside `ubuntu:20.04`, uploads `out/*.deb` as the `<source>-focal-amd64` artifact.
- `README.md`: human documentation, including the server install steps.

## Conventions

- The jammy version in the matrix has no epoch, because Launchpad file names omit it. The new version keeps the epoch when the source has one (php8.0 and php7.4 use `1:`).
- New versions use the suffix `+ubuntu20.04.1+backportN`. Increment `N` for every rebuild of the same base version so `dpkg` treats it as an upgrade.
- To add a newer base version, change `jammy_version` and `new_version` in the matrix and reset the suffix to `+backport1`.
- Keep the README table in sync with the workflow matrix.

## Do not

- Do not add client names, server hostnames, or credentials. The repository is public.
- Do not run the PHP test suite in CI (`nocheck`); it takes hours and is not needed for a rebuild of tested sources.
- Do not build for other Ubuntu releases; they receive patched packages through `apt`.
- Do not pin actions to branches; use released major tags.
