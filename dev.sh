#!/bin/bash
source .env

# stop and remove any running services of this project
docker compose down --remove-orphans

docker compose up -d 
docker exec -it $APP_CONTAINER_NAME sh
