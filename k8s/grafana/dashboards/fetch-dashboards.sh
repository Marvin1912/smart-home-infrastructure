#!/bin/bash

# Fetch all Grafana dashboards from grafana.home-lab.com
# Usage: ./fetch-dashboards.sh

set -e

GRAFANA_URL="http://grafana.home-lab.com"
NAMESPACE="default"
OUTPUT_DIR="dashboards"

mkdir -p "$OUTPUT_DIR"

echo "Fetching dashboards list..."
DASHBOARDS=$(curl -s -u "marvin:password" "$GRAFANA_URL/apis/dashboard.grafana.app/v1beta1/namespaces/$NAMESPACE/dashboards" | jq -r '.items[].metadata.name')

if [ -z "$DASHBOARDS" ]; then
    echo "No dashboards found or failed to fetch dashboard list"
    exit 1
fi

echo "Found $(echo "$DASHBOARDS" | wc -l) dashboards"

for DASHBOARD in $DASHBOARDS; do
    echo "Fetching dashboard: $DASHBOARD"
    curl -s -u "marvin:password" "$GRAFANA_URL/apis/dashboard.grafana.app/v1beta1/namespaces/$NAMESPACE/dashboards/$DASHBOARD" | jq '.' > "$OUTPUT_DIR/$DASHBOARD.json"
done

echo "All dashboards fetched successfully to $OUTPUT_DIR/"