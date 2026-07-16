# syntax=docker/dockerfile:1.7

ARG JELLYFIN_IMAGE=jellyfin/jellyfin:10.11.11@sha256:aefb67e6a7ff1debdd154a78a7bbb780fd0c873d8639210a7f6a2016ad2b35db

FROM ${JELLYFIN_IMAGE} AS seed

USER root
RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/plezy-demo
COPY scripts/maestro_fixtures.py scripts/maestro_real_jellyfin.py scripts/prepare_maestro_media.py ./
COPY .maestro/jellyfin-demo/seed.sh ./seed.sh

ARG PLEZY_DEMO_MEDIA_BASE_URL=https://demo-files.plezy.app/media-samples/
ARG PLEZY_DEMO_MEDIA_REVISION=2026-07-14
ARG PLEZY_DEMO_MEDIA_DURATION=300
RUN test -n "${PLEZY_DEMO_MEDIA_REVISION}" \
    && python3 maestro_real_jellyfin.py download-codecs \
        --base-url "${PLEZY_DEMO_MEDIA_BASE_URL}" \
        --output-dir /tmp/plezy-codecs \
    && PATH="/usr/lib/jellyfin-ffmpeg:${PATH}" python3 prepare_maestro_media.py \
        /tmp/plezy-codecs /tmp/plezy-codecs-prepared \
        --duration "${PLEZY_DEMO_MEDIA_DURATION}" \
        --extend av1_opus_ass_srt.mkv \
        --extend h264_eac3_multisub.mkv \
        --extend hevc10_flac_ass.mkv \
    && python3 maestro_real_jellyfin.py prepare \
        --output-dir /media \
        --codec-source-dir /tmp/plezy-codecs-prepared \
        --include-codecs \
    && rm -rf /tmp/plezy-codecs /tmp/plezy-codecs-prepared __pycache__ \
    && chmod -R a=rX /media

RUN ./seed.sh

FROM ${JELLYFIN_IMAGE}

LABEL org.opencontainers.image.title="Plezy Jellyfin demo server" \
      org.opencontainers.image.description="Ready-to-run Jellyfin server with Plezy's deterministic codec demo catalog" \
      org.opencontainers.image.source="https://github.com/edde746/plezy"

COPY --from=seed /media /media
COPY --from=seed /opt/plezy-demo/seed-config /opt/plezy-demo/seed-config
COPY .maestro/jellyfin-demo/entrypoint.sh /usr/local/bin/plezy-demo-entrypoint

RUN chmod 0755 /usr/local/bin/plezy-demo-entrypoint \
    && chmod -R a=rX /media /opt/plezy-demo/seed-config

ENV TZ=UTC \
    JELLYFIN_PublishedServerUrl=http://localhost:8096

EXPOSE 8096
STOPSIGNAL SIGTERM
ENTRYPOINT ["/usr/local/bin/plezy-demo-entrypoint"]
