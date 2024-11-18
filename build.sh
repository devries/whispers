#!/bin/sh

docker build --platform linux/amd64 -t devries/whispers:$(date +%Y%m%d) .
