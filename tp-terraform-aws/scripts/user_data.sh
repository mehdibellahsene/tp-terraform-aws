#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# User Data - Script de bootstrap EC2 (BONUS)
# ══════════════════════════════════════════════════════════════════════════════
#
# Ce script est exécuté automatiquement au premier démarrage de l'instance EC2.
# Il installe et configure nginx comme serveur web.
#
# Les logs de ce script sont disponibles dans :
#   /var/log/cloud-init-output.log
#
# ══════════════════════════════════════════════════════════════════════════════

set -e  # Arrêter en cas d'erreur

# ── Variables ─────────────────────────────────────────────────────────────────
LOG_FILE="/var/log/user-data.log"
HOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/hostname)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# ── Logging ───────────────────────────────────────────────────────────────────
exec > >(tee -a "$LOG_FILE") 2>&1
echo "=========================================="
echo "User Data Script - $(date)"
echo "Hostname: $HOSTNAME"
echo "Public IP: $PUBLIC_IP"
echo "=========================================="

# ── Mise à jour du système ────────────────────────────────────────────────────
echo "[1/5] Mise à jour du système..."
apt-get update -y
apt-get upgrade -y

# ── Installation de nginx ─────────────────────────────────────────────────────
echo "[2/5] Installation de nginx..."
apt-get install -y nginx

# ── Configuration de nginx ────────────────────────────────────────────────────
echo "[3/5] Configuration de nginx..."

cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TP Terraform - AWS EC2</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 600px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
            text-align: center;
        }
        h1 {
            color: #1a202c;
            font-size: 2.5rem;
            margin-bottom: 10px;
        }
        .subtitle {
            color: #718096;
            font-size: 1.1rem;
            margin-bottom: 30px;
        }
        .info {
            background: #f7fafc;
            border-radius: 10px;
            padding: 20px;
            margin: 20px 0;
            text-align: left;
        }
        .info-item {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #e2e8f0;
        }
        .info-item:last-child { border-bottom: none; }
        .info-label { color: #4a5568; font-weight: 500; }
        .info-value { color: #2d3748; font-family: monospace; }
        .badge {
            display: inline-block;
            background: #48bb78;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9rem;
            margin-top: 20px;
        }
        .footer {
            margin-top: 30px;
            color: #a0aec0;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>TP Terraform</h1>
        <p class="subtitle">Infrastructure AWS avec Terraform - DevOps S8</p>

        <div class="info">
            <div class="info-item">
                <span class="info-label">Instance</span>
                <span class="info-value">$HOSTNAME</span>
            </div>
            <div class="info-item">
                <span class="info-label">IP Publique</span>
                <span class="info-value">$PUBLIC_IP</span>
            </div>
            <div class="info-item">
                <span class="info-label">Région</span>
                <span class="info-value">eu-west-3 (Paris)</span>
            </div>
            <div class="info-item">
                <span class="info-label">OS</span>
                <span class="info-value">Ubuntu 24.04 LTS</span>
            </div>
            <div class="info-item">
                <span class="info-label">Type</span>
                <span class="info-value">t3.micro</span>
            </div>
        </div>

        <span class="badge">Déployé avec Terraform</span>

        <p class="footer">
            Infrastructure as Code - EFREI Paris
        </p>
    </div>
</body>
</html>
EOF

# ── Démarrage de nginx ────────────────────────────────────────────────────────
echo "[4/5] Démarrage de nginx..."
systemctl enable nginx
systemctl start nginx
systemctl status nginx

# ── Installation d'outils utiles ──────────────────────────────────────────────
echo "[5/5] Installation d'outils supplémentaires..."
apt-get install -y \
    curl \
    wget \
    vim \
    htop \
    tree \
    jq \
    unzip

# ── Vérification finale ───────────────────────────────────────────────────────
echo "=========================================="
echo "Installation terminée avec succès!"
echo "Nginx version: $(nginx -v 2>&1)"
echo "Page web disponible sur: http://$PUBLIC_IP"
echo "=========================================="

# ── Signal de fin ─────────────────────────────────────────────────────────────
touch /tmp/user-data-complete
