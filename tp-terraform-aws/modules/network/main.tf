# ══════════════════════════════════════════════════════════════════════════════
# Module Network - Infrastructure réseau réutilisable
# ══════════════════════════════════════════════════════════════════════════════
#
# Ce module crée une infrastructure réseau complète pour AWS :
# - VPC avec DNS activé
# - Subnet public avec IP automatique
# - Internet Gateway pour accès internet
# - Route Table pour le routage vers IGW
#
# Usage:
#   module "network" {
#     source             = "./modules/network"
#     project_name       = "mon-projet"
#     vpc_cidr           = "10.0.0.0/16"
#     public_subnet_cidr = "10.0.1.0/24"
#   }
#
# ══════════════════════════════════════════════════════════════════════════════

# ── Data Sources ──────────────────────────────────────────────────────────────

data "aws_availability_zones" "available" {
  state = "available"
}

# ── VPC ───────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# ── Internet Gateway ──────────────────────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

# ── Subnet Public ─────────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Environment = var.environment
    Type        = "public"
  }
}

# ── Subnet Privé (optionnel, pour RDS/ALB) ────────────────────────────────────

resource "aws_subnet" "private" {
  count                   = var.create_private_subnet ? 1 : 0
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-private-subnet"
    Environment = var.environment
    Type        = "private"
  }
}

# ── Route Table Public ────────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ── Route Table Privée (optionnel) ────────────────────────────────────────────

resource "aws_route_table" "private" {
  count  = var.create_private_subnet ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-private-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private" {
  count          = var.create_private_subnet ? 1 : 0
  subnet_id      = aws_subnet.private[0].id
  route_table_id = aws_route_table.private[0].id
}
