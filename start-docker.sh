#!/usr/bin/env bash

docker run --rm -it \
           --publish 8080:80 \
           --name dev-portal \
           micovery/apigee-drupal8-dev-portal:latest