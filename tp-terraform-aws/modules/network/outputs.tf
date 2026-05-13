# ══════════════════════════════════════════════════════════════════════════════
# Outputs du module Network
# ══════════════════════════════════════════════════════════════════════════════

output "vpc_id" {
  description = "ID du VPC créé"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block du VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "ID du subnet public"
  value       = aws_subnet.public.id
}

output "public_subnet_cidr" {
  description = "CIDR block du subnet public"
  value       = aws_subnet.public.cidr_block
}

output "private_subnet_id" {
  description = "ID du subnet privé (si créé)"
  value       = var.create_private_subnet ? aws_subnet.private[0].id : null
}

output "private_subnet_cidr" {
  description = "CIDR block du subnet privé (si créé)"
  value       = var.create_private_subnet ? aws_subnet.private[0].cidr_block : null
}

output "internet_gateway_id" {
  description = "ID de l'Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_route_table_id" {
  description = "ID de la route table publique"
  value       = aws_route_table.public.id
}

output "availability_zones" {
  description = "Liste des zones de disponibilité utilisées"
  value       = data.aws_availability_zones.available.names
}
