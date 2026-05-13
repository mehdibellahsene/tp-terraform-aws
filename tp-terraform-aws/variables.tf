variable "aws_region" {
  description = "Région AWS cible"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Nom du projet (utilisé dans les tags et noms de ressources)"
  type        = string
}

variable "environment" {
  description = "Environnement (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "L'environnement doit être dev, staging ou prod."
  }
}

variable "owner" {
  description = "Nom ou email du responsable"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR du subnet public"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}

variable "my_ip" {
  description = "Votre IP publique pour autoriser SSH (format CIDR : x.x.x.x/32)"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Chemin vers la clé publique SSH"
  type        = string
  default     = "~/.ssh/tp_terraform.pub"
}

# ══════════════════════════════════════════════════════════════════════════════
# Variables Bonus
# ══════════════════════════════════════════════════════════════════════════════

variable "create_backend_resources" {
  description = "Créer les ressources pour le backend S3 (bucket + DynamoDB)"
  type        = bool
  default     = false
}

variable "enable_user_data" {
  description = "Activer le script user_data pour bootstrap EC2"
  type        = bool
  default     = true
}

variable "use_network_module" {
  description = "Utiliser le module réseau au lieu des ressources directes"
  type        = bool
  default     = false
}
