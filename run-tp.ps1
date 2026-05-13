#===============================================================================
# TP DevOps Terraform & AWS - Script d'execution complet (Windows PowerShell)
# Ce script execute l'ensemble du TP etape par etape
#===============================================================================

param(
    [switch]$All,
    [switch]$Destroy,
    [switch]$AWS,
    [switch]$Docker,
    [switch]$GitHub,
    [switch]$Check,
    [switch]$Connect,    # Nouvelle option: connexion SSH à l'instance
    [switch]$Web,        # Nouvelle option: ouvrir la page web
    [switch]$Status      # Nouvelle option: afficher le statut
)

$ErrorActionPreference = "Continue"

# Charger le fichier .env si present
function Load-EnvFile($path) {
    if (Test-Path $path) {
        Get-Content $path | ForEach-Object {
            if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
                $name = $matches[1].Trim()
                $value = $matches[2].Trim()
                if ($value -ne "") {
                    [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
                }
            }
        }
        return $true
    }
    return $false
}

# Couleurs pour l'affichage
function Write-Header($message) {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Blue
    Write-Host "  $message" -ForegroundColor Blue
    Write-Host "================================================================" -ForegroundColor Blue
    Write-Host ""
}

function Write-Step($message) {
    Write-Host "[>] $message" -ForegroundColor Green
}

function Write-Warn($message) {
    Write-Host "[!] $message" -ForegroundColor Yellow
}

function Write-Err($message) {
    Write-Host "[X] $message" -ForegroundColor Red
}

function Write-Success($message) {
    Write-Host "[OK] $message" -ForegroundColor Green
}

# Chemin du script
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

#===============================================================================
# Creation des fichiers .env si absents
#===============================================================================
function Ensure-GitHubEnv {
    $envFile = "$ScriptDir\tp-github\.env"
    if (-not (Test-Path $envFile)) {
        Write-Warn "Fichier tp-github\.env non trouve"
        $token = Read-Host "Entrez votre GitHub Personal Access Token"
        if ([string]::IsNullOrWhiteSpace($token)) {
            return $false
        }
        Set-Content -Path $envFile -Value "GITHUB_TOKEN=$token"
        Write-Success "Fichier .env cree: $envFile"
    }
    return $true
}

function Ensure-AWSEnv {
    $envFile = "$ScriptDir\tp-terraform-aws\.env"
    if (-not (Test-Path $envFile)) {
        Write-Warn "Fichier tp-terraform-aws\.env non trouve"
        Write-Host ""
        $accessKey = Read-Host "AWS_ACCESS_KEY_ID"
        if ([string]::IsNullOrWhiteSpace($accessKey)) {
            return $false
        }
        $secretKey = Read-Host "AWS_SECRET_ACCESS_KEY"
        if ([string]::IsNullOrWhiteSpace($secretKey)) {
            return $false
        }
        $region = Read-Host "AWS_DEFAULT_REGION (defaut: eu-west-3)"
        if ([string]::IsNullOrWhiteSpace($region)) {
            $region = "eu-west-3"
        }

        $content = @"
AWS_ACCESS_KEY_ID=$accessKey
AWS_SECRET_ACCESS_KEY=$secretKey
AWS_DEFAULT_REGION=$region
"@
        Set-Content -Path $envFile -Value $content
        Write-Success "Fichier .env cree: $envFile"
    }
    return $true
}

#===============================================================================
# Verification des prerequis
#===============================================================================
function Check-Prerequisites {
    Write-Header "Verification des prerequis"

    # Terraform
    try {
        $tfVersion = terraform version | Select-Object -First 1
        Write-Success "Terraform installe: $tfVersion"
    } catch {
        Write-Err "Terraform n'est pas installe"
        return $false
    }

    # Docker
    try {
        $dockerInfo = docker info 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker installe et demarre"
        } else {
            Write-Warn "Docker installe mais le daemon n'est pas accessible"
        }
    } catch {
        Write-Warn "Docker n'est pas installe (exercice 2.1 ignore)"
    }

    # AWS CLI
    $awsCmd = "aws"
    if (Test-Path "C:\Program Files\Amazon\AWSCLIV2\aws.exe") {
        $awsCmd = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    }
    try {
        $awsVersion = & $awsCmd --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "AWS CLI installe: $awsVersion"
        } else {
            Write-Warn "AWS CLI n'est pas installe"
        }
    } catch {
        Write-Warn "AWS CLI n'est pas installe"
    }

    return $true
}

