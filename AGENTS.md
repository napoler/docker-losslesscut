# PROJECT KNOWLEDGE BASE

**Generated:** 2026-06-29
**Commit:** 90c4266
**Branch:** master

## OVERVIEW

Docker wrapper for [LosslessCut](https://github.com/mifi/lossless-cut) — wraps the pre-built binary in a container with web/VNC GUI access. **No source code**; pure infrastructure project.

## STRUCTURE

```
.
├── Dockerfile              # Multi-stage build (download → final)
├── GNUmakefile             # Build automation (make build/buildx/push)
├── docker-compose.yaml     # Example compose config
├── .github/workflows/      # CI (ci.yaml) + CD (build-and-deploy.yaml)
└── helper-scripts/         # Dev utilities (dependency extraction)
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Modify container build | `Dockerfile` |
| Add/change dependencies | `Dockerfile` lines 61-100, use `helper-scripts/generate_dependencies_list.bash` |
| Change build tags/registry | `GNUmakefile` lines 8-13 |
| Modify CI triggers | `.github/workflows/ci.yaml` lines 7-18 |
| Modify CD deployment | `.github/workflows/build-and-deploy.yaml` |
| Runtime env vars | `README.md` lines 158-184 |
| Startup command | `Dockerfile` line 127: `/LosslessCut/losslesscut --no-sandbox` |

## CONVENTIONS

**Build System:**
- Multi-stage: `download-stage` downloads binary → final-stage runtime
- Base image: `jlesage/baseimage-gui:debian-12-v4.11.3`
- Platform detection via `TARGETPLATFORM` (BuildKit) — **never set default**
- Versioning: `APP_VERSION` (LosslessCut) + `IMAGE_REVISION` (container bump)
- Supported platforms: amd64, arm64 (arm/v7 dropped since LosslessCut 3.68.0)

**Tagging:**
- 7 tags per build: `:latest`, `:X.Y.Z`, `:X.Y`, `:X`, plus `-vN` revision suffixes
- Dual registry: GHCR + Docker Hub
- Platforms: amd64, arm64 (arm/v7 dropped since LosslessCut 3.68.0)

**Makefile Patterns:**
- `make build` — single platform
- `make buildx` — multi-platform (amd64, arm64)
- `make push` — build + push to registries

## ANTI-PATTERNS (THIS PROJECT)

| Pattern | Why Forbidden |
|---------|---------------|
| Setting `TARGETPLATFORM` default | Breaks multi-arch builds (Dockerfile line 24) |
| Removing `--no-sandbox` | Electron sandbox fails in container |
| VNC password >8 chars | RFC 6143 limitation, truncated silently |
| Building without BuildKit | `TARGETPLATFORM` won't be set |

## UNIQUE STYLES

- **No application code** — downloads pre-built LosslessCut binary
- **Makefile for Docker** — unusual but simplifies complex `buildx` commands
- **ARM ffmpeg workaround** — symlinks system ffmpeg if missing (Dockerfile lines 115-118)
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
- **CI builds on push** (excluding docs and workflow files); **CD deploys on semver tags**
