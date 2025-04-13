FROM ghcr.io/glassrom/os-image-updater:master

#LABEL maintainer=""

RUN rm -fv /etc/ld.so.preload

RUN pacman-key --init && pacman-key --populate archlinux

RUN pacman -Syyuu git base-devel bc cpio gettext libelf pahole perl python rust rust-bindgen rust-src tar xz llvm clang lld polly rust graphviz imagemagick python-sphinx python-yaml texlive-latexextra --noconfirm

RUN useradd -m builder
RUN echo 'builder ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
USER builder

COPY --chown=builder:builder . /home/builder/linux-hardened
WORKDIR /home/builder/linux-hardened
RUN /bin/bash makepkg.sh

USER root
RUN rm -rf /etc/pacman.d/gnupg
