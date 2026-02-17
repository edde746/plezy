# Snapshot libs from the runtime (not SDK) — this is what's actually on the Steam Deck.
FROM registry.gitlab.steamos.cloud/steamrt/sniper/platform:latest AS runtime-snapshot
RUN find /lib /usr/lib -name '*.so*' -type f -o -type l 2>/dev/null | xargs -r basename -a | sort -u > /steam-rt-libs.txt

FROM registry.gitlab.steamos.cloud/steamrt/sniper/sdk:latest
COPY --from=runtime-snapshot /steam-rt-libs.txt /steam-rt-libs.txt

# ─── Layer 1: apt deps (cached unless this block changes) ─────────────────────
RUN apt-get update -qq && apt-get install -y -qq \
  clang cmake meson ninja-build pkg-config nasm git curl unzip xz-utils \
  libgtk-3-dev libevdev-dev liblzma-dev \
  libasound2-dev libass-dev libfreetype-dev libfontconfig-dev libfribidi-dev libharfbuzz-dev \
  libepoxy-dev libegl-dev libgl-dev libgnutls28-dev \
  libpipewire-0.3-dev libva-dev libvdpau-dev \
  libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxi-dev libxss-dev libxpresent-dev \
  libxkbcommon-dev libpulse-dev libdbus-1-dev libdrm-dev libgbm-dev \
  libwayland-dev wayland-protocols liblcms2-dev python3-pip \
  && pip3 install meson --upgrade \
  && rm -rf /var/lib/apt/lists/*

# ─── Layer 2: libmpv (cached unless build-libmpv.sh changes) ──────────────────
WORKDIR /build
COPY linux/packaging/build-libmpv.sh linux/packaging/
RUN bash linux/packaging/build-libmpv.sh

# ─── Layer 3: Flutter SDK (cached unless Flutter channel changes) ──────────────
RUN git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:$PATH"
RUN flutter --disable-analytics \
  && flutter config --no-cli-animations \
  && flutter precache --linux

# ─── Layer 4: App build (runs on every source change) ─────────────────────────
COPY . /app
WORKDIR /app
ENV PKG_CONFIG_PATH="/build/libmpv-prefix/lib/pkgconfig:/build/libmpv-prefix/lib/x86_64-linux-gnu/pkgconfig"
RUN flutter pub get \
  && flutter build linux --release

# ─── Layer 5: Bundle assembly + dep bundling ──────────────────────────────────
RUN bash scripts/bundle_steam.sh
