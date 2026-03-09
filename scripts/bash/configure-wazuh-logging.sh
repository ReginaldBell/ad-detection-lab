#!/usr/bin/env bash
# =============================================================================
# configure-wazuh-logging.sh
# Purpose : Enable full archive logging on the Wazuh manager (siem01).
#           Logs all raw events to /var/ossec/logs/archives/ in JSON format.
# Target  : siem01 (192.168.56.103) — run as root or with sudo
# =============================================================================

set -euo pipefail

OSSEC_CONF="/var/ossec/etc/ossec.conf"
BACKUP_CONF="${OSSEC_CONF}.bak.$(date +%Y%m%d_%H%M%S)"

echo "=== Wazuh Archive Logging Configuration ==="

# Backup current config
echo "[*] Backing up ossec.conf to $BACKUP_CONF..."
cp "$OSSEC_CONF" "$BACKUP_CONF"

# Check if logall is already enabled
if grep -q "<logall>yes</logall>" "$OSSEC_CONF"; then
    echo "[!] Archive logging already enabled. No changes made."
else
    echo "[*] Enabling logall and logall_json in ossec.conf..."

    # Insert logall settings into the <global> block
    sed -i 's|</global>|  <logall>yes</logall>\n  <logall_json>yes</logall_json>\n</global>|' "$OSSEC_CONF"

    echo "[+] Archive logging enabled."
fi

# Validate the config file is valid XML
echo "[*] Validating ossec.conf..."
/var/ossec/bin/wazuh-logtest -t 2>/dev/null || true

# Restart Wazuh manager to apply changes
echo "[*] Restarting wazuh-manager..."
systemctl restart wazuh-manager

# Wait and verify
sleep 3
if systemctl is-active --quiet wazuh-manager; then
    echo "[+] wazuh-manager restarted successfully."
else
    echo "ERROR: wazuh-manager failed to start. Restoring backup..."
    cp "$BACKUP_CONF" "$OSSEC_CONF"
    systemctl restart wazuh-manager
    exit 1
fi

echo ""
echo "=== Archive Logging Active ==="
echo "[+] Raw events logged to: /var/ossec/logs/archives/archives.json"
echo "[+] Monitor live: sudo tail -f /var/ossec/logs/archives/archives.json"
echo "[+] Filter alerts: sudo tail -f /var/ossec/logs/alerts/alerts.json"