#===============================================================================
# EXERCICE 2.1 - Provider Docker
#===============================================================================
function Run-DockerExercise {
    Write-Header "EXERCICE 2.1 - Provider Docker"

    # Verifier Docker
    docker info 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Docker n'est pas demarre. Demarrez Docker Desktop d'abord."
        return
    }

    Push-Location "$ScriptDir\tp-docker"

    try {
        Write-Step "Initialisation de Terraform..."
        terraform init

        Write-Step "Validation de la configuration..."
        terraform validate

        Write-Step "Plan d'execution..."
        terraform plan

        Write-Step "Application de la configuration..."
        terraform apply -auto-approve

        Write-Step "Outputs:"
        terraform output

        Write-Step "Test de nginx..."
        Start-Sleep -Seconds 2
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 5
            Write-Success "Nginx repond! Status: $($response.StatusCode)"
        } catch {
            Write-Warn "Impossible de tester nginx"
        }

        Write-Success "Exercice Docker termine!"
    }
    catch {
        Write-Err "Erreur dans l'exercice Docker: $_"
    }
    finally {
        Pop-Location
    }
}

#===============================================================================
# EXERCICE 2.2 - Provider GitHub
#===============================================================================
function Run-GitHubExercise {
    Write-Header "EXERCICE 2.2 - Provider GitHub"

    # Creer .env si absent
    if (-not (Ensure-GitHubEnv)) {
        Write-Warn "Exercice GitHub ignore"
        return
    }

    # Charger le fichier .env
    $envFile = "$ScriptDir\tp-github\.env"
    if (Load-EnvFile $envFile) {
        Write-Success "Fichier .env charge"
    }

    if (-not $env:GITHUB_TOKEN) {
        Write-Err "GITHUB_TOKEN non defini dans le fichier .env"
        return
    }

    Push-Location "$ScriptDir\tp-github"

    try {
        Write-Step "Initialisation de Terraform..."
        terraform init

        Write-Step "Validation de la configuration..."
        terraform validate

        Write-Step "Plan d'execution..."
        terraform plan -var="project_name=tp-terraform-demo" -var="github_token=$env:GITHUB_TOKEN"

        Write-Step "Application de la configuration..."
        terraform apply -auto-approve -var="project_name=tp-terraform-demo" -var="github_token=$env:GITHUB_TOKEN"

        Write-Step "Outputs:"
        terraform output

        Write-Success "Exercice GitHub termine!"
    }
    catch {
        Write-Err "Erreur dans l'exercice GitHub: $_"
    }
    finally {
        Pop-Location
    }
}

