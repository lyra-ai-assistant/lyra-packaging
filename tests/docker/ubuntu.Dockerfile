# Installs the built .deb into a clean Ubuntu image and runs the shared
# assertion suite. Build context must be the repo root so dist/ is visible.
#
#   docker build -f tests/docker/ubuntu.Dockerfile -t lyra-install-test:ubuntu .
#
# Tracks the minimum "Supported" distribution version per README.md — bump
# alongside README if the supported baseline changes.
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY dist/lyra_*.deb /tmp/lyra.deb
RUN apt-get update && apt-get install -y /tmp/lyra.deb && rm -rf /var/lib/apt/lists/*

COPY tests/cases/assertions.sh /assertions.sh
RUN chmod +x /assertions.sh

CMD ["/assertions.sh"]
