#!/usr/bin/env bash
#
# build-and-push.sh - Build and push the db-backup Docker image
#
# Usage: ./build-and-push.sh [--registry HOST:PORT] [--tag TAG]
#
# Defaults:
#   Registry: localhost:5000
#   Tag:      latest

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REGISTRY="${REGISTRY:-localhost:5000}"
IMAGE_NAME="db-backup"
TAG="${TAG:-latest}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --registry)
            REGISTRY="$2"
            shift 2
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--registry HOST:PORT] [--tag TAG]"
            echo ""
            echo "Options:"
            echo "  --registry  Registry host and port (default: localhost:5000)"
            echo "  --tag       Image tag (default: latest)"
            echo ""
            echo "Environment Variables:"
            echo "  REGISTRY    Registry host and port (default: localhost:5000)"
            echo "  TAG         Image tag (default: latest)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "============================================"
echo "  Build & Push db-backup Image"
echo "============================================"
echo ""
echo "Image: ${FULL_IMAGE}"
echo ""

echo "[1/2] Building image..."
docker build -t "${FULL_IMAGE}" "${SCRIPT_DIR}"

echo ""
echo "[2/2] Pushing image to ${REGISTRY}..."
docker push "${FULL_IMAGE}"

echo ""
echo "============================================"
echo "  Done: ${FULL_IMAGE}"
echo "============================================"
