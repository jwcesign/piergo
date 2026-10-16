# syntax=docker/dockerfile:1
ARG DEBIAN_IMAGE=debian:13-slim
ARG NODE_IMAGE=node:22.22.0-bookworm-slim
FROM ${NODE_IMAGE} AS node
FROM ${DEBIAN_IMAGE} AS downloads

RUN apt-get update && apt-get -o Acquire::Retries=3 install -y --no-install-recommends \
    ca-certificates curl jq && rm -rf /var/lib/apt/lists/*
ARG CUA_SPACESD_VERSION=0.5.3
ARG CUA_DRIVER_VERSION=0.35.4
ARG BROWSEROS_VERSION=0.51.1.2
RUN <<'EOF'
set -eu
download() {
    repository=$1
    tag=$(jq -nr --arg tag "$2" '$tag | @uri')
    asset=$3
    output=$4
    curl -fsSL --retry 3 --max-time 60 \
        "https://api.github.com/repos/$repository/releases/tags/$tag" > /tmp/release.json
    digest=$(jq -er --arg name "$asset" '.assets[] | select(.name == $name) |
        .digest | select(test("^sha256:[a-f0-9]{64}$"))' /tmp/release.json)
    url=$(jq -r --arg name "$asset" '.assets[] | select(.name == $name) | .browser_download_url' /tmp/release.json)
    curl -fL --retry 3 --connect-timeout 20 --max-time 900 "$url" -o "$output"
    printf '%s  %s\n' "${digest#sha256:}" "$output" | sha256sum -c -
}
mkdir /artifacts
download trycua/cua "cua-spacesd-v$CUA_SPACESD_VERSION" cua-spacesd-x86_64-unknown-linux-gnu /artifacts/cua-spacesd
download trycua/cua "cua-driver-rs-v$CUA_DRIVER_VERSION" "cua-driver-rs-$CUA_DRIVER_VERSION-linux-x86_64-binary.tar.gz" /tmp/cua-driver.tar.gz
tar -xOzf /tmp/cua-driver.tar.gz cua-driver > /artifacts/cua-driver
download browseros-ai/BrowserOS "browserclaw/v$BROWSEROS_VERSION" "BrowserOS_neo_v${BROWSEROS_VERSION}_amd64.deb" /artifacts/BrowserOS.deb
chmod 755 /artifacts/cua-driver /artifacts/cua-spacesd
EOF

FROM ${DEBIAN_IMAGE}

ARG TARGETARCH
RUN test "$TARGETARCH" = amd64
ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8

COPY --from=node /usr/local/ /usr/local/
RUN apt-get update && apt-get -o Acquire::Retries=3 install -y --no-install-recommends \
    ca-certificates curl git sudo procps iproute2 \
    xfce4 xfce4-terminal xvfb x11-utils x11-xserver-utils xauth \
    dbus dbus-x11 dbus-user-session at-spi2-core libatk-adaptor \
    libxi6 libxtst6 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 \
    libsecret-1-0 fonts-liberation fonts-noto-cjk xdg-utils \
    pipewire pipewire-pulse wireplumber pulseaudio-utils \
    && rm -rf /var/lib/apt/lists/*

COPY --from=downloads /artifacts/BrowserOS.deb /tmp/BrowserOS.deb
RUN apt-get update && apt-get -o Acquire::Retries=3 install -y --no-install-recommends /tmp/BrowserOS.deb \
    && rm -rf /var/lib/apt/lists/* /tmp/BrowserOS.deb
ARG CODEX_VERSION=0.162.1
RUN npm install --global "@openai/codex@${CODEX_VERSION}" && npm cache clean --force
COPY --from=downloads --chmod=0755 /artifacts/cua-spacesd /artifacts/cua-driver /usr/local/bin/

RUN useradd --create-home --uid 1000 --shell /bin/bash --groups audio,video cua \
    && install -d -o cua -g cua /home/cua/workspace
USER cua
WORKDIR /home/cua/workspace
CMD ["bash"]
