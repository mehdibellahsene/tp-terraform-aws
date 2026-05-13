#!/bin/bash
#===============================================================================
# TP DevOps Terraform & AWS - Script d'exécution complet (Linux/macOS)
# Ce script exécute l'ensemble du TP étape par étape
#===============================================================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Chemin du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#===============================================================================
# Fonctions d'affichage
#===============================================================================
print_header() {
    echo ""
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}[>] $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_err() {
    echo -e "${RED}[X] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[OK] $1${NC}"
}

#===============================================================================
# Chargement des fichiers .env
#===============================================================================
load_env_file() {
    local env_file="$1"
    if [[ -f "$env_file" ]]; then
        set -a
        source "$env_file"
        set +a
        return 0
    fi
    return 1
}

#===============================================================================
# Création des fichiers .env si absents
#===============================================================================
ensure_github_env() {
    local env_file="$SCRIPT_DIR/tp-github/.env"
    if [[ ! -f "$env_file" ]]; then
        print_warn "Fichier tp-github/.env non trouvé"
        read -p "Entrez votre GitHub Personal Access Token: " token
        if [[ -z "$token" ]]; then
            return 1
        fi
        echo "GITHUB_TOKEN=$token" > "$env_file"
        print_success "Fichier .env créé: $env_file"
    fi
    return 0
}

ensure_aws_env() {
    local env_file="$SCRIPT_DIR/tp-terraform-aws/.env"
    if [[ ! -f "$env_file" ]]; then
        print_warn "Fichier tp-terraform-aws/.env non trouvé"
        echo ""
        read -p "AWS_ACCESS_KEY_ID: " access_key
        if [[ -z "$access_key" ]]; then
            return 1
        fi
        read -p "AWS_SECRET_ACCESS_KEY: " secret_key
        if [[ -z "$secret_key" ]]; then
            return 1
        fi
        read -p "AWS_DEFAULT_REGION (défaut: eu-west-3): " region
        region="${region:-eu-west-3}"

        cat > "$env_file" << EOF
AWS_ACCESS_KEY_ID=$access_key
AWS_SECRET_ACCESS_KEY=$secret_key
AWS_DEFAULT_REGION=$region
EOF
        print_success "Fichier .env créé: $env_file"
    fi
    return 0
}

#===============================================================================
# Vérification des prérequis
#===============================================================================
check_prerequisites() {
    print_header "Vérification des prérequis"

    # Terraform
    if command -v terraform &> /dev/null; then
        tf_version=$(terraform version | head -n1)
        print_success "Terraform installé: $tf_version"
    else
        print_err "Terraform n'est pas installé"
        return 1
    fi

    # Docker
    if command -v docker &> /dev/null; then
        if docker info &> /dev/null; then
            print_success "Docker installé et démarré"
        else
            print_warn "Docker installé mais le daemon n'est pas accessible"
        fi
    else
        print_warn "Docker n'est pas installé (exercice 2.1 ignoré)"
    fi

    # AWS CLI
    if command -v aws &> /dev/null; then
        aws_version=$(aws --version 2>&1)
        print_success "AWS CLI installé: $aws_version"
    else
        print_warn "AWS CLI n'est pas installé"
    fi

    # tflint
    if command -v tflint &> /dev/null; then
        tflint_version=$(tflint --version)
        print_success "tflint installé: $tflint_version"
    else
        print_warn "tflint n'est pas installé (bonus ignoré)"
    fi

    return 0
}

#===============================================================================
# EXERCICE 2.1 - Provider Docker
#===============================================================================
run_docker_exercise() {
    print_header "EXERCICE 2.1 - Provider Docker"

    # Vérifier Docker
    if ! docker info &> /dev/null; then
        print_err "Docker n'est pas démarré. Démarrez Docker d'abord."
        return 1
    fi

    cd "$SCRIPT_DIR/tp-docker"

    print_step "Initialisation de Terraform..."
    terraform init

    print_step "Validation de la configuration..."
    terraform validate

    print_step "Plan d'exécution..."
    terraform plan

    print_step "Application de la configuration..."
    terraform apply -auto-approve

    print_step "Outputs:"
    terraform output

    print_step "Test de nginx..."
    sleep 2
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
        print_success "Nginx répond! Status: 200"
    else
        print_warn "Impossible de tester nginx"
    fi

    print_success "Exercice Docker terminé!"
    cd "$SCRIPT_DIR"
}

