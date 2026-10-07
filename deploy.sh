#!/usr/bin/env bash
set -e

REGISTRY=$1
NEW_TAG=$2

if [ -z "$REGISTRY" ] || [ -z "$NEW_TAG" ]; then
    echo "Usage: ./deploy.sh <registry_url> <tag>"
    exit 1
fi

# Capture currently running container image for potential rollback
PREV_TAG=$(docker inspect --format='{{.Config.Image}}' orderhub 2>/dev/null || echo "")

echo "Pulling new image: ${REGISTRY}:${NEW_TAG}..."
docker pull "${REGISTRY}:${NEW_TAG}"

# Stop and remove old container safely if it exists
if [ "$(docker ps -a -q -f name=orderhub)" ]; then
    echo "Stopping existing container..."
    docker stop orderhub || true
    docker rm orderhub || true
fi

# Start the new container
echo "Starting container with tag ${NEW_TAG}..."
if ! docker run -d --name orderhub -p 8080:8080 "${REGISTRY}:${NEW_TAG}"; then
    echo "Error: Container startup failed."
    exit 1
fi

# Wait and verify health check
echo "Waiting for health check..."
HEALTHY=false
for i in {1..10}; do
    if curl -s http://localhost:8080/health | grep -q '"UP"'; then
        HEALTHY=true
        break
    fi
    sleep 3
done

if [ "$HEALTHY" = false ]; then
    echo "❌ Health check failed for ${NEW_TAG}! Initiating automated rollback..."
    docker stop orderhub && docker rm orderhub || true
    
    if [ -n "$PREV_TAG" ]; then
        echo "Restoring previous image: $PREV_TAG"
        docker run -d --name orderhub -p 8080:8080 "$PREV_TAG"
        echo "Rollback complete. Restored version: $PREV_TAG"
    else
        echo "No previous version available to restore."
    fi
    exit 1
fi

echo "✅ Deployment successful! Running immutable version: ${REGISTRY}:${NEW_TAG}"