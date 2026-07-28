# Installs the built .pkg.tar.zst into a clean Arch Linux image and runs the
# shared assertion suite. Build context must be the repo root.
#
#   docker build -f tests/docker/archlinux.Dockerfile -t lyra-install-test:archlinux .
FROM archlinux:base

RUN pacman -Syu --noconfirm

COPY packages/arch/lyra/lyra-*.pkg.tar.zst /tmp/lyra.pkg.tar.zst
RUN pacman -U --noconfirm /tmp/lyra.pkg.tar.zst

COPY tests/cases/assertions.sh /assertions.sh
RUN chmod +x /assertions.sh

CMD ["/assertions.sh"]
