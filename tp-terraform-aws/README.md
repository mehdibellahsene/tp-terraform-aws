# Section 3 - Infrastructure AWS

Déploiement d'une infrastructure AWS complète.

## Architecture

- VPC + Subnet public
- EC2 Ubuntu (t2.micro Free Tier)
- Security Group (SSH, HTTP, HTTPS)
- S3 Bucket avec versioning

## Configuration

Créer `.env` :
```
AWS_ACCESS_KEY_ID=xxxxx
AWS_SECRET_ACCESS_KEY=xxxxx
```

Modifier `terraform.tfvars` :
```hcl
project_name = "tp-terraform-monnom"
owner        = "email@efrei.fr"
my_ip        = "x.x.x.x/32"
```

## Lancement

```bash
terraform init
terraform plan
terraform apply
```

## Connexion SSH

```bash
ssh -i ~/.ssh/tp_terraform ubuntu@<IP>
```

## Destruction

```bash
terraform destroy
```
