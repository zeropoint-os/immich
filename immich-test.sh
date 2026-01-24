#!/bin/bash

# Simple test script for Immich containers: prints container IPs

IMMICH_NAME="${ZP_MODULE_ID:-immich}-immich"
MICRO_NAME="${ZP_MODULE_ID:-immich}-microservices"

for name in "$IMMICH_NAME" "$MICRO_NAME"; do
  ip=$(docker inspect "$name" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)
  if [ -z "$ip" ]; then
    echo "Container $name not found or not running"
  else
    echo "Found $name at IP: $ip"
  fi
done

echo "Done. To test service endpoints, curl the appropriate API paths on the container IPs above."