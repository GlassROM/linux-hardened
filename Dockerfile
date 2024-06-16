FROM ghcr.io/glassrom/os-image-docker:latest

#LABEL maintainer=""

RUN pacman-key --init && pacman-key --populate archlinux

RUN pacman -Syyuu git base-devel --noconfirm

RUN useradd -m builder
RUN echo 'builder ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
USER builder

COPY --chown=builder:builder . /home/builder/linux-hardened
WORKDIR /home/builder/linux-hardened
RUN makepkg -sf --noconfirm --skippgpcheck

RUN rm -rf /etc/pacman.d/gnupg
