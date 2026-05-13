# ══════════════════════════════════════════════════════════════════════════════
# Outputs - Informations utiles après l'apply
# ══════════════════════════════════════════════════════════════════════════════

output "vpc_id" {
  description = "ID du VPC créé"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID du subnet public"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID du Security Group"
  value       = aws_security_group.web.id
}

output "instance_id" {
  description = "ID de l'instance EC2"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "IP publique de l'instance EC2"
  value       = aws_instance.web.public_ip
}

output "instance_public_dns" {
  description = "DNS public de l'instance EC2"
  value       = aws_instance.web.public_dns
}

output "ssh_command" {
  description = "Commande SSH pour se connecter"
  value       = "ssh -i ~/.ssh/tp_terraform ubuntu@${aws_instance.web.public_ip}"
}

output "s3_bucket_name" {
  description = "Nom du bucket S3"
  value       = aws_s3_bucket.assets.id
}

output "s3_bucket_arn" {
  description = "ARN du bucket S3"
  value       = aws_s3_bucket.assets.arn
}

output "ami_id" {
  description = "ID de l'AMI Ubuntu utilisée"
  value       = data.aws_ami.ubuntu.id
}
