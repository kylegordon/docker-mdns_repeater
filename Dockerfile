# Build stage - compile mdns-repeater
FROM gcc:latest AS builder
ADD mdns-repeater.c /build/mdns-repeater.c
WORKDIR /build
RUN gcc -O3 -o mdns-repeater mdns-repeater.c -DHGVERSION="\"1\""

# Final stage - lightweight Alpine  
FROM alpine:3.19

# Copy compiled mdns-repeater from builder
COPY --from=builder /build/mdns-repeater /bin/mdns-repeater

# Add Docker CLI with API 1.44+ support from official static binaries
# Docker 27.x supports API version 1.46 which is compatible with daemons requiring 1.44+
ADD docker/docker /usr/local/bin/docker

COPY entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh
#ENV options="" hostNIC=eth0 dockerNIC=docker_gwbridge

#CMD mdns-repeater -f ${options} ${hostNIC} ${dockerNIC}

ENTRYPOINT [ "/entrypoint.sh" ]
