# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) relative to the bundled LosslessCut version.

## [Unreleased]

### Fixed
- Fixed Makefile variable extraction (Dockerfile uses uppercase `ARG APP_VERSION`, Makefile now greps correctly)
- Removed arm/v7 from multi-platform build targets (LosslessCut >= 3.68.0 no longer provides armv7l binaries)
- Removed armv7l detection from platform auto-detection in Makefile

### Changed
- Upgraded GitHub Actions: `actions/checkout` v3→v4, `docker/login-action` v3→v4, `docker/build-push-action` v5→v6
- Updated CI/CD runners from `ubuntu-22.04` to `ubuntu-latest`
- Fixed docker-compose.yaml: added missing `/config` volume, removed redundant `$HOME` mount, safe fallback for `${HOME}`
- Removed deprecated `version: '3'` from README.md compose examples
- Removed stale FIXME and TODO comments from CI/CD workflows
- Removed `.github/workflows/*` and `helper-scripts/*` from CI paths-ignore
- Added `.editorconfig` for consistent coding styles
