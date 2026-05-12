# Exercice 2.1 - Provider Docker

Déploiement de containers avec Terraform.

## Containers

- **nginx** : serveur web sur port 8080
- **redis** : cache sur port 6379

## Lancement

```bash
terraform init
terraform apply
```

## Test

```bash
curl http://localhost:8080
```

## Destruction

```bash
terraform destroy
```
