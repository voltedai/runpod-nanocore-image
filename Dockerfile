FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

# Node.js 22 (required by NanoCore)
RUN curl -fsSL https://nodejs.org/dist/v22.14.0/node-v22.14.0-linux-x64.tar.xz | tar -xJ -C /opt/
ENV PATH="/opt/node-v22.14.0-linux-x64/bin:$PATH"

# NanoCore (globally installed, no npx needed)
RUN npm install -g nanocore

# Disable nginx (steals port 3001 needed by NanoCore asset server)
RUN rm -f /etc/nginx/sites-enabled/default && \
    echo 'server { listen 80; return 444; }' > /etc/nginx/sites-enabled/default

# NanoCore env vars (override in RunPod pod settings):
#   NANOCORE_CONFIG    — path to nodeservers.json (nodeserver registry)
#   NANOCORE_PATHS     — path to nanocore.config.json (model/media directories)
#   ASSET_DB_PATH      — path to assets.db (asset index)
#   ASSET_API_TOKEN    — API token for asset server authentication
ENV NANOCORE_CONFIG=/workspace/nanocore/nodeservers.json
ENV NANOCORE_PATHS=/workspace/nanocore/nanocore.config.json
ENV ASSET_DB_PATH=/workspace/nanocore/assets.db
ENV ASSET_API_TOKEN=changeme

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
