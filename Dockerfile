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
        librsvg2-bin \
        locales \
        fontconfig \
        locales-all

# -----------------------------------------------------------------------------
# Configure Chinese Locale
# -----------------------------------------------------------------------------

# Generate zh_CN.UTF-8 locale for Chinese text support
RUN sed -i '/zh_CN.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen

# Install Chinese fonts (WenQuanYi Zen Hei for CJK)
RUN set -eux \
    && add-pkg \
        fonts-wqy-zenhei \
        fonts-wqy-microhei \
        fonts-noto-cjk

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
# Replace all non-executable cont-env.d files with executable scripts
# Workaround for overlayfs bug on some systems where non-executable
# files are incorrectly detected as executable
# -----------------------------------------------------------------------------

RUN set -eux \
    && for f in APP_NAME APP_VERSION DOCKER_IMAGE_VERSION DBUS_SESSION_BUS_ADDRESS \
        DOCKER_IMAGE_PLATFORM GTK_A11Y HOME NO_AT_BRIDGE TAKE_CONFIG_OWNERSHIP \
        XDG_CACHE_HOME XDG_CONFIG_HOME XDG_DATA_HOME XDG_RUNTIME_DIR XDG_STATE_HOME; do \
        rm -f /etc/cont-env.d/$f; \
    done \
    && printf '#!/bin/sh\necho LosslessCut' > /etc/cont-env.d/APP_NAME && chmod +x /etc/cont-env.d/APP_NAME \
    && printf '#!/bin/sh\necho %s' "${APP_VERSION}" > /etc/cont-env.d/APP_VERSION && chmod +x /etc/cont-env.d/APP_VERSION \
    && printf '#!/bin/sh\necho %s' "${IMAGE_REVISION}" > /etc/cont-env.d/DOCKER_IMAGE_VERSION && chmod +x /etc/cont-env.d/DOCKER_IMAGE_VERSION \
    && printf '#!/bin/sh\necho unix:path=/tmp/dbus.base' > /etc/cont-env.d/DBUS_SESSION_BUS_ADDRESS && chmod +x /etc/cont-env.d/DBUS_SESSION_BUS_ADDRESS \
    && printf '#!/bin/sh\necho linux/amd64' > /etc/cont-env.d/DOCKER_IMAGE_PLATFORM && chmod +x /etc/cont-env.d/DOCKER_IMAGE_PLATFORM \
    && printf '#!/bin/sh\necho none' > /etc/cont-env.d/GTK_A11Y && chmod +x /etc/cont-env.d/GTK_A11Y \
    && printf '#!/bin/sh\necho' > /etc/cont-env.d/HOME && chmod +x /etc/cont-env.d/HOME \
    && printf '#!/bin/sh\necho 1' > /etc/cont-env.d/NO_AT_BRIDGE && chmod +x /etc/cont-env.d/NO_AT_BRIDGE \
    && printf '#!/bin/sh\necho 1' > /etc/cont-env.d/TAKE_CONFIG_OWNERSHIP && chmod +x /etc/cont-env.d/TAKE_CONFIG_OWNERSHIP \
    && printf '#!/bin/sh\necho /config/xdg/cache' > /etc/cont-env.d/XDG_CACHE_HOME && chmod +x /etc/cont-env.d/XDG_CACHE_HOME \
    && printf '#!/bin/sh\necho /config/xdg/config' > /etc/cont-env.d/XDG_CONFIG_HOME && chmod +x /etc/cont-env.d/XDG_CONFIG_HOME \
    && printf '#!/bin/sh\necho /config/xdg/data' > /etc/cont-env.d/XDG_DATA_HOME && chmod +x /etc/cont-env.d/XDG_DATA_HOME \
    && printf '#!/bin/sh\necho /tmp/run/user/app' > /etc/cont-env.d/XDG_RUNTIME_DIR && chmod +x /etc/cont-env.d/XDG_RUNTIME_DIR \
    && printf '#!/bin/sh\necho /config/xdg/state' > /etc/cont-env.d/XDG_STATE_HOME && chmod +x /etc/cont-env.d/XDG_STATE_HOME

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
ENV LANG=zh_CN.UTF-8
ENV LC_ALL=zh_CN.UTF-8

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