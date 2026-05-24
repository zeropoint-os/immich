# Immich zeropoint module

This Terraform module deploys the official Immich application and the Immich microservices containers into a pre-existing Docker network managed by Zeropoint. Images are pulled directly from the upstream registry; no local Dockerfile build is required.

## Resources Created

- **Docker Images**: Pulls `ghcr.io/immich-app/immich:latest` and `ghcr.io/immich-app/immich-microservices:latest`
- **Docker Containers**: `immich` and `immich-microservices` running on the provided Zeropoint network

## Requirements

- Terraform >= 1.0
- Docker provider ~> 3.0

## Usage

### Via zeropoint API

POST a module install to the zeropoint node (zeropoint injects `zp_` variables):

```bash
curl -X POST http://<zeropoint-node-name>:2370/modules/install \
  -H "Content-Type: application/json" \
  -d '{
    "source": "https://github.com/zeropoint-os/immich-module.git",
    "module_id": "immich",
    "arch": "amd64"
  }'
```

### Manual (for testing)

Use the workspace Run tasks to create a test network and run Terraform init/plan/apply.

## Inputs

The module retains all `zp_` inputs injected by Zeropoint and does not remove or rename them. Important inputs:

- `zp_network_name` (string) - Docker network name (required)
- `zp_arch` (string) - Target architecture (default: `amd64`)
- `zp_module_dir` (string) - Agent's working directory for this module — terraform state + cloned source (required)
- `zp_storage_dir` (string) - Isolated data root for this module — all bind mounts must live under here (required)

## Outputs

- `immich_main` - The `docker_container` resource for Immich
- `microservices` - The `docker_container` resource for Immich microservices
- `containers` - Map of container names for service discovery

## Network & Service Discovery

Containers are attached to the provided Docker network and can be reached by container name (DNS) from other containers on that network.

## Testing

Use the provided test script to verify containers exist and print their network IPs.
