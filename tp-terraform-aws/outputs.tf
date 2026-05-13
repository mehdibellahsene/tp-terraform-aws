# ══════════════════════════════════════════════════════════════════════════════
# Outputs - Informations utiles après l'apply
# ══════════════════════════════════════════════════════════════════════════════

# ── VPC & Réseau ──────────────────────────────────────────────────────────────

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

# ── Instance EC2 ──────────────────────────────────────────────────────────────

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

output "instance_private_ip" {
  description = "IP privée de l'instance EC2"
  value       = aws_instance.web.private_ip
}

# ── Commandes de connexion ────────────────────────────────────────────────────

output "ssh_command" {
  description = "Commande SSH pour se connecter à l'instance"
  value       = "ssh -i ~/.ssh/tp_terraform ubuntu@${aws_instance.web.public_ip}"
}

output "ssh_command_dns" {
  description = "Commande SSH via DNS public"
  value       = "ssh -i ~/.ssh/tp_terraform ubuntu@${aws_instance.web.public_dns}"
}

output "ssm_command" {
  description = "Commande AWS SSM Session Manager (nécessite IAM role SSM)"
  value       = "aws ssm start-session --target ${aws_instance.web.id}"
}

output "scp_upload_command" {
  description = "Commande SCP pour uploader un fichier"
  value       = "scp -i ~/.ssh/tp_terraform <fichier_local> ubuntu@${aws_instance.web.public_ip}:~/"
}

output "scp_download_command" {
  description = "Commande SCP pour télécharger un fichier"
  value       = "scp -i ~/.ssh/tp_terraform ubuntu@${aws_instance.web.public_ip}:~/<fichier_distant> ."
}

# ── URLs d'accès ──────────────────────────────────────────────────────────────

output "web_url" {
  description = "URL HTTP du serveur web (si nginx installé)"
  value       = "http://${aws_instance.web.public_ip}"
}

output "web_url_dns" {
  description = "URL HTTP via DNS public"
  value       = "http://${aws_instance.web.public_dns}"
}

# ── S3 Bucket ─────────────────────────────────────────────────────────────────

output "s3_bucket_name" {
  description = "Nom du bucket S3"
  value       = aws_s3_bucket.assets.id
}

output "s3_bucket_arn" {
  description = "ARN du bucket S3"
  value       = aws_s3_bucket.assets.arn
}

output "s3_bucket_url" {
  description = "URL du bucket S3"
  value       = "https://${aws_s3_bucket.assets.id}.s3.${var.aws_region}.amazonaws.com"
}

# ── Informations générales ────────────────────────────────────────────────────

output "ami_id" {
  description = "ID de l'AMI Ubuntu utilisée"
  value       = data.aws_ami.ubuntu.id
}

output "environment" {
  description = "Environnement déployé"
  value       = local.environment
}

output "workspace" {
  description = "Workspace Terraform actuel"
  value       = terraform.workspace
}

output "instance_type" {
  description = "Type d'instance EC2 utilisé"
  value       = local.instance_type
}

# ── Résumé de connexion ───────────────────────────────────────────────────────

output "connection_info" {
  description = "Résumé des informations de connexion"
  value       = <<-EOT

    ╔══════════════════════════════════════════════════════════════════════╗
    ║                    INFORMATIONS DE CONNEXION                        ║
    ╠══════════════════════════════════════════════════════════════════════╣
    ║  Instance ID   : ${aws_instance.web.id}
    ║  IP Publique   : ${aws_instance.web.public_ip}
    ║  IP Privée     : ${aws_instance.web.private_ip}
    ║  Environnement : ${local.environment}
    ╠══════════════════════════════════════════════════════════════════════╣
    ║  CONNEXION SSH :                                                     ║
    ║  ssh -i ~/.ssh/tp_terraform ubuntu@${aws_instance.web.public_ip}
    ╠══════════════════════════════════════════════════════════════════════╣
    ║  PAGE WEB :                                                          ║
    ║  http://${aws_instance.web.public_ip}
    ╚══════════════════════════════════════════════════════════════════════╝

  EOT
}
