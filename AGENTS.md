# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-20
**Commit:** 028b582
**Branch:** master

## OVERVIEW

Docker wrapper for [LosslessCut](https://github.com/mifi/lossless-cut) — wraps the pre-built binary in a container with web/VNC GUI access. **No source code**; pure infrastructure project.

## STRUCTURE

```
.
├── Dockerfile              # Multi-stage build (extract → final)
├── GNUmakefile             # Build automation (make build/buildx/push)
├── docker-compose.yaml     # Example compose config
├── .github/workflows/      # CI (ci.yaml) + CD (build-and-deploy.yaml)
└── helper-scripts/         # Dev utilities (dependency extraction)
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Modify container build | `Dockerfile` |
| Add/change dependencies | `Dockerfile` lines 45-126, use `helper-scripts/generate_dependencies_list.bash` |
| Change build tags/registry | `GNUmakefile` lines 8-13 |
| Modify CI triggers | `.github/workflows/ci.yaml` lines 9-18 |
| Modify CD deployment | `.github/workflows/build-and-deploy.yaml` |
| Runtime env vars | `README.md` lines 93-115 |
| Startup command | `Dockerfile` line 140: `/LosslessCut/losslesscut --no-sandbox` |

## CONVENTIONS

**Build System:**
- Multi-stage: `extract-stage` downloads binary → `final-stage` runtime
- Base image: `jlesage/baseimage-gui:debian-12-v4`
- Platform detection via `TARGETPLATFORM` (BuildKit) — **never set default**
- Versioning: `app_version` (LosslessCut) + `image_revision` (container bump)

**Tagging:**
- 7 tags per build: `:latest`, `:X.Y.Z`, `:X.Y`, `:X`, plus `-vN` revision suffixes
- Dual registry: GHCR + Docker Hub

**Makefile Patterns:**
- `make build` — single platform
- `make buildx` — multi-platform (amd64, arm/v7, arm64)
- `make push` — build + push to registries

## ANTI-PATTERNS (THIS PROJECT)

| Pattern | Why Forbidden |
|---------|---------------|
| Setting `TARGETPLATFORM` default | Breaks multi-arch builds (Dockerfile line 8-9) |
| Removing `--no-sandbox` | Electron sandbox fails in container |
| VNC password >8 chars | RFC 6143 limitation, truncated silently |
| Building without BuildKit | `TARGETPLATFORM` won't be set |

## UNIQUE STYLES

- **No application code** — downloads pre-built LosslessCut binary
- **Makefile for Docker** — unusual but simplifies complex `buildx` commands
- **ARM ffmpeg workaround** — symlinks system ffmpeg if missing (Dockerfile lines 133-136)
- **Dual registry deployment** — simultaneously pushes to GHCR + Docker Hub

## COMMANDS

```bash
# Local build (current platform)
make build

# Multi-platform build (all archs)
make buildx

# Build and push to registries
make push REGISTRY=docker.io IMAGE_NAME=outlyernet/losslesscut

# Run locally
docker run -d -p 5800:5800 -v $HOME:/storage outlyernet/losslesscut

# Shell into container
docker exec -ti losslesscut sh

# Generate dependency list (after ldd analysis)
./helper-scripts/generate_dependencies_list.bash /LosslessCut/losslesscut
```

## NOTES

- **Ports**: 5800 (web GUI), 5900 (VNC)
- **Volumes**: `/config` (persistent state), `/storage` (host files)
- **Base image docs**: https://github.com/jlesage/docker-baseimage-gui
- **CI builds on push** (excluding docs); **CD deploys on semver tags**