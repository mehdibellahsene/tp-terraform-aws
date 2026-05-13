variable "github_token" {
  description = "Personal Access Token GitHub"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "db_url" {
  description = "URL de base de données (pour le secret GitHub Actions)"
  type        = string
  sensitive   = true
  default     = "postgresql://user:pass@localhost/mydb"
}
