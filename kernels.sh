#!/usr/bin/env bash
docker pull ghcr.io/glassrom/linux-hardened:main
cosign verify 'ghcr.io/glassrom/linux-hardened:master' --certificate-identity https://github.com/GlassROM/linux-hardened/.github/workflows/docker-publish.yml@refs/heads/master --certificate-oidc-issuer https://token.actions.githubusercontent.com || exit $?
container=$(docker create ghcr.io/glassrom/linux-hardened:main)
docker cp /home/builder/linux-hardened ./
docker rm $container