#===============================================================================
# SECTION 3 - Infrastructure AWS
#===============================================================================
function Run-AWSInfrastructure {
    Write-Header "SECTION 3 - Infrastructure AWS"

    # Creer .env si absent
    if (-not (Ensure-AWSEnv)) {
        Write-Warn "Exercice AWS ignore"
        return
    }

    # Charger le fichier .env
    $envFile = "$ScriptDir\tp-terraform-aws\.env"
    if (Load-EnvFile $envFile) {
        Write-Success "Fichier .env charge"
    }

    # Chemin vers AWS CLI
    $awsCmd = "aws"
    if (Test-Path "C:\Program Files\Amazon\AWSCLIV2\aws.exe") {
        $awsCmd = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    }

    # Verifier AWS CLI
    & $awsCmd --version 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Err "AWS CLI n'est pas installe!"
        Write-Warn "Installez AWS CLI: https://aws.amazon.com/cli/"
        return
    }

    Push-Location "$ScriptDir\tp-terraform-aws"

    try {
        # Verifier les credentials AWS
        Write-Step "Verification des credentials AWS..."
        $identity = & $awsCmd sts get-caller-identity --output json 2>$null | ConvertFrom-Json
        if (-not $identity) {
            Write-Err "Credentials AWS non configures!"
            Write-Warn "Configurez AWS avec: aws configure"
            Pop-Location
            return
        }
        Write-Success "Credentials AWS OK: $($identity.Arn)"

        # Recuperer l'IP publique
        Write-Step "Recuperation de votre IP publique..."
        try {
            # Utiliser api.ipify.org qui retourne toujours une IP simple
            $myIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing -TimeoutSec 10).Content.Trim()
            $myIPCidr = "$myIP/32"
            Write-Success "Votre IP publique: $myIPCidr"
        } catch {
            Write-Err "Impossible de recuperer votre IP publique"
            Pop-Location
            return
        }

        # Verifier/Generer la cle SSH
        $sshKeyPath = "$env:USERPROFILE\.ssh\tp_terraform"
        $sshPubKeyPath = "$sshKeyPath.pub"

        if (-not (Test-Path $sshPubKeyPath)) {
            Write-Step "Generation de la cle SSH..."
            ssh-keygen -t ed25519 -C "tp-terraform" -f $sshKeyPath -N '""'
        } else {
            Write-Success "Cle SSH existante: $sshKeyPath"
        }

        Write-Step "Initialisation de Terraform..."
        terraform init

        Write-Step "Formatage du code..."
        terraform fmt

        Write-Step "Validation de la configuration..."
        terraform validate

        Write-Step "Plan d'execution..."
        terraform plan -var="my_ip=$myIPCidr"

        Write-Host ""
        $confirm = Read-Host "Voulez-vous appliquer cette configuration? (yes/no)"
        if ($confirm -ne "yes") {
            Write-Warn "Application annulee"
            Pop-Location
            return
        }

        Write-Step "Application de la configuration..."
        terraform apply -auto-approve -var="my_ip=$myIPCidr"

        Write-Step "Outputs:"
        terraform output

        # Recuperer l'IP de l'instance
        $instanceIP = terraform output -raw instance_public_ip 2>$null

        if ($instanceIP) {
            Write-Success "Infrastructure AWS creee!"
            Write-Host ""
            Write-Host "Pour vous connecter a l'instance:" -ForegroundColor Green
            Write-Host "  ssh -i ~/.ssh/tp_terraform ubuntu@$instanceIP" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Ou utilisez:" -ForegroundColor Green
            Write-Host "  .\run-tp.ps1 -Connect" -ForegroundColor Cyan
            Write-Host ""
        }
    }
    catch {
        Write-Err "Erreur dans l'infrastructure AWS: $_"
    }
    finally {
        Pop-Location
    }
}

#===============================================================================
# Connexion SSH a l'instance EC2
#===============================================================================
function Connect-ToInstance {
    Write-Header "CONNEXION SSH A L'INSTANCE EC2"

    # Charger le fichier .env
    Load-EnvFile "$ScriptDir\tp-terraform-aws\.env" | Out-Null

    Push-Location "$ScriptDir\tp-terraform-aws"

    try {
        # Verifier que l'infrastructure existe
        if (-not (Test-Path ".terraform")) {
            Write-Err "L'infrastructure n'est pas initialisee. Executez d'abord: .\run-tp.ps1 -AWS"
            Pop-Location
            return
        }

        # Recuperer l'IP de l'instance
        $instanceIP = terraform output -raw instance_public_ip 2>$null

        if ([string]::IsNullOrWhiteSpace($instanceIP)) {
            Write-Err "Aucune instance EC2 trouvee. Deployez d'abord l'infrastructure avec: .\run-tp.ps1 -AWS"
            Pop-Location
            return
        }

        $sshKeyPath = "$env:USERPROFILE\.ssh\tp_terraform"

        if (-not (Test-Path $sshKeyPath)) {
            Write-Err "Cle SSH non trouvee: $sshKeyPath"
            Write-Warn "Generez une cle avec: ssh-keygen -t ed25519 -f ~/.ssh/tp_terraform"
            Pop-Location
            return
        }

        Write-Success "Instance trouvee: $instanceIP"
        Write-Host ""
        Write-Host "Connexion en cours..." -ForegroundColor Cyan
        Write-Host ""

        # Lancer SSH
        & ssh -i $sshKeyPath -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "ubuntu@$instanceIP"
    }
    catch {
        Write-Err "Erreur de connexion: $_"
    }
    finally {
        Pop-Location
    }
}

