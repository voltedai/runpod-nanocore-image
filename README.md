# NanoCore RunPod Image

Docker image for running [NanoCore](https://github.com/voltedai/NanoCore) nodeservers on RunPod GPU pods.

**Base:** `runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404` (PyTorch 2.8.0, CUDA 12.8.1, Ubuntu 24.04)
**Includes:** Node.js 22, NanoCore (global), nginx disabled (port 3001 freed)

## Usage

### 1. Create a RunPod pod

Use this image:
```
ghcr.io/voltedai/runpod-nanocore-image:latest
```

Attach a network volume to `/workspace`.

### 2. Prepare the network volume

On the network volume, you need:

```
/workspace/
├── nanocore/
│   ├── nodeservers.json       # Lists nodeservers to register and start
│   └── nanocore.config.json   # Storage paths (models, media, etc.)
└── my-nodeserver/             # Your nodeserver codebase (with nanoserver.json)
```

**`nodeservers.json`** — registry of nodeservers:
```json
[
  {
    "serverDisplayName": "My Nodes",
    "serverPackageId": "my-node-server",
    "serverUid": "some-uuid",
    "language": "python",
    "path": "/workspace/my-nodeserver",
    "port": 24002
  }
]
```

**`nanocore.config.json`** — storage paths (absolute):
```json
{
  "paths": {
    "checkpoint": "/workspace/models/checkpoint",
    "lora": "/workspace/models/lora",
    "vae": "/workspace/models/vae"
  }
}
```

### 3. Configure environment variables

Set these in the RunPod pod settings:

| Variable | Description | Default |
|----------|-------------|---------|
| `NANOCORE_CONFIG` | Path to `nodeservers.json` | `/workspace/nanocore/nodeservers.json` |
| `NANOCORE_PATHS` | Path to `nanocore.config.json` | `/workspace/nanocore/nanocore.config.json` |
| `ASSET_DB_PATH` | Path to `assets.db` | `/workspace/nanocore/assets.db` |
| `ASSET_API_TOKEN` | Asset server API token | `changeme` |

### 4. Start

The entrypoint automatically:
1. Reads `nodeservers.json` and runs `nanocore register` for each nodeserver (creates venv + installs deps if not already done)
2. Starts NanoCore with the configured storage paths

## How it works

- **First boot:** `nanocore register` creates a Python venv in each nodeserver directory and installs dependencies from `requirements.txt`. This takes a few minutes.
- **Subsequent boots:** The venv already exists on the network volume, so `register` is a no-op. NanoCore starts immediately.
- **Models and data** live on the network volume, configured via `nanocore.config.json`. Nothing is stored on the ephemeral container disk.

## Ports

| Port | Service |
|------|---------|
| 3001 | NanoCore asset server (HTTP) |
| 50052 | NanoCore discovery WebSocket |
| Per nodeserver | Nodeserver HTTP + WebSocket (configured in `nodeservers.json`) |