#===============================================================================
# EXERCICE 2.2 - Provider GitHub
#===============================================================================
run_github_exercise() {
    print_header "EXERCICE 2.2 - Provider GitHub"

    # Créer .env si absent
    if ! ensure_github_env; then
        print_warn "Exercice GitHub ignoré"
        return 1
    fi

    # Charger le fichier .env
    if load_env_file "$SCRIPT_DIR/tp-github/.env"; then
        print_success "Fichier .env chargé"
    fi

    if [[ -z "$GITHUB_TOKEN" ]]; then
        print_err "GITHUB_TOKEN non défini dans le fichier .env"
        return 1
    fi

    cd "$SCRIPT_DIR/tp-github"

    print_step "Initialisation de Terraform..."
    terraform init

    print_step "Validation de la configuration..."
    terraform validate

    print_step "Plan d'exécution..."
    terraform plan -var="project_name=tp-terraform-demo" -var="github_token=$GITHUB_TOKEN"

    print_step "Application de la configuration..."
    terraform apply -auto-approve -var="project_name=tp-terraform-demo" -var="github_token=$GITHUB_TOKEN"

    print_step "Outputs:"
    terraform output

    print_success "Exercice GitHub terminé!"
    cd "$SCRIPT_DIR"
}

#===============================================================================
# SECTION 3 - Infrastructure AWS
#===============================================================================
run_aws_infrastructure() {
    print_header "SECTION 3 - Infrastructure AWS"

    # Créer .env si absent
    if ! ensure_aws_env; then
        print_warn "Exercice AWS ignoré"
        return 1
    fi

    # Charger le fichier .env
    if load_env_file "$SCRIPT_DIR/tp-terraform-aws/.env"; then
        print_success "Fichier .env chargé"
    fi

    # Vérifier AWS CLI
    if ! command -v aws &> /dev/null; then
        print_err "AWS CLI n'est pas installé!"
        print_warn "Installez AWS CLI: https://aws.amazon.com/cli/"
        return 1
    fi

    cd "$SCRIPT_DIR/tp-terraform-aws"

    # Vérifier les credentials AWS
    print_step "Vérification des credentials AWS..."
    if ! aws sts get-caller-identity &> /dev/null; then
        print_err "Credentials AWS non configurés!"
        print_warn "Configurez AWS avec: aws configure"
        cd "$SCRIPT_DIR"
        return 1
    fi
    identity=$(aws sts get-caller-identity --output json)
    arn=$(echo "$identity" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)
    print_success "Credentials AWS OK: $arn"

    # Récupérer l'IP publique
    print_step "Récupération de votre IP publique..."
    my_ip=$(curl -s https://api.ipify.org)
    if [[ -z "$my_ip" ]]; then
        print_err "Impossible de récupérer votre IP publique"
        cd "$SCRIPT_DIR"
        return 1
    fi
    my_ip_cidr="${my_ip}/32"
    print_success "Votre IP publique: $my_ip_cidr"

    # Vérifier/Générer la clé SSH
    ssh_key_path="$HOME/.ssh/tp_terraform"
    ssh_pub_key_path="${ssh_key_path}.pub"

    if [[ ! -f "$ssh_pub_key_path" ]]; then
        print_step "Génération de la clé SSH..."
        ssh-keygen -t ed25519 -C "tp-terraform" -f "$ssh_key_path" -N ""
    else
        print_success "Clé SSH existante: $ssh_key_path"
    fi

    print_step "Initialisation de Terraform..."
    terraform init

    print_step "Formatage du code..."
    terraform fmt

    print_step "Validation de la configuration..."
    terraform validate

    print_step "Plan d'exécution..."
    terraform plan -var="my_ip=$my_ip_cidr"

    echo ""
    read -p "Voulez-vous appliquer cette configuration? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        print_warn "Application annulée"
        cd "$SCRIPT_DIR"
        return 0
    fi

    print_step "Application de la configuration..."
    terraform apply -auto-approve -var="my_ip=$my_ip_cidr"

    print_step "Outputs:"
    terraform output

    # Récupérer l'IP de l'instance
    instance_ip=$(terraform output -raw instance_public_ip 2>/dev/null || echo "")

    if [[ -n "$instance_ip" ]]; then
        print_success "Infrastructure AWS créée!"
        echo ""
        echo -e "${GREEN}Pour vous connecter à l'instance:${NC}"
        echo -e "${CYAN}  ssh -i ~/.ssh/tp_terraform ubuntu@$instance_ip${NC}"
        echo ""
        echo -e "${GREEN}Ou utilisez:${NC}"
        echo -e "${CYAN}  ./run-tp.sh connect${NC}"
        echo ""
    fi

    cd "$SCRIPT_DIR"
}

#===============================================================================
# Connexion SSH à l'instance EC2
#===============================================================================
connect_to_instance() {
    print_header "CONNEXION SSH À L'INSTANCE EC2"

    # Charger le fichier .env
    load_env_file "$SCRIPT_DIR/tp-terraform-aws/.env" || true

    cd "$SCRIPT_DIR/tp-terraform-aws"

    # Vérifier que l'infrastructure existe
    if [[ ! -d ".terraform" ]]; then
        print_err "L'infrastructure n'est pas initialisée. Exécutez d'abord: ./run-tp.sh aws"
        cd "$SCRIPT_DIR"
        return 1
    fi

    # Récupérer l'IP de l'instance
    instance_ip=$(terraform output -raw instance_public_ip 2>/dev/null || echo "")

    if [[ -z "$instance_ip" ]]; then
        print_err "Aucune instance EC2 trouvée. Déployez d'abord l'infrastructure avec: ./run-tp.sh aws"
        cd "$SCRIPT_DIR"
        return 1
    fi

    ssh_key_path="$HOME/.ssh/tp_terraform"

    if [[ ! -f "$ssh_key_path" ]]; then
        print_err "Clé SSH non trouvée: $ssh_key_path"
        print_warn "Générez une clé avec: ssh-keygen -t ed25519 -f ~/.ssh/tp_terraform"
        cd "$SCRIPT_DIR"
        return 1
    fi

    print_success "Instance trouvée: $instance_ip"
    echo ""
    echo -e "${CYAN}Connexion en cours...${NC}"
    echo ""

    # Lancer SSH
    ssh -i "$ssh_key_path" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "ubuntu@$instance_ip"

    cd "$SCRIPT_DIR"
}

#===============================================================================
# Ouvrir la page web
#===============================================================================
open_web_page() {
    print_header "OUVERTURE DE LA PAGE WEB"

    # Charger le fichier .env
    load_env_file "$SCRIPT_DIR/tp-terraform-aws/.env" || true

    cd "$SCRIPT_DIR/tp-terraform-aws"

    # Vérifier que l'infrastructure existe
    if [[ ! -d ".terraform" ]]; then
        print_err "L'infrastructure n'est pas initialisée. Exécutez d'abord: ./run-tp.sh aws"
        cd "$SCRIPT_DIR"
        return 1
    fi

    # Récupérer l'IP de l'instance
    instance_ip=$(terraform output -raw instance_public_ip 2>/dev/null || echo "")

    if [[ -z "$instance_ip" ]]; then
        print_err "Aucune instance EC2 trouvée. Déployez d'abord l'infrastructure avec: ./run-tp.sh aws"
        cd "$SCRIPT_DIR"
        return 1
    fi

    url="http://$instance_ip"
    print_success "URL: $url"

    # Ouvrir dans le navigateur selon l'OS
    if command -v xdg-open &> /dev/null; then
        xdg-open "$url"
    elif command -v open &> /dev/null; then
        open "$url"
    else
        print_warn "Impossible d'ouvrir le navigateur automatiquement"
        echo "Ouvrez manuellement: $url"
    fi

    cd "$SCRIPT_DIR"
}

#===============================================================================
# Afficher le statut de l'infrastructure
#===============================================================================
show_status() {
    print_header "STATUT DE L'INFRASTRUCTURE"

    # Charger le fichier .env
    load_env_file "$SCRIPT_DIR/tp-terraform-aws/.env" || true

    cd "$SCRIPT_DIR/tp-terraform-aws"

    # Vérifier que l'infrastructure existe
    if [[ ! -d ".terraform" ]]; then
        print_warn "L'infrastructure n'est pas initialisée."
        cd "$SCRIPT_DIR"
        return 0
    fi

    print_step "Outputs:"
    terraform output

    echo ""
    print_step "Ressources:"
    terraform state list

    cd "$SCRIPT_DIR"
}

#===============================================================================
# Exécuter tflint
#===============================================================================
run_tflint() {
    print_header "EXÉCUTION DE TFLINT"

    if ! command -v tflint &> /dev/null; then
        print_err "tflint n'est pas installé"
        print_warn "Installation: curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash"
        return 1
    fi

    cd "$SCRIPT_DIR/tp-terraform-aws"

    print_step "Initialisation de tflint..."
    tflint --init

    print_step "Analyse du code..."
    tflint

    print_success "Analyse tflint terminée!"
    cd "$SCRIPT_DIR"
}

#===============================================================================
# Destruction des ressources
#===============================================================================
destroy_all() {
    print_header "DESTRUCTION DE TOUTES LES RESSOURCES"

    print_warn "Cette action va détruire TOUTES les ressources créées!"
    read -p "Êtes-vous sûr? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        print_warn "Destruction annulée"
        return 0
    fi

    # Charger les fichiers .env
    load_env_file "$SCRIPT_DIR/tp-github/.env" || true
    load_env_file "$SCRIPT_DIR/tp-terraform-aws/.env" || true

    # GitHub
    if [[ -d "$SCRIPT_DIR/tp-github/.terraform" ]]; then
        print_step "Destruction des dépôts GitHub..."

        if [[ -z "$GITHUB_TOKEN" ]]; then
            read -p "GITHUB_TOKEN requis pour la destruction. Entrez votre token: " token
            if [[ -n "$token" ]]; then
                export GITHUB_TOKEN="$token"
            fi
        fi

        if [[ -n "$GITHUB_TOKEN" ]]; then
            cd "$SCRIPT_DIR/tp-github"
            terraform destroy -auto-approve -var="project_name=tp-terraform-demo" -var="github_token=$GITHUB_TOKEN" || true
            print_success "Dépôts GitHub détruits"
            cd "$SCRIPT_DIR"
        else
            print_warn "GITHUB_TOKEN non fourni, destruction GitHub ignorée"
        fi
    fi

    # AWS
    if [[ -d "$SCRIPT_DIR/tp-terraform-aws/.terraform" ]]; then
        print_step "Destruction de l'infrastructure AWS..."
        cd "$SCRIPT_DIR/tp-terraform-aws"
        my_ip=$(curl -s https://api.ipify.org)
        my_ip_cidr="${my_ip}/32"
        terraform destroy -auto-approve -var="my_ip=$my_ip_cidr" || true
        cd "$SCRIPT_DIR"
    fi

    # Docker
    if [[ -d "$SCRIPT_DIR/tp-docker/.terraform" ]]; then
        print_step "Destruction des containers Docker..."
        cd "$SCRIPT_DIR/tp-docker"
        terraform destroy -auto-approve || true
        cd "$SCRIPT_DIR"
    fi

    print_success "Destruction terminée!"
}

#===============================================================================
# Menu principal
#===============================================================================
show_menu() {
    echo ""
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}  TP DevOps Terraform & AWS${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo "1) Vérifier les prérequis"
    echo "2) Exercice 2.1 - Docker"
    echo "3) Exercice 2.2 - GitHub"
    echo "4) Section 3 - Infrastructure AWS"
    echo "5) Exécuter TOUT le TP"
    echo ""
    echo -e "${YELLOW}--- Actions rapides ---${NC}"
    echo "6) Se connecter à l'instance EC2 (SSH)"
    echo "7) Ouvrir la page web"
    echo "8) Afficher le statut"
    echo "9) Exécuter tflint"
    echo ""
    echo -e "${RED}--- Nettoyage ---${NC}"
    echo "10) Détruire toutes les ressources"
    echo "0) Quitter"
    echo ""

    read -p "Votre choix: " choice

    case $choice in
        1) check_prerequisites; show_menu ;;
        2) run_docker_exercise; show_menu ;;
        3) run_github_exercise; show_menu ;;
        4) run_aws_infrastructure; show_menu ;;
        5)
            check_prerequisites
            run_docker_exercise
            run_github_exercise
            run_aws_infrastructure
            show_menu
            ;;
        6) connect_to_instance; show_menu ;;
        7) open_web_page; show_menu ;;
        8) show_status; show_menu ;;
        9) run_tflint; show_menu ;;
        10) destroy_all; show_menu ;;
        0) exit 0 ;;
        *) print_err "Choix invalide"; show_menu ;;
    esac
}

