ARG ALPINE_VERSION="3.22"

FROM scratch AS bin-folder

FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS releaser
RUN apk add --no-cache bash
WORKDIR /out
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
RUN --mount=from=bin-folder,source=.,target=/release <<EOT
  set -e
  for f in /release/*; do
    pkgtype=$(basename $f)
    if [ "$pkgtype" = "static" ]; then
      basedir="${TARGETOS}/${TARGETARCH}"
      if [ -n "$TARGETVARIANT" ]; then
        basedir="${basedir}/${TARGETVARIANT}"
      fi
      [ ! -d "${f}/${basedir}" ] && continue
      (
        set -x
        mkdir -p "/out/static/${basedir}"
        cp "${f}/${basedir}"/* "/out/static/${basedir}/"
      )
    else
      [ "${TARGETOS}" != "linux" ] && continue
      for ff in ${f}/*; do
        pkgrelease=$(basename $ff)
        basedir="${TARGETARCH}"
        if [ -n "$TARGETVARIANT" ]; then
          basedir="${basedir}/${TARGETVARIANT}"
        fi
        [ ! -d "${ff}/${basedir}" ] && continue
        (
          set -x
          mkdir -p "/out/${pkgtype}/${pkgrelease}/${basedir}"
          cp "${ff}/${basedir}"/* "/out/${pkgtype}/${pkgrelease}/${basedir}/"
        )
      done
    fi
  done
  if [ -d "/out" ] && [ -f "/release/metadata.env" ]; then
    cp "/release/metadata.env" "/out/"
  fi
EOT

FROM scratch AS release
COPY --from=releaser /out /
