#!/bin/bash

# Fetch all Grafana dashboards from grafana.home-lab.com
# Usage: ./fetch-dashboards.sh

set -e

GRAFANA_URL="http://grafana.home-lab.com"
NAMESPACE="default"

echo "Fetching dashboards list..."
DASHBOARDS=$(curl -s -u "marvin:password" "$GRAFANA_URL/apis/dashboard.grafana.app/v1beta1/namespaces/$NAMESPACE/dashboards" | jq -r '.items[].metadata.name')

if [ -z "$DASHBOARDS" ]; then
    echo "No dashboards found or failed to fetch dashboard list"
    exit 1
fi

echo "Found $(echo "$DASHBOARDS" | wc -l) dashboards"

for DASHBOARD in $DASHBOARDS; do
    echo "Fetching dashboard: $DASHBOARD"
    DASHBOARD_JSON=$(curl -s -u "marvin:password" "$GRAFANA_URL/apis/dashboard.grafana.app/v1beta1/namespaces/$NAMESPACE/dashboards/$DASHBOARD")
    DASHBOARD_TITLE=$(echo "$DASHBOARD_JSON" | jq -r '.spec.title')

    if [ -z "$DASHBOARD_TITLE" ] || [ "$DASHBOARD_TITLE" == "null" ]; then
        echo "Warning: Could not extract title for dashboard $DASHBOARD, using name as fallback"
        DASHBOARD_TITLE=$DASHBOARD
    fi

    SANITIZED_TITLE=$(echo "$DASHBOARD_TITLE" | sed 's/ /_/g' | tr -dc 'a-zA-Z0-9_.-' | tr '[:upper:]' '[:lower:]')

    echo "Saving as: $SANITIZED_TITLE.json"
    echo "$DASHBOARD_JSON" | jq -r '.spec | walk(if type == "object" then with_entries(select(.key != "uid")) else . end)' > "dashboards/$SANITIZED_TITLE.json"
done

echo "All dashboards fetched successfully to $(pwd)/dashboards"