#!/bin/sh

tag=$(date +%Y%m%d)

docker build --platform linux/amd64 -t devries/whispers:$tag .
docker tag devries/whispers:$tag devries/whispers:latest
docker push devries/whispers:$tag
docker push devries/whispers:latest
