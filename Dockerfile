ARG LICENSE_TYPE="apache"
ARG LICENSE_COPYRIGHT_HOLDER="KhulnaSoft dockerize authors"
ARG LICENSE_FILES=".*\(Dockerfile\|\.go\|\.hcl\|\.mk\|\.sh\)"

FROM ghcr.io/google/addlicense:v1.0.0 AS addlicense

FROM alpine:3.22 AS base
WORKDIR /src
RUN apk add --no-cache cpio findutils git

FROM base AS license-set
ARG LICENSE_TYPE
ARG LICENSE_COPYRIGHT_HOLDER
ARG LICENSE_FILES
RUN --mount=type=bind,target=.,rw \
    --mount=from=addlicense,source=/app/addlicense,target=/usr/bin/addlicense \
    find . -regex "${LICENSE_FILES}" | xargs addlicense -v -c "${LICENSE_COPYRIGHT_HOLDER}" -l "${LICENSE_TYPE}" \
    && mkdir /out \
    && find . -regex "${LICENSE_FILES}" | cpio -pdm /out

FROM scratch AS license-update
COPY --from=license-set /out /

FROM base AS license-validate
ARG LICENSE_TYPE
ARG LICENSE_COPYRIGHT_HOLDER
ARG LICENSE_FILES
RUN --mount=type=bind,target=. \
    --mount=from=addlicense,source=/app/addlicense,target=/usr/bin/addlicense \
    find . -regex "${LICENSE_FILES}" | xargs addlicense -v -check -c "${LICENSE_COPYRIGHT_HOLDER}" -l "${LICENSE_TYPE}"