# ── Dépôt principal avec protection de branche ────
resource "github_repository" "app" {
  name        = "${var.project_name}-demo"
  description = "Dépôt géré par Terraform - DevOps 4A"
  visibility  = "public"

  has_issues   = true
  has_wiki     = true
  has_projects = true
  auto_init    = true # Initialise avec un README

  topics = ["terraform", "devops"]
}

# NOTE: Commenté car nécessite scope 'read:org' sur le token
# resource "github_branch_protection" "main" {
#   repository_id = github_repository.app.node_id
#   pattern       = "main"
#
#   required_pull_request_reviews {
#     required_approving_review_count = 1
#     dismiss_stale_reviews           = true
#   }
# }

resource "github_actions_secret" "db_url" {
  repository      = github_repository.app.name
  secret_name     = "DATABASE_URL"
  plaintext_value = var.db_url
}

# ── Deuxième dépôt sans wiki (exercice bonus) ──────
resource "github_repository" "app2" {
  name        = "${var.project_name}-api"
  description = "Dépôt API géré par Terraform - DevOps 4A"
  visibility  = "public"

  has_issues   = true
  has_wiki     = false # Sans wiki
  has_projects = false
  auto_init    = true

  topics = ["terraform", "api", "devops"]
}
