#!/usr/bin/env bash
TAG=$(openssl rand -base64 128 | tr -dc 'a-z')
echo "tagging as $TAG"
./dockersafebuild -t $TAG
docker cp $(docker start $(docker create $TAG)):/home/builder/linux-hardened ./
