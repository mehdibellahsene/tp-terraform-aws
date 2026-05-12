output "container_name" {
  description = "Nom du container nginx"
  value       = docker_container.web.name
}

output "url" {
  description = "URL pour accéder à nginx"
  value       = "http://localhost:${docker_container.web.ports[0].external}"
}

output "redis_container_name" {
  description = "Nom du container redis"
  value       = docker_container.redis.name
}

output "redis_port" {
  description = "Port redis exposé"
  value       = docker_container.redis.ports[0].external
}
