# LosslessCut Docker Container
# https://github.com/mifi/lossless-cut
# Base image: https://github.com/jlesage/docker-baseimage-gui
#
# 完全重构版本 - 2026-03-23
# - 使用最新基础镜像 v4.11.3
# - 简化构建流程
# - 仅支持 amd64 和 arm64（LosslessCut 3.68.0 不再提供 armv7l）

# =============================================================================
# Build Arguments
# =============================================================================

ARG APP_VERSION="3.68.0"
ARG IMAGE_REVISION="1"

# =============================================================================
# Stage 1: Download LosslessCut
# =============================================================================

FROM alpine:3.20 AS download-stage

ARG TARGETPLATFORM
ARG APP_VERSION

# Fail early if TARGETPLATFORM isn't set
RUN test -n "${TARGETPLATFORM}"

# Download LosslessCut
# Architecture mapping: linux/amd64 -> x64, linux/arm64 -> arm64
RUN set -eux \
    && apk add --no-cache ca-certificates wget \
    && ARCH=$(case "${TARGETPLATFORM}" in \
        linux/amd64) echo "x64"   ;; \
        linux/arm64) echo "arm64" ;; \
        *) echo "Unsupported: ${TARGETPLATFORM}" >&2; exit 1 ;; \
    esac) \
    && URL="https://github.com/mifi/lossless-cut/releases/download/v${APP_VERSION}/LosslessCut-linux-${ARCH}.tar.bz2" \
    && wget -q -O /losslesscut.tar.bz2 "${URL}" \
    && mkdir -p /LosslessCut \
    && tar -xjf /losslesscut.tar.bz2 -C /LosslessCut --strip-components=1 \
    && rm -f /losslesscut.tar.bz2 \
    && ls -la /LosslessCut

# =============================================================================
# Stage 2: Final Runtime Image
# =============================================================================

FROM jlesage/baseimage-gui:debian-12-v4.11.3

ARG APP_VERSION
ARG IMAGE_REVISION

# -----------------------------------------------------------------------------
# Install Runtime Dependencies
# -----------------------------------------------------------------------------

RUN set -eux \
    && add-pkg \
        libasound2 \
        libatk1.0-0 \
        libatk-bridge2.0-0 \
        libatspi2.0-0 \
        libcairo2 \
        libcups2 \
        libdbus-1-3 \
        libdrm2 \
        libgbm1 \
        libgtk-3-0 \
        libnspr4 \
        libnss3 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxkbcommon0 \
        libxrandr2 \
        xdg-utils \
        ffmpeg \
        fonts-liberation \
        fonts-noto-color-emoji \
        librsvg2-bin

# -----------------------------------------------------------------------------
# Copy LosslessCut Binary
# -----------------------------------------------------------------------------

COPY --from=download-stage /LosslessCut /LosslessCut

# Symlink ffmpeg if needed (ARM builds may not include it)
RUN set -eux \
    && if [ ! -x /LosslessCut/resources/ffmpeg ]; then \
        ln -sf /usr/bin/ffmpeg /LosslessCut/resources/ffmpeg; \
        ln -sf /usr/bin/ffprobe /LosslessCut/resources/ffprobe; \
    fi

# -----------------------------------------------------------------------------
# Application Startup Script
# -----------------------------------------------------------------------------

RUN set -eux \
    && printf '%s\n' \
        '#!/bin/sh' \
        'exec /LosslessCut/losslesscut --no-sandbox "$@"' \
        > /startapp.sh \
    && chmod +x /startapp.sh

# -----------------------------------------------------------------------------
# Set Application Info (using set-cont-env helper)
# -----------------------------------------------------------------------------

RUN set-cont-env APP_NAME "LosslessCut"
RUN set-cont-env APP_VERSION "${APP_VERSION}"
RUN set-cont-env DOCKER_IMAGE_VERSION "${IMAGE_REVISION}"

# -----------------------------------------------------------------------------
# Application Icon
# -----------------------------------------------------------------------------

RUN install_app_icon.sh "https://raw.githubusercontent.com/mifi/lossless-cut/master/src/renderer/src/icon.svg"

# -----------------------------------------------------------------------------
# Volumes and Ports
# -----------------------------------------------------------------------------

VOLUME ["/config", "/storage"]
EXPOSE 5800 5900

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------

ENV HOME=/storage

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------

LABEL \
    maintainer="napoler" \
    org.opencontainers.image.title="Dockerized LosslessCut" \
    org.opencontainers.image.description="LosslessCut via web browser and VNC" \
    org.opencontainers.image.version="${APP_VERSION}" \
    org.opencontainers.image.url="https://github.com/napoler/docker-losslesscut" \
    org.opencontainers.image.source="https://github.com/napoler/docker-losslesscut"