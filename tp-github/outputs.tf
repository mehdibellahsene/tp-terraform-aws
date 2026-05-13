output "repo_url" {
  description = "URL du dépôt principal"
  value       = github_repository.app.html_url
}

output "repo_clone_url" {
  description = "URL de clonage du dépôt principal"
  value       = github_repository.app.http_clone_url
}

output "repo2_url" {
  description = "URL du deuxième dépôt"
  value       = github_repository.app2.html_url
}

output "repo2_clone_url" {
  description = "URL de clonage du deuxième dépôt"
  value       = github_repository.app2.http_clone_url
}