#===============================================================================
# Affichage de l'aide
#===============================================================================
show_help() {
    echo "Usage: $0 [commande]"
    echo ""
    echo "Commandes disponibles:"
    echo "  check      Vérifier les prérequis"
    echo "  docker     Exécuter l'exercice Docker"
    echo "  github     Exécuter l'exercice GitHub"
    echo "  aws        Déployer l'infrastructure AWS"
    echo "  all        Exécuter tout le TP"
    echo "  connect    Se connecter en SSH à l'instance EC2"
    echo "  web        Ouvrir la page web dans le navigateur"
    echo "  status     Afficher le statut de l'infrastructure"
    echo "  lint       Exécuter tflint"
    echo "  destroy    Détruire toutes les ressources"
    echo "  help       Afficher cette aide"
    echo ""
    echo "Sans argument, le menu interactif est affiché."
}

#===============================================================================
# Point d'entrée
#===============================================================================
case "${1:-}" in
    check)
        check_prerequisites
        ;;
    docker)
        run_docker_exercise
        ;;
    github)
        run_github_exercise
        ;;
    aws)
        run_aws_infrastructure
        ;;
    all)
        check_prerequisites
        run_docker_exercise
        run_github_exercise
        run_aws_infrastructure
        ;;
    connect)
        connect_to_instance
        ;;
    web)
        open_web_page
        ;;
    status)
        show_status
        ;;
    lint)
        run_tflint
        ;;
    destroy)
        destroy_all
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        show_menu
        ;;
    *)
        print_err "Commande inconnue: $1"
        show_help
        exit 1
        ;;
esac
