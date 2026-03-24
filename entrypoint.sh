#!/bin/bash
set -e

echo "=== NanoCore Pod Entrypoint ==="
echo "  NANOCORE_CONFIG: $NANOCORE_CONFIG"
echo "  NANOCORE_PATHS:  $NANOCORE_PATHS"
echo "  ASSET_DB_PATH:   $ASSET_DB_PATH"

# Validate nodeservers.json exists
if [ ! -f "$NANOCORE_CONFIG" ]; then
    echo "ERROR: nodeservers.json not found at $NANOCORE_CONFIG"
    echo "Create it on your network volume or set NANOCORE_CONFIG env var."
    exit 1
fi

# Register each nodeserver listed in nodeservers.json (idempotent)
echo "Registering nodeservers..."
for server_path in $(python3 -c "
import json
with open('$NANOCORE_CONFIG') as f:
    servers = json.load(f)
for s in servers:
    print(s['path'])
"); do
    if [ -d "$server_path" ]; then
        echo "  Registering: $server_path"
        cd "$server_path"
        nanocore register
    else
        echo "  WARNING: $server_path does not exist, skipping"
    fi
done

# Start NanoCore (NANOCORE_CONFIG is read natively by NanoCore)
echo "Starting NanoCore..."
exec nanocore start --paths "$NANOCORE_PATHS"
