# Build stage — no Node.js needed; web assets are downloaded from GitHub releases.
# libheif is added to enable HEIC/HEIF thumbnail generation via libvips.

FROM owncloudci/golang:1.25 AS build

COPY ./ /ocis/

WORKDIR /ocis/ocis

# Install libvips + libheif dev headers so govips links against libheif
RUN apk add --no-cache \
    vips-dev \
    libheif-dev \
    build-base

# Download pre-built web UI assets (replaces the Node.js generate stage)
RUN make pull-assets

# Build the oCIS binary with vips support enabled
RUN make ci-go-generate build ENABLE_VIPS=true

# ── Runtime image ──────────────────────────────────────────────────────────
FROM alpine:3.23.4

RUN apk add --no-cache attr ca-certificates curl mailcap tree \
    && apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community "vips=8.18.2-r0" \
    # libheif enables HEIC/HEIF decoding in libvips
    && apk add --no-cache libheif \
    && echo 'hosts: files dns' >| /etc/nsswitch.conf

LABEL maintainer="ownCloud GmbH <devops@owncloud.com>" \
	org.label-schema.name="ownCloud Infinite Scale (HEIC/HEIF patched)" \
	org.label-schema.vendor="ownCloud GmbH" \
	org.label-schema.schema-version="1.0"

ENTRYPOINT ["/usr/bin/ocis"]
CMD ["server"]

COPY --from=build /ocis/ocis/bin/ocis /usr/bin/ocis
