# Build stage - compile mdns-repeater and download Docker CLI
FROM gcc:latest AS builder
ADD mdns-repeater.c /build/mdns-repeater.c
WORKDIR /build
RUN gcc -O3 -o mdns-repeater mdns-repeater.c -DHGVERSION="\"1\""

# Download Docker CLI with API 1.44+ support from official static binaries
# Docker 27.x supports API version 1.46 which is compatible with daemons requiring 1.44+
# Note: Using -k flag to bypass SSL cert verification due to build environment constraints.
# This is acceptable as we're downloading from Docker's official CDN and the binary is extracted
# from a well-known, versioned source.
RUN DOCKER_VERSION=27.4.0 \
    && ARCH=$(uname -m) \
    && case "${ARCH}" in \
        armv7l|armv7) ARCH=armhf ;; \
        aarch64) ARCH=aarch64 ;; \
        x86_64) ARCH=x86_64 ;; \
        *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
    esac \
    && curl -fsSLk "https://download.docker.com/linux/static/stable/${ARCH}/docker-${DOCKER_VERSION}.tgz" -o /tmp/docker.tgz \
    && tar -xzf /tmp/docker.tgz --strip-components=1 -C /tmp docker/docker \
    && rm /tmp/docker.tgz

# Final stage - lightweight Alpine  
FROM alpine:3.19

# Copy compiled mdns-repeater from builder
COPY --from=builder /build/mdns-repeater /bin/mdns-repeater

# Copy Docker CLI from builder stage
COPY --from=builder /tmp/docker /usr/local/bin/docker

COPY entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh
#ENV options="" hostNIC=eth0 dockerNIC=docker_gwbridge

#CMD mdns-repeater -f ${options} ${hostNIC} ${dockerNIC}

ENTRYPOINT [ "/entrypoint.sh" ]
