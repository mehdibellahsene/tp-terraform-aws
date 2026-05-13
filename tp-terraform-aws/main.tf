# ══════════════════════════════════════════════════════════════════════════════
# Locals - Configuration multi-environnements (BONUS Workspaces)
# ══════════════════════════════════════════════════════════════════════════════

locals {
  # Détermine l'environnement depuis le workspace ou la variable
  environment = terraform.workspace != "default" ? terraform.workspace : var.environment

  # Préfixe de nommage incluant l'environnement
  name_prefix = "${var.project_name}-${local.environment}"

  # Configuration par environnement
  instance_types = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.medium"
  }

  # Sélection du type d'instance selon l'environnement
  instance_type = lookup(local.instance_types, local.environment, var.instance_type)

  # Tags communs à toutes les ressources
  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
    Workspace   = terraform.workspace
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# Data Sources
# ══════════════════════════════════════════════════════════════════════════════

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# VPC - Virtual Private Cloud
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${local.name_prefix}-vpc" }
}

# ══════════════════════════════════════════════════════════════════════════════
# Internet Gateway
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-igw" }
}

# ══════════════════════════════════════════════════════════════════════════════
# Subnet Public
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = { Name = "${local.name_prefix}-public-subnet" }
}

# ══════════════════════════════════════════════════════════════════════════════
# Route Table (accès internet depuis subnet public)
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${local.name_prefix}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ══════════════════════════════════════════════════════════════════════════════
# Security Group - Pare-feu de l'instance
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Security Group pour le serveur web"
  vpc_id      = aws_vpc.main.id

  # SSH - uniquement depuis votre IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "SSH depuis ma machine"
  }

  # HTTP public
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP public"
  }

  # HTTPS public
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS public"
  }

  # Tout le trafic sortant autorisé
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tout le trafic sortant"
  }

  tags = { Name = "${local.name_prefix}-web-sg" }
}

# ══════════════════════════════════════════════════════════════════════════════
# Clé SSH
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_key_pair" "deployer" {
  key_name   = "${local.name_prefix}-key"
  public_key = file(var.ssh_public_key_path)
}

# ══════════════════════════════════════════════════════════════════════════════
# Instance EC2
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = local.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.deployer.key_name

  # User Data - Script de bootstrap (BONUS)
  user_data = var.enable_user_data ? file("${path.module}/scripts/user_data.sh") : null

  root_block_device {
    volume_size = 8 # Minimum pour Ubuntu, économise les coûts
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = "${local.name_prefix}-web" }
}

# ══════════════════════════════════════════════════════════════════════════════
# Bucket S3
# ══════════════════════════════════════════════════════════════════════════════

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "assets" {
  bucket = "${local.name_prefix}-assets-${random_id.suffix.hex}"

  tags = { Name = "${local.name_prefix}-assets" }
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
