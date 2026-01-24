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
  default     = "immich"
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

# External service inputs (to be provided/linked by the user)
variable "redis_host" {
  type        = string
  default     = "redis-main"
  description = "Hostname of the Redis service (e.g. redis-main or an external host)"
}

variable "redis_port" {
  type        = number
  default     = 6379
  description = "Port for Redis (default 6379)"
}

variable "postgres_host" {
  type        = string
  default     = "postgres-main"
  description = "Hostname of the Postgres service (e.g. postgres-main or an external host)"
}

variable "postgres_port" {
  type        = number
  default     = 5432
  description = "Port for Postgres (default 5432)"
}

variable "postgres_user" {
  type        = string
  default     = "postgres"
  description = "Postgres username"
}

variable "postgres_password" {
  type        = string
  default     = "postgres"
  description = "Postgres password"
}

variable "postgres_db" {
  type        = string
  default     = "immich"
  description = "Postgres database name"
}

variable "postgres_connection" {
  type = map(any)
  default = {}
  description = "Optional Postgres connection map with keys: host, port, user, password, database, uri"
}

locals {
  db_host     = lookup(var.postgres_connection, "host", var.postgres_host)
  db_port     = tostring(lookup(var.postgres_connection, "port", var.postgres_port))
  db_user     = lookup(var.postgres_connection, "user", var.postgres_user)
  db_password = lookup(var.postgres_connection, "password", var.postgres_password)
  db_database = lookup(var.postgres_connection, "database", var.postgres_db)
  db_uri      = lookup(var.postgres_connection, "uri", format("postgresql://%s:%s@%s:%s/%s", local.db_user, local.db_password, local.db_host, lookup(var.postgres_connection, "port", var.postgres_port), local.db_database))
}

# Pull the official Immich images from the registry (no local Dockerfile build)
resource "docker_image" "immich" {
  name         = "ghcr.io/immich-app/immich-server:v2.4.1"
  keep_locally = true
}

resource "docker_image" "machine_learning" {
  name         = "ghcr.io/immich-app/immich-machine-learning:v2.4.1"
  keep_locally = true
}

# Immich application container
resource "docker_container" "immich" {
  name  = "${var.zp_module_id}-immich"
  image = docker_image.immich.image_id

  networks_advanced {
    name = var.zp_network_name
  }

  restart = "unless-stopped"

  # Environment variables to let Immich connect to Redis/Postgres and to operate
  env = [
    "NODE_ENV=production",
    "DB_HOST=${local.db_host}",
    "DB_PORT=${local.db_port}",
    "DB_USERNAME=${local.db_user}",
    "DB_PASSWORD=${local.db_password}",
    "DB_DATABASE_NAME=${local.db_database}",
    "DB_URI=${local.db_uri}",
    "DB_URL=${local.db_uri}",
    "DB_HOSTNAME=${local.db_host}",
    "DATABASE_HOST=${local.db_host}",
    "POSTGRES_HOST=${local.db_host}",
    "DATABASE_URL=${local.db_uri}",
    "REDIS_HOSTNAME=${var.redis_host}",
    "REDIS_PORT=${var.redis_port}",
  ]

  # Ensure microservices container exists on the network so Immich can reach it
  depends_on = [docker_container.machine_learning]

  volumes {
    host_path      = "${var.zp_module_storage}/immich"
    container_path = "/data"
  }
}

# Immich microservices container
resource "docker_container" "machine_learning" {
  name  = "${var.zp_module_id}-machine-learning"
  image = docker_image.machine_learning.image_id

  networks_advanced {
    name = var.zp_network_name
  }

  restart = "unless-stopped"

  # If a GPU vendor is provided, set the runtime to nvidia so the container can access GPUs
  runtime = var.zp_gpu_vendor != "" ? "nvidia" : null

  volumes {
    host_path      = "${var.zp_module_storage}/immich-machine-learning"
    container_path = "/cache"
  }
}

# Outputs for zeropoint (container resources)
output "main" {
  value       = docker_container.immich
  description = "Immich application container"
}

output "main_ports" {
  value = {
    web = {
      port        = 2283
      protocol    = "http"
      transport   = "tcp"
      description = "Immich frontend"
      default     = false
    }
  }
  description = "Service ports for external access"
}

output "microservices" {
  value       = docker_container.machine_learning
  description = "Immich machine-learning container"
}

output "containers" {
  value = {
    immich        = docker_container.immich.name
    machine_learning = docker_container.machine_learning.name
  }
  description = "Container names for service discovery"
}