#===============================================================================
# Ouvrir la page web
#===============================================================================
function Open-WebPage {
    Write-Header "OUVERTURE DE LA PAGE WEB"

    # Charger le fichier .env
    Load-EnvFile "$ScriptDir\tp-terraform-aws\.env" | Out-Null

    Push-Location "$ScriptDir\tp-terraform-aws"

    try {
        # Verifier que l'infrastructure existe
        if (-not (Test-Path ".terraform")) {
            Write-Err "L'infrastructure n'est pas initialisee. Executez d'abord: .\run-tp.ps1 -AWS"
            Pop-Location
            return
        }

        # Recuperer l'IP de l'instance
        $instanceIP = terraform output -raw instance_public_ip 2>$null

        if ([string]::IsNullOrWhiteSpace($instanceIP)) {
            Write-Err "Aucune instance EC2 trouvee. Deployez d'abord l'infrastructure avec: .\run-tp.ps1 -AWS"
            Pop-Location
            return
        }

        $url = "http://$instanceIP"
        Write-Success "Ouverture de: $url"
        Start-Process $url
    }
    catch {
        Write-Err "Erreur: $_"
    }
    finally {
        Pop-Location
    }
}

#===============================================================================
# Afficher le statut de l'infrastructure
#===============================================================================
function Show-Status {
    Write-Header "STATUT DE L'INFRASTRUCTURE"

    # Charger le fichier .env
    Load-EnvFile "$ScriptDir\tp-terraform-aws\.env" | Out-Null

    Push-Location "$ScriptDir\tp-terraform-aws"

    try {
        # Verifier que l'infrastructure existe
        if (-not (Test-Path ".terraform")) {
            Write-Warn "L'infrastructure n'est pas initialisee."
            Pop-Location
            return
        }

        Write-Step "Etat Terraform:"
        terraform show -no-color | Select-Object -First 50

        Write-Host ""
        Write-Step "Outputs:"
        terraform output

        Write-Host ""
        Write-Step "Ressources:"
        terraform state list
    }
    catch {
        Write-Err "Erreur: $_"
    }
    finally {
        Pop-Location
    }
}

