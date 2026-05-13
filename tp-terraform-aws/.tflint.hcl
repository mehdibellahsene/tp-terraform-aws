# ══════════════════════════════════════════════════════════════════════════════
# Configuration tflint - Linter Terraform (BONUS)
# ══════════════════════════════════════════════════════════════════════════════
#
# tflint détecte les erreurs de configuration Terraform et AWS.
#
# Installation :
#   Windows: choco install tflint
#   Mac:     brew install tflint
#   Linux:   curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
#
# Usage :
#   tflint --init     # Télécharge les plugins
#   tflint            # Lance l'analyse
#   tflint --fix      # Corrige les erreurs automatiquement (si possible)
#
# ══════════════════════════════════════════════════════════════════════════════

# ── Configuration globale ─────────────────────────────────────────────────────

config {
  # Format de sortie : default, json, checkstyle, junit, compact, sarif
  format = "compact"

  # Active tous les plugins par défaut
  plugin_dir = "~/.tflint.d/plugins"

  # Force l'exécution même si des modules sont manquants
  force = false

  # Exclure certains répertoires
  ignore_module = {}
}

# ── Plugin AWS ────────────────────────────────────────────────────────────────

plugin "aws" {
  enabled = true
  version = "0.31.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"

  # Région par défaut pour la validation
  region = "eu-west-3"
}

# ── Plugin Terraform (règles de base) ─────────────────────────────────────────

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# ── Règles personnalisées ─────────────────────────────────────────────────────

# Vérifier que les types d'instances sont valides
rule "aws_instance_invalid_type" {
  enabled = true
}

# Vérifier que les AMIs sont valides
rule "aws_instance_invalid_ami" {
  enabled = true
}

# Vérifier les security groups
rule "aws_security_group_invalid_protocol" {
  enabled = true
}

# Éviter les security groups trop permissifs (0.0.0.0/0 sur SSH)
rule "aws_security_group_rule_invalid_cidr_block" {
  enabled = true
}

# Vérifier les noms de ressources
rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

# Vérifier que toutes les variables ont une description
rule "terraform_documented_variables" {
  enabled = true
}

# Vérifier que tous les outputs ont une description
rule "terraform_documented_outputs" {
  enabled = true
}

# Vérifier l'utilisation de versions épinglées pour les providers
rule "terraform_required_providers" {
  enabled = true
}

# Vérifier la présence de required_version
rule "terraform_required_version" {
  enabled = true
}

# Éviter les ressources dépréciées
rule "terraform_deprecated_index" {
  enabled = true
}

# Détecter les variables non utilisées
rule "terraform_unused_declarations" {
  enabled = true
}

# Vérifier le formatage (terraform fmt)
rule "terraform_standard_module_structure" {
  enabled = true
}
