# TP Terraform - Infrastructure AWS avec Terraform

**DevOps S8 - EFREI Paris**

> Provisionner, versionner et automatiser une infrastructure cloud complète

## Auteur

- **Nom** : Mehdi
- **Email** : mehdi@efrei.fr

---

## Table des matières

1. [Prérequis](#prérequis)
2. [Structure du projet](#structure-du-projet)
3. [Installation et configuration](#installation-et-configuration)
4. [Exercices réalisés](#exercices-réalisés)
5. [Infrastructure AWS](#infrastructure-aws)
6. [Bonus implémentés](#bonus-implémentés)
7. [Commandes utiles](#commandes-utiles)
8. [Captures d'écran](#captures-décran)
9. [Destruction des ressources](#destruction-des-ressources)

---

## Prérequis

### Logiciels requis

| Outil | Version minimale | Installation |
|-------|------------------|--------------|
| Terraform | >= 1.6 | [terraform.io](https://terraform.io) |
| AWS CLI | >= 2.0 | `winget install Amazon.AWSCLI` |
| Docker Desktop | >= 4.0 | [docker.com](https://docker.com) |
| Git | >= 2.0 | `winget install Git.Git` |
| tflint | >= 0.50 | `choco install tflint` |

### Vérification des versions

```powershell
terraform version    # >= 1.6.0
aws --version        # >= 2.0.0
docker --version     # >= 24.0.0
git --version        # >= 2.0.0
tflint --version     # >= 0.50.0
```

### Configuration AWS

1. Créer un compte AWS sur [aws.amazon.com](https://aws.amazon.com)
2. Créer une clé d'accès IAM (Console AWS → IAM → Users → Security credentials)
3. Configurer AWS CLI :

```bash
aws configure
# AWS Access Key ID: AKIA...
# AWS Secret Access Key: ...
# Default region: eu-west-3
# Default output format: json
```

4. Vérifier la connexion :

```bash
aws sts get-caller-identity
```

### Clé SSH

Générer une paire de clés SSH pour l'accès EC2 :

```bash
ssh-keygen -t ed25519 -C "tp-terraform" -f ~/.ssh/tp_terraform
```

---

## Structure du projet

```
terraform/
├── README.md                 # Ce fichier
├── .gitignore               # Fichiers exclus de Git
├── run-tp.ps1               # Script d'automatisation PowerShell (Windows)
├── run-tp.sh                # Script d'automatisation Bash (Linux/macOS)
│
├── tp-docker/               # Exercice 2.1 - Provider Docker
│   ├── versions.tf          # Version Terraform + provider Docker
│   ├── main.tf              # Ressources Docker (nginx, redis)
│   ├── variables.tf         # Variables du projet
│   ├── outputs.tf           # Outputs (URLs, noms containers)
│   └── terraform.tfvars     # Valeurs des variables
│
├── tp-github/               # Exercice 2.2 - Provider GitHub
│   ├── versions.tf          # Version Terraform + provider GitHub
│   ├── main.tf              # Ressources GitHub (repos, secrets)
│   ├── variables.tf         # Variables du projet
│   ├── outputs.tf           # Outputs (URLs repos)
│   └── terraform.tfvars     # Valeurs des variables
│
└── tp-terraform-aws/        # Section 3 - Infrastructure AWS
    ├── versions.tf          # Version Terraform + providers AWS/random
    ├── provider.tf          # Configuration provider AWS + default_tags
    ├── main.tf              # Ressources principales (VPC, EC2, S3...)
    ├── variables.tf         # Déclaration des variables
    ├── outputs.tf           # Outputs (IPs, IDs, commande SSH)
    ├── terraform.tfvars     # Valeurs (sans secrets!)
    ├── backend.tf           # Configuration remote state S3 (bonus)
    ├── .tflint.hcl          # Configuration tflint (bonus)
    ├── scripts/
    │   └── user_data.sh     # Script bootstrap EC2 (bonus)
    └── modules/
        └── network/         # Module réseau réutilisable (bonus)
            ├── main.tf
            ├── variables.tf
            └── outputs.tf
```

---

## Installation et configuration

### 1. Cloner le dépôt

```bash
git clone <URL_DU_REPO>
cd terraform
```

### 2. Configuration des variables d'environnement

#### Pour GitHub (tp-github)

```powershell
$env:GITHUB_TOKEN = "ghp_xxxxxxxxxxxx"
```

#### Pour AWS (tp-terraform-aws)

```powershell
$env:AWS_ACCESS_KEY_ID = "AKIA..."
$env:AWS_SECRET_ACCESS_KEY = "..."
$env:AWS_DEFAULT_REGION = "eu-west-3"
```

### 3. Modifier les fichiers terraform.tfvars

Éditer `tp-terraform-aws/terraform.tfvars` :

```hcl
project_name = "tp-terraform-votrenom"
owner        = "votre.email@efrei.fr"
environment  = "dev"
my_ip        = "X.X.X.X/32"  # Votre IP publique (curl ifconfig.me)
```

---

## Exercices réalisés

### Exercice 2.1 - Provider Docker (Infra locale)

**Objectif** : Déployer des containers Docker avec Terraform

**Ressources créées** :
- Image Docker nginx:alpine
- Image Docker redis:alpine
- Réseau Docker "app-network"
- Container nginx (port 8080)
- Container redis (port 6379)

**Commandes** :

```bash
cd tp-docker
terraform init
terraform plan
terraform apply

# Tester nginx
curl http://localhost:8080

# Vérifier l'idempotence
terraform apply  # 0 changes

# Nettoyer
terraform destroy
```

**Exercices bonus réalisés** :
- [x] Ajout d'un 2e container (redis:alpine)
- [x] Nom de l'image passé en variable
- [x] Vérification de l'idempotence

---

### Exercice 2.2 - Provider GitHub (GitOps)

**Objectif** : Gérer des dépôts GitHub avec Terraform

**Ressources créées** :
- Repository `tp-terraform-mehdi-demo` (public, avec wiki)
- Repository `tp-terraform-mehdi-api` (public, sans wiki)
- Secret GitHub Actions `DATABASE_URL`
- Topics sur les repos : terraform, devops, api

**Commandes** :

```bash
cd tp-github
export GITHUB_TOKEN="ghp_xxx"  # ou $env:GITHUB_TOKEN sur PowerShell
terraform init
terraform plan
terraform apply

# Vérifier sur GitHub.com que les repos sont créés
# Vérifier Settings → Secrets → Actions pour le secret

terraform destroy  # Attention: supprime les repos!
```

**Exercices bonus réalisés** :
- [x] Création de 2 dépôts avec paramètres différents
- [x] Ajout de topics aux dépôts
- [ ] Branch protection (commentée - nécessite scope `read:org`)

---

## Infrastructure AWS

### Section 3 - Infrastructure de base

**Objectif** : Déployer une infrastructure cloud complète sur AWS

### Architecture déployée

```
┌─────────────────────────────────────────────────────────────┐
│                          AWS Cloud                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                    VPC (10.0.0.0/16)                  │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │           Public Subnet (10.0.1.0/24)           │  │  │
│  │  │  ┌─────────────┐     ┌─────────────────────┐    │  │  │
│  │  │  │   EC2       │     │   Security Group    │    │  │  │
│  │  │  │  t3.micro   │◄────│  - SSH (22)         │    │  │  │
│  │  │  │  Ubuntu 24  │     │  - HTTP (80)        │    │  │  │
│  │  │  │  + nginx    │     │  - HTTPS (443)      │    │  │  │
│  │  │  └─────────────┘     └─────────────────────┘    │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                         │                              │  │
│  │  ┌─────────────────────┴────────────────────────────┐ │  │
│  │  │              Internet Gateway                     │ │  │
│  │  └──────────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌─────────────────┐                                        │
│  │   S3 Bucket     │ (versioning + encryption AES256)       │
│  │   assets        │                                        │
│  └─────────────────┘                                        │
└─────────────────────────────────────────────────────────────┘
```

### Ressources créées

| Ressource | Type | Description |
|-----------|------|-------------|
| VPC | `aws_vpc` | Réseau privé virtuel (10.0.0.0/16) |
| Subnet | `aws_subnet` | Sous-réseau public (10.0.1.0/24) |
| Internet Gateway | `aws_internet_gateway` | Accès internet |
| Route Table | `aws_route_table` | Table de routage vers IGW |
| Security Group | `aws_security_group` | Pare-feu (SSH, HTTP, HTTPS) |
| Key Pair | `aws_key_pair` | Clé SSH pour accès EC2 |
| EC2 Instance | `aws_instance` | Serveur Ubuntu 24.04 (t3.micro) |
| S3 Bucket | `aws_s3_bucket` | Stockage avec versioning |

### Déploiement pas à pas

```bash
cd tp-terraform-aws

# 1. Initialiser Terraform
terraform init

# 2. Vérifier la syntaxe
terraform validate

# 3. Formater le code
terraform fmt

# 4. Prévisualiser les changements
terraform plan

# 5. Appliquer (créer les ressources)
terraform apply
# Tapez 'yes' pour confirmer

# 6. Afficher les outputs
terraform output
terraform output instance_public_ip
terraform output ssh_command
```

### Connexion SSH à l'instance

```bash
# Récupérer la commande SSH
terraform output ssh_command

# Se connecter
ssh -i ~/.ssh/tp_terraform ubuntu@<IP_PUBLIQUE>

# Sur l'instance EC2, vérifier :
uname -a              # Ubuntu 24.04
curl ifconfig.me      # IP publique
df -h                 # Espace disque
nginx -v              # Version nginx (si user_data activé)
```

### Outputs disponibles

| Output | Description |
|--------|-------------|
| `vpc_id` | ID du VPC créé |
| `subnet_id` | ID du subnet public |
| `security_group_id` | ID du Security Group |
| `instance_id` | ID de l'instance EC2 |
| `instance_public_ip` | IP publique de l'EC2 |
| `instance_public_dns` | DNS public de l'EC2 |
| `ssh_command` | Commande SSH complète |
| `s3_bucket_name` | Nom du bucket S3 |
| `s3_bucket_arn` | ARN du bucket S3 |

---

## Bonus implémentés

### 1. Remote State S3 + DynamoDB Locking

Le state Terraform est stocké sur S3 avec verrouillage DynamoDB pour le travail en équipe.

**Fichier** : `tp-terraform-aws/backend.tf`

```hcl
terraform {
  backend "s3" {
    bucket         = "tp-terraform-state-bucket"
    key            = "terraform.tfstate"
    region         = "eu-west-3"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### 2. Module réseau réutilisable

Module encapsulant la création du VPC, subnets et routing.

**Dossier** : `tp-terraform-aws/modules/network/`

### 3. User Data - Script bootstrap

Script exécuté au démarrage de l'EC2 pour installer nginx automatiquement.

**Fichier** : `tp-terraform-aws/scripts/user_data.sh`

### 4. tflint - Linter Terraform

Configuration tflint avec le plugin AWS pour détecter les erreurs.

**Fichier** : `tp-terraform-aws/.tflint.hcl`

```bash
cd tp-terraform-aws
tflint --init
tflint
```

### 5. Workspaces multi-environnements

Support des environnements dev/staging/prod avec variables distinctes.

```bash
terraform workspace new dev
terraform workspace new prod
terraform workspace list
terraform workspace select dev
```

---

## Commandes utiles

### Scripts d'automatisation

**Windows (PowerShell):**
```powershell
.\run-tp.ps1              # Menu interactif
.\run-tp.ps1 -All         # Exécuter tout le TP
.\run-tp.ps1 -AWS         # Déployer AWS uniquement
.\run-tp.ps1 -Docker      # Exercice Docker uniquement
.\run-tp.ps1 -GitHub      # Exercice GitHub uniquement
.\run-tp.ps1 -Connect     # Connexion SSH à l'instance
.\run-tp.ps1 -Web         # Ouvrir la page web
.\run-tp.ps1 -Status      # Afficher le statut
.\run-tp.ps1 -Destroy     # Détruire tout
```

**Linux/macOS (Bash):**
```bash
chmod +x run-tp.sh        # Rendre exécutable (1 fois)
./run-tp.sh               # Menu interactif
./run-tp.sh all           # Exécuter tout le TP
./run-tp.sh aws           # Déployer AWS uniquement
./run-tp.sh docker        # Exercice Docker uniquement
./run-tp.sh github        # Exercice GitHub uniquement
./run-tp.sh connect       # Connexion SSH à l'instance
./run-tp.sh web           # Ouvrir la page web
./run-tp.sh status        # Afficher le statut
./run-tp.sh lint          # Exécuter tflint
./run-tp.sh destroy       # Détruire tout
./run-tp.sh help          # Afficher l'aide
```

### Workflow quotidien (Terraform)

```bash
terraform init          # Initialiser (1 fois)
terraform fmt           # Formater le code
terraform validate      # Vérifier la syntaxe
terraform plan          # Prévisualiser
terraform apply         # Appliquer
terraform output        # Voir les outputs
terraform destroy       # Détruire (FIN DE SEANCE!)
```

### Debug et inspection

```bash
terraform state list                    # Lister les ressources
terraform state show aws_instance.web   # Détail d'une ressource
terraform output -json                  # Outputs en JSON
TF_LOG=DEBUG terraform plan             # Mode verbeux
```

### AWS CLI utile

```bash
aws sts get-caller-identity                    # Vérifier credentials
aws ec2 describe-instances --output table      # Lister EC2
aws s3 ls                                      # Lister buckets
aws ec2 describe-vpcs                          # Lister VPCs
```

---

## Captures d'écran

### terraform apply réussi

```
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:

ami_id = "ami-0adb8ca49015e0901"
instance_id = "i-0abc123def456789"
instance_public_dns = "ec2-XX-XX-XX-XX.eu-west-3.compute.amazonaws.com"
instance_public_ip = "XX.XX.XX.XX"
s3_bucket_arn = "arn:aws:s3:::tp-terraform-mehdi-assets-a1b2c3d4"
s3_bucket_name = "tp-terraform-mehdi-assets-a1b2c3d4"
security_group_id = "sg-0abc123def456789"
ssh_command = "ssh -i ~/.ssh/tp_terraform ubuntu@XX.XX.XX.XX"
subnet_id = "subnet-0abc123def456789"
vpc_id = "vpc-0abc123def456789"
```

### Connexion SSH réussie

```
$ ssh -i ~/.ssh/tp_terraform ubuntu@XX.XX.XX.XX

Welcome to Ubuntu 24.04 LTS (GNU/Linux 6.5.0-1014-aws x86_64)

ubuntu@ip-10-0-1-XX:~$ uname -a
Linux ip-10-0-1-XX 6.5.0-1014-aws #14-Ubuntu SMP x86_64 GNU/Linux

ubuntu@ip-10-0-1-XX:~$ curl -s ifconfig.me
XX.XX.XX.XX

ubuntu@ip-10-0-1-XX:~$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/xvda1      7.7G  1.5G  6.2G  20% /
```

---

## Destruction des ressources

**IMPORTANT** : À exécuter à la fin de chaque séance pour économiser les crédits AWS!

### Destruction complète

```bash
# Détruire l'infrastructure AWS
cd tp-terraform-aws
terraform destroy
# Tapez 'yes' pour confirmer

# Détruire les containers Docker
cd ../tp-docker
terraform destroy

# Détruire les repos GitHub (attention!)
cd ../tp-github
terraform destroy
```

### Vérification post-destruction

Vérifier dans la console AWS que toutes les ressources sont supprimées :

- [ ] EC2 → Instances → 0 running
- [ ] VPC → Your VPCs → Seul le VPC par défaut
- [ ] S3 → Buckets → Bucket supprimé
- [ ] EC2 → Key Pairs → Clé supprimée

### Script automatisé

**Windows (PowerShell):**
```powershell
.\run-tp.ps1 -Destroy
```

**Linux/macOS (Bash):**
```bash
./run-tp.sh destroy
```

---

## Checklist de rendu

- [x] Dépôt Git accessible
- [x] README complet avec instructions
- [x] Aucune credential AWS dans le code
- [x] .gitignore exclut .terraform/, *.tfstate, *.tfplan
- [x] terraform fmt sans différence
- [x] terraform validate sans erreur
- [x] terraform plan + apply documenté
- [x] Connexion SSH documentée
- [x] terraform destroy documenté
- [x] Tags Name cohérents sur toutes les ressources
- [x] Bonus listés dans le README

---

## Ressources

- [Documentation Terraform](https://terraform.io/docs)
- [Provider AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Provider Docker](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)
- [Provider GitHub](https://registry.terraform.io/providers/integrations/github/latest/docs)
- [Best Practices Terraform](https://www.terraform-best-practices.com/)

---

*TP réalisé dans le cadre du cours DevOps S8 - EFREI Paris*
