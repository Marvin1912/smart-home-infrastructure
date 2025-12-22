#!/bin/bash

# Fetch all Grafana dashboards from grafana.home-lab.com
# Usage: ./fetch-dashboards.sh

set -e

GRAFANA_URL="https://grafana.home-lab.com"
NAMESPACE="default"
OUTPUT_DIR="dashboards"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Get authentication token
echo "Getting authentication token..."
TOKEN=$(curl -s -u "marvin:password" "$GRAFANA_URL/login" | grep -o '"user":"[^"]*","csrf"[^"]*","token":"[^"]*"' | sed 's/.*"token":"\([^"]*\).*/\1/')

if [ -z "$TOKEN" ]; then
    echo "Failed to get authentication token"
    exit 1
fi

echo "Fetching dashboards list..."
# Get list of dashboards
DASHBOARDS=$(curl -s -H "Authorization: Bearer $TOKEN" \
    "$GRAFANA_URL/apis/dashboard.grafana.app/v1beta1/namespaces/$NAMESPACE/dashboards" | \
    jq -r '.items[].metadata.name')

if [ -z "$DASHBOARDS" ]; then
    echo "No dashboards found or failed to fetch dashboard list"
    exit 1
fi

echo "Found $(echo "$DASHBOARDS" | wc -l) dashboards"

# Fetch each dashboard
for DASHBOARD in $DASHBOARDS; do
    echo "Fetching dashboard: $DASHBOARD"
    curl -s -H "Authorization: Bearer $TOKEN" \
        "$GRAFANA_URL/apis/dashboard.grafana.app/v1beta1/namespaces/$NAMESPACE/dashboards/$DASHBOARD" | \
        jq '.' > "$OUTPUT_DIR/$DASHBOARD.json"
done

echo "All dashboards fetched successfully to $OUTPUT_DIR/"