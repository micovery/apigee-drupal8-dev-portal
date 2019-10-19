#!/usr/bin/env bash


export KICKSTART_VERSION=${KICKSTART_VERSION:-8.x-dev}

export REPOSITORY=micovery/apigee-drupal8-dev-portal
export TAG=${KICKSTART_VERSION:-latest}

docker build \
      --build-arg KICKSTART_VERSION=${KICKSTART_VERSION} \
      -t ${REPOSITORY}:${TAG}  \
      -t ${REPOSITORY}:latest .
