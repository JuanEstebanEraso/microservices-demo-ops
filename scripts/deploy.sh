#!/bin/bash
set -e

IMAGE_TAG=$1
ACR_LOGIN_SERVER=$2
ACR_NAME=$3

if [ -z "$IMAGE_TAG" ] || [ -z "$ACR_LOGIN_SERVER" ] || [ -z "$ACR_NAME" ]; then
    echo "Uso: deploy.sh <image-tag> <acr-server> <acr-name>"
    exit 1
fi

echo "=== Deploy iniciado - tag: ${IMAGE_TAG} ==="

cd /home/azureuser/microservices-demo-ops

git pull origin main

az acr login --name ${ACR_NAME}

sed -i "s/IMAGE_TAG=.*/IMAGE_TAG=${IMAGE_TAG}/" .env

docker-compose pull vote worker-1 worker-2 worker-3 result

docker-compose up -d \
    --no-deps \
    --force-recreate \
    nginx vote worker-1 worker-2 worker-3 result redis

echo "=== Estado de los contenedores ==="
docker-compose ps

echo "=== Deploy completado ==="