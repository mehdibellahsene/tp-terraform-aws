# ══════════════════════════════════════════════════════════════════════════════
# Backend S3 - Remote State avec DynamoDB Locking (BONUS)
# ══════════════════════════════════════════════════════════════════════════════
#
# Ce fichier configure le stockage du state Terraform sur S3 avec verrouillage
# DynamoDB pour permettre le travail en équipe.
#
# IMPORTANT: Avant d'activer ce backend, vous devez créer manuellement :
# 1. Le bucket S3 pour stocker le state
# 2. La table DynamoDB pour le locking
#
# Commandes pour créer les ressources (à exécuter une seule fois) :
#
# aws s3api create-bucket \
#   --bucket tp-terraform-mehdi-state \
#   --region eu-west-3 \
#   --create-bucket-configuration LocationConstraint=eu-west-3
#
# aws s3api put-bucket-versioning \
#   --bucket tp-terraform-mehdi-state \
#   --versioning-configuration Status=Enabled
#
# aws dynamodb create-table \
#   --table-name terraform-locks \
#   --attribute-definitions AttributeName=LockID,AttributeType=S \
#   --key-schema AttributeName=LockID,KeyType=HASH \
#   --billing-mode PAY_PER_REQUEST \
#   --region eu-west-3
#
# Après création, décommentez le bloc ci-dessous et lancez :
#   terraform init -migrate-state
#
# ══════════════════════════════════════════════════════════════════════════════

# Décommentez pour activer le remote state :

# terraform {
#   backend "s3" {
#     bucket         = "tp-terraform-mehdi-state"
#     key            = "terraform.tfstate"
#     region         = "eu-west-3"
#     encrypt        = true
#     dynamodb_table = "terraform-locks"
#   }
# }

# ══════════════════════════════════════════════════════════════════════════════
# Alternative : Créer les ressources de backend via Terraform
# ══════════════════════════════════════════════════════════════════════════════
#
# Ces ressources peuvent être créées par Terraform lui-même.
# À utiliser dans un projet séparé ou avant de configurer le backend.

resource "aws_s3_bucket" "terraform_state" {
  count  = var.create_backend_resources ? 1 : 0
  bucket = "${var.project_name}-terraform-state"

  lifecycle {
    prevent_destroy = true
  }

  tags = { Name = "${var.project_name}-terraform-state" }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  count  = var.create_backend_resources ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  count  = var.create_backend_resources ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  count  = var.create_backend_resources ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  count        = var.create_backend_resources ? 1 : 0
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = { Name = "${var.project_name}-terraform-locks" }
}
