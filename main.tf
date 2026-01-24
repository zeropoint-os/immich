terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

variable "zp_module_id" {
  type        = string
  default     = "ollama"
  description = "Unique identifier for this module instance (user-defined, freeform)"
}

 variable "zp_network_name" {
  type        = string
  description = "Pre-created Docker network name for this module (managed by zeropoint)"
}

variable "zp_arch" {
  type        = string
  default     = "amd64"
  description = "Target architecture - amd64, arm64, etc. (injected by zeropoint)"
}

variable "zp_gpu_vendor" {
  type        = string
  default     = ""
  description = "GPU vendor - nvidia, amd, intel, or empty for no GPU (injected by zeropoint)"
}

variable "zp_module_storage" {
  type        = string
  description = "Host path for persistent storage (injected by zeropoint)"
}

# Build Ollama image from local Dockerfile
resource "docker_image" "ollama" {
  name = "${var.zp_module_id}:latest"
  build {
    context    = path.module
    dockerfile = "Dockerfile"
    platform   = "linux/${var.zp_arch}"  # Uses injected zp_arch variable
  }
  keep_locally = true
}

# Main Ollama container (no host port binding)
resource "docker_container" "ollama_main" {
  name  = "${var.zp_module_id}-main"
  image = docker_image.ollama.image_id

  # Network configuration (provided by zeropoint)
  networks_advanced {
    name = var.zp_network_name
  }

  # Restart policy
  restart = "unless-stopped"

  # GPU access (conditional based on vendor)
  runtime = var.zp_gpu_vendor == "nvidia" ? "nvidia" : null
  gpus    = var.zp_gpu_vendor != "" ? "all" : null

  # Environment variables
  env = [
    "OLLAMA_HOST=0.0.0.0",
  ]

  # Persistent storage
  volumes {
    host_path      = "${var.zp_module_storage}/.ollama"
    container_path = "/root/.ollama"
  }

  # Ports exposed internally (no host binding)
  # Port 11434 is accessible via service discovery (DNS)
}

# Outputs for zeropoint (container resource only)
output "main" {
  value       = docker_container.ollama_main
  description = "Main Ollama container"
}

# Service ports for external access (defined but not bound to host)
output "main_ports" {
  value = {
    api = {
      port        = 11434                   # Ollama API port
      protocol    = "http"                  # The protocol used
      transport   = "tcp"                   # Transport layer
      description = "Ollama API endpoint"   # Description of the port
      default     = true                    # Default port for the service
    }
  }
  description = "Service ports for external access"
}

# Ollama API URL for easy consumption by other modules
output "ollama_api_url" {
  value       = "http://${docker_container.ollama_main.name}:11434"
  description = "Ollama API URL accessible via Docker network"
}