variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "tp-terraform"
}

variable "host_port" {
  description = "Port sur la machine hôte pour nginx"
  type        = number
  default     = 8080
}

variable "redis_port" {
  description = "Port sur la machine hôte pour redis"
  type        = number
  default     = 6379
}

variable "nginx_image" {
  description = "Image Docker pour nginx"
  type        = string
  default     = "nginx:alpine"
}

variable "redis_image" {
  description = "Image Docker pour redis"
  type        = string
  default     = "redis:alpine"
}
