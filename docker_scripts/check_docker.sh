#!/bin/bash
set -e # Exit if any command fails


# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Check if docker is installed
if ! [ docker ]; then
  echo 'Error: docker is not installed.' >&2
  exit 1
fi

# Check if Docker Compose is installed (supporting both `docker-compose` and `docker compose`)
if ! docker compose version &> /dev/null && ! docker-compose version &> /dev/null; then
  echo 'Error: Docker Compose is not installed.' >&2
  exit 1
fi


# Echo docker version and docker compose version
docker --version