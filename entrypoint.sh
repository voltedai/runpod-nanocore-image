#!/bin/bash
set -e

# Start RunPod base services (SSH, Jupyter) in background
/start.sh &
sleep 5

# Kill nginx — it steals port 3001 needed by NanoCore asset server
pkill nginx 2>/dev/null && echo "nginx stopped (port 3001 freed)" || true

echo "=== NanoCore Pod Entrypoint ==="
echo "  NANOCORE_CONFIG: $NANOCORE_CONFIG"
echo "  NANOCORE_PATHS:  $NANOCORE_PATHS"
echo "  ASSET_DB_PATH:   $ASSET_DB_PATH"

# Validate nodeservers.json exists
if [ ! -f "$NANOCORE_CONFIG" ]; then
    echo "WARNING: nodeservers.json not found at $NANOCORE_CONFIG"
    echo "NanoCore will not start. SSH is available — set up manually."
    echo "Set NANOCORE_CONFIG env var to the path of your nodeservers.json."
    wait
    exit 0
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

# Start NanoCore as PID 1 (receives signals properly)
echo "Starting NanoCore..."
exec nanocore start --paths "$NANOCORE_PATHS"
