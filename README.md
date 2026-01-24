# Ollama zeropoint app

This module defines the Ollama app for zeropoint os using Terraform and the Docker provider.

## Resources Created

- **Docker Image**: Builds from local `Dockerfile` with platform-specific targeting
- **Docker Container**: Ollama server with optional GPU support

## Requirements

- Terraform >= 1.0
- Docker provider ~> 3.0
- GPU support (optional):
  - NVIDIA: NVIDIA Container Runtime
  - AMD: ROCm drivers
  - Intel: Intel GPU drivers

## Usage

### Via zeropoint API

```bash
curl -X POST http://<zeropoint-node-name>:2370/modules/install \
  -H "Content-Type: application/json" \
  -d '{
    "source": "https://github.com/zeropoint-os/ollama.git", 
    "module_id": "ollama",
    "arch": "arm64",
    "gpu_vendor": "nvidia"
  }'
```

### Manual (for testing)

Use Run task (Shift+Alt+T)
1. Full test - setup and apply
2. Full test - cleanup

The install will be performed using Docker-in-Docker.

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `zp_app_id` | string | Unique identifier for this app instance (injected by zeropoint) | `"ollama"` |
| `zp_network_name` | string | Pre-created Docker network name (injected by zeropoint) | (required) |
| `zp_arch` | string | Target architecture: amd64, arm64, etc. (injected by zeropoint) | `"amd64"` |
| `zp_gpu_vendor` | string | GPU vendor: nvidia, amd, intel, or empty for no GPU (injected by zeropoint) | `""` |
| `zp_module_storage` | string | Host path for persistent storage (injected by zeropoint) | (required) |

## Outputs

| Name | Description |
|------|-------------|
| `main` | Main Ollama container resource (docker_container) |

## GPU Support

This module supports multiple GPU vendors:

- **NVIDIA**: Sets `runtime = "nvidia"` and `gpus = "all"`
- **AMD/Intel**: Sets `gpus = "all"` (uses default runtime with device access)
- **No GPU**: Both runtime and gpus set to null (CPU-only mode)

The GPU vendor is auto-detected by zeropoint and injected via the `gpu_vendor` variable.

## Network & Service Discovery

- **Internal Port**: 11434 (Ollama API)
- **Network**: Uses pre-created network provided by zeropoint via `zp_network_name`
- **No Host Ports**: Service discovery via DNS only
- **Container Name**: `${zp_module_id}-main` (e.g., `ollama-main`)

## Accessing Ollama

### From Other Containers (Service Discovery)

Other apps linked to Ollama can access it via DNS:

```bash
curl http://ollama-main:11434/api/tags
```

### From Host (via Exposure)

External access requires creating an exposure through zeropoint API.
