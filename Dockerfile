FROM --platform=$BUILDPLATFORM rust:alpine AS builder-amd64
ENV TARGET=x86_64-unknown-linux-musl
RUN apk add --upgrade --no-cache ca-certificates pkgconfig openssl-dev build-base libffi-dev perl make

WORKDIR /usr/src/tado-exporter

COPY Cargo.* .
COPY src/ ./src


FROM messense/rust-musl-cross:aarch64-musl AS builder-arm64
ENV TARGET=aarch64-unknown-linux-musl

RUN apk add --no-cache ca-certificates

WORKDIR /usr/src/tado-exporter

COPY Cargo.* .
COPY src/ ./src

#ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc CC_aarch64_unknown_linux_gnu=aarch64-linux-gnu-gcc CXX_aarch64_unknown_linux_gnu=aarch64-linux-gnu-gcc

FROM builder-$TARGETARCH$TARGETVARIANT as final-builder
RUN rustup target add ${TARGET}
RUN cargo build --target ${TARGET} --release --target-dir /build && \
    cp /build/$TARGET/release/tado-exporter /tado-exporter_$TARGETARCH$TARGETVARIANT&& \
    rm -rf /build/${TARGET}

FROM --platform=$TARGETPLATFORM alpine:latest
LABEL name="tado-exporter"

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG TARGETPLATFORM
ARG BUILDOS
ARG BUILDARCH
ARG BUILDVARIANT
ARG BUILDPLATFORM
ARG USERNAME=tado-exporter
ARG USER_UID=1000
ARG USER_GID=1000

RUN echo "I'm building for $TARGETOS/$TARGETARCH/$TARGETVARIANT"
RUN echo "I'm building on $BUILDOS/$BUILDARCH/$BUILDVARIANT"

RUN echo "builder-$TARGETARCH$TARGETVARIANT"

RUN apk add --upgrade --no-cache wget

COPY --from=final-builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=final-builder /tado-exporter_$TARGETARCH$TARGETVARIANT /usr/bin/tado-exporter

# Create the user
RUN addgroup -g $USER_GID $USERNAME && adduser -D -H -u $USER_UID -G $USERNAME $USERNAME

RUN chmod 755 /usr/bin/tado-exporter && chown tado-exporter:tado-exporter /usr/bin/tado-exporter

USER $USERNAME

CMD ["tado-exporter"]
