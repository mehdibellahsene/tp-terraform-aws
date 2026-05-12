# ── Images Docker ──────────────────────────────────
resource "docker_image" "nginx" {
  name = var.nginx_image
}

resource "docker_image" "redis" {
  name = var.redis_image
}

# ── Réseau Docker ──────────────────────────────────
resource "docker_network" "app" {
  name = "app-network"
}

# ── Container Nginx ────────────────────────────────
resource "docker_container" "web" {
  name  = "${var.project_name}-web"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = var.host_port
  }

  networks_advanced {
    name = docker_network.app.name
  }
}

# ── Container Redis (exercice bonus) ───────────────
resource "docker_container" "redis" {
  name  = "${var.project_name}-redis"
  image = docker_image.redis.image_id

  ports {
    internal = 6379
    external = var.redis_port
  }

  networks_advanced {
    name = docker_network.app.name
  }
}
