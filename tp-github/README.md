# Exercice 2.2 - Provider GitHub

Gestion de repos GitHub avec Terraform.

## Ressources créées

- 2 repositories (app + infra)
- Secret GitHub Actions

## Configuration

Créer `.env` avec votre token :
```
GITHUB_TOKEN=ghp_xxxxx
```

## Lancement

```bash
export GITHUB_TOKEN=$(cat .env | grep GITHUB_TOKEN | cut -d'=' -f2)
terraform init
terraform apply -var="github_token=$GITHUB_TOKEN" -var="project_name=mon-projet"
```

## Destruction

```bash
terraform destroy -var="github_token=$GITHUB_TOKEN" -var="project_name=mon-projet"
```
