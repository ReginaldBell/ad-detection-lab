#!/usr/bin/env bash
# =============================================================================
# install-wazuh-server.sh
# Purpose : Install Wazuh 4.7.5 all-in-one on siem01 (Ubuntu 24.04 LTS)
# Target  : siem01 (192.168.56.103) — run as root or with sudo
# NOTE    : Ubuntu 24.04 is not officially supported by Wazuh 4.7.5.
#           The -i flag bypasses the OS compatibility check. Installation
#           works correctly despite the warning.
# =============================================================================

set -euo pipefail

echo "=== Wazuh 4.7.5 Installation (Ubuntu 24.04) ==="
echo "Using -i flag to bypass OS compatibility check..."
echo ""

# Update system packages
echo "[*] Updating system packages..."
apt-get update -qq && apt-get upgrade -y -qq

# Install dependencies
echo "[*] Installing dependencies..."
apt-get install -y curl tar

# Download the Wazuh all-in-one install script
echo "[*] Downloading Wazuh install script..."
curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh

# Verify the download
if [[ ! -f wazuh-install.sh ]]; then
    echo "ERROR: Failed to download wazuh-install.sh"
    exit 1
fi

chmod +x wazuh-install.sh

# Install Wazuh all-in-one (indexer + server + dashboard)
# -a  = all components
# -i  = ignore OS compatibility check (required for Ubuntu 24.04)
echo "[*] Installing Wazuh (this takes ~10 minutes)..."
bash wazuh-install.sh -a -i

echo ""
echo "=== Installation Complete ==="
echo "[+] Wazuh Dashboard: https://192.168.56.103"
echo "[+] Username: admin"
echo "[+] Password: (shown in output above — save it now)"
echo ""
echo "[*] Service management:"
echo "    sudo systemctl status wazuh-manager"
echo "    sudo systemctl restart wazuh-manager"
echo "    sudo systemctl status wazuh-indexer"
echo "    sudo systemctl status wazuh-dashboard"