#===============================================================================
# Destruction des ressources
#===============================================================================
function Destroy-All {
    Write-Header "DESTRUCTION DE TOUTES LES RESSOURCES"

    Write-Warn "Cette action va detruire TOUTES les ressources creees!"
    $confirm = Read-Host "Etes-vous sur? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Warn "Destruction annulee"
        return
    }

    # Charger les fichiers .env
    Load-EnvFile "$ScriptDir\tp-github\.env" | Out-Null
    Load-EnvFile "$ScriptDir\tp-terraform-aws\.env" | Out-Null

    # GitHub (en premier pour eviter les dependances)
    if (Test-Path "$ScriptDir\tp-github\.terraform") {
        Write-Step "Destruction des depots GitHub..."

        # Demander le token si absent
        if (-not $env:GITHUB_TOKEN) {
            $token = Read-Host "GITHUB_TOKEN requis pour la destruction. Entrez votre token"
            if (-not [string]::IsNullOrWhiteSpace($token)) {
                $env:GITHUB_TOKEN = $token
            }
        }

        if ($env:GITHUB_TOKEN) {
            Push-Location "$ScriptDir\tp-github"
            try {
                terraform destroy -auto-approve -var="project_name=tp-terraform-demo" -var="github_token=$env:GITHUB_TOKEN"
                Write-Success "Depots GitHub detruits"
            } catch {
                Write-Warn "Erreur lors de la destruction GitHub"
            }
            Pop-Location
        } else {
            Write-Warn "GITHUB_TOKEN non fourni, destruction GitHub ignoree"
        }
    }

    # AWS
    if (Test-Path "$ScriptDir\tp-terraform-aws\.terraform") {
        Write-Step "Destruction de l'infrastructure AWS..."
        Push-Location "$ScriptDir\tp-terraform-aws"
        try {
            $myIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing -TimeoutSec 10).Content.Trim()
            $myIPCidr = "$myIP/32"
            terraform destroy -auto-approve -var="my_ip=$myIPCidr"
        } catch {
            Write-Warn "Erreur lors de la destruction AWS"
        }
        Pop-Location
    }

    # Docker
    if (Test-Path "$ScriptDir\tp-docker\.terraform") {
        Write-Step "Destruction des containers Docker..."
        Push-Location "$ScriptDir\tp-docker"
        try {
            terraform destroy -auto-approve
        } catch {
            Write-Warn "Erreur lors de la destruction Docker"
        }
        Pop-Location
    }

    Write-Success "Destruction terminee!"
}

#===============================================================================
# Menu principal
#===============================================================================
function Show-Menu {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "  TP DevOps Terraform & AWS" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "1) Verifier les prerequis"
    Write-Host "2) Exercice 2.1 - Docker"
    Write-Host "3) Exercice 2.2 - GitHub"
    Write-Host "4) Section 3 - Infrastructure AWS"
    Write-Host "5) Executer TOUT le TP"
    Write-Host ""
    Write-Host "--- Actions rapides ---" -ForegroundColor Yellow
    Write-Host "6) Se connecter a l'instance EC2 (SSH)"
    Write-Host "7) Ouvrir la page web"
    Write-Host "8) Afficher le statut"
    Write-Host ""
    Write-Host "--- Nettoyage ---" -ForegroundColor Red
    Write-Host "9) Detruire toutes les ressources"
    Write-Host "0) Quitter"
    Write-Host ""

    $choice = Read-Host "Votre choix"

    switch ($choice) {
        "1" { Check-Prerequisites; Show-Menu }
        "2" { Run-DockerExercise; Show-Menu }
        "3" { Run-GitHubExercise; Show-Menu }
        "4" { Run-AWSInfrastructure; Show-Menu }
        "5" {
            Check-Prerequisites
            Run-DockerExercise
            Run-GitHubExercise
            Run-AWSInfrastructure
            Show-Menu
        }
        "6" { Connect-ToInstance; Show-Menu }
        "7" { Open-WebPage; Show-Menu }
        "8" { Show-Status; Show-Menu }
        "9" { Destroy-All; Show-Menu }
        "0" { return }
        default { Write-Err "Choix invalide"; Show-Menu }
    }
}

#===============================================================================
# Point d'entree
#===============================================================================
if ($All) {
    Check-Prerequisites
    Run-DockerExercise
    Run-GitHubExercise
    Run-AWSInfrastructure
}
elseif ($Destroy) {
    Destroy-All
}
elseif ($AWS) {
    Run-AWSInfrastructure
}
elseif ($Docker) {
    Run-DockerExercise
}
elseif ($GitHub) {
    Run-GitHubExercise
}
elseif ($Check) {
    Check-Prerequisites
}
elseif ($Connect) {
    Connect-ToInstance
}
elseif ($Web) {
    Open-WebPage
}
elseif ($Status) {
    Show-Status
}
else {
    Show-Menu
}
