# ══════════════════════════════════════════════════════════════════════════════
# Variables du module Network
# ══════════════════════════════════════════════════════════════════════════════

variable "project_name" {
  description = "Nom du projet (utilisé pour les tags et noms de ressources)"
  type        = string
}

variable "environment" {
  description = "Environnement (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block du subnet public"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block du subnet privé"
  type        = string
  default     = "10.0.2.0/24"
}

variable "create_private_subnet" {
  description = "Créer un subnet privé (pour RDS, ALB, etc.)"
  type        = bool
  default     = false
}
