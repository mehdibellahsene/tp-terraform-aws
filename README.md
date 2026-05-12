# TP Terraform - DevOps S8

TP Infrastructure as Code avec Terraform.

## Structure

```
tp-terraform/
├── tp-docker/          # Exercice 2.1 - Provider Docker
├── tp-github/          # Exercice 2.2 - Provider GitHub
├── tp-terraform-aws/   # Section 3 - Infrastructure AWS
└── run-tp.ps1          # Script d'exécution
```

## Étapes réalisées

### 1. Exercice Docker (tp-docker)
- Configuration du provider Docker
- Déploiement containers nginx et redis
- Test de connectivité

### 2. Exercice GitHub (tp-github)
- Configuration du provider GitHub
- Création de 2 repositories
- Configuration d'un secret GitHub Actions

### 3. Infrastructure AWS (tp-terraform-aws)
- Création VPC + Subnet public
- Déploiement EC2 Ubuntu (t2.micro)
- Configuration Security Group
- Création bucket S3 avec versioning

## Lancement

```powershell
# Tout exécuter
.\run-tp.ps1 -All

# Par exercice
.\run-tp.ps1 -Docker
.\run-tp.ps1 -GitHub
.\run-tp.ps1 -AWS

# Destruction
.\run-tp.ps1 -Destroy
```

## Configuration

Créer les fichiers `.env` (demandés automatiquement si absents) :

```
tp-github/.env      → GITHUB_TOKEN
tp-terraform-aws/.env → AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
```
