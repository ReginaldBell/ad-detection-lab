# Useful Commands

All key commands used throughout this lab, organized by category.

## Recommended Trail

Use this repo in the following order if you want the shortest path to a successful reproduction:

1. Host setup in [docs/02-prerequisites.md](../docs/02-prerequisites.md)
2. VM networking in [docs/03-network-configuration.md](../docs/03-network-configuration.md)
3. WinRM and optional Ansible connectivity in [docs/04-winrm-ansible-setup.md](../docs/04-winrm-ansible-setup.md)
4. AD buildout in [docs/05-active-directory-setup.md](../docs/05-active-directory-setup.md)
5. Wazuh install in [docs/06-wazuh-siem-setup.md](../docs/06-wazuh-siem-setup.md)
6. Agent enrollment in [docs/07-wazuh-agent-configuration.md](../docs/07-wazuh-agent-configuration.md)
7. Rule deployment in [docs/08-detection-rules.md](../docs/08-detection-rules.md)
8. Attack validation in [detections/attack-simulation-guide.md](../detections/attack-simulation-guide.md)

> The actual build path is manual VirtualBox + guest PowerShell, with Ansible used as an optional remote execution layer from WSL2.

---

## VirtualBox (Host PowerShell)

```powershell
# List all host-only interfaces
VBoxManage list hostonlyifs

# Show VM network adapter details
VBoxManage showvminfo <vmname> --details

# Get guest IP address
VBoxManage guestproperty get <vmname> /VirtualBox/GuestInfo/Net/0/V4/IP
```

---

## Network Configuration (Windows PowerShell — run as Administrator)

```powershell
# List all adapters with names
Get-NetAdapter | Select-Object Name, InterfaceDescription

# Assign a static IP
New-NetIPAddress -InterfaceAlias "Ethernet 2" -IPAddress 192.168.56.10 -PrefixLength 24

# Remove an existing IP (before reassigning)
Remove-NetIPAddress -InterfaceAlias "Ethernet 2" -Confirm:$false

# Set DNS server
Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ServerAddresses 192.168.56.10

# Disable IPv6 on an adapter
Disable-NetAdapterBinding -Name "Ethernet 2" -ComponentID ms_tcpip6

# Change network profile from Public to Private (required for WinRM)
Set-NetConnectionProfile -InterfaceAlias "Ethernet" -NetworkCategory Private

# Test connectivity
Test-Connection 192.168.56.10 -Count 2

# Verify DNS resolution
nslookup corp.techcorp.internal
```

---

## WinRM Setup (Windows PowerShell — run as Administrator)

```powershell
# Enable and configure WinRM
winrm quickconfig -Force

# Allow basic auth and unencrypted traffic (lab only)
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'

# Trust the lab subnet
Set-Item WSMan:\localhost\Client\TrustedHosts -Value '192.168.56.*' -Force

# Add firewall rule for WinRM on host-only subnet
New-NetFirewallRule -DisplayName "WinRM-Lab" -Direction Inbound -Protocol TCP -LocalPort 5985 -RemoteAddress 192.168.56.0/24 -Action Allow

# Verify WinRM listener
winrm enumerate winrm/config/listener

# Check auth config
winrm get winrm/config/service/auth

# Test WinRM from another host
Test-WSMan 192.168.56.10
```

---

## Ansible (WSL2 / Linux)

```bash
# Install Ansible and WinRM dependencies
pip3 install ansible pywinrm requests-credssp

# Verify Ansible version
ansible --version

# Test connectivity to all Windows hosts
ansible windows -i ansible/inventory.ini -m win_ping

# Test a single host
ansible dc01 -i ansible/inventory.ini -m win_ping

# Run a command on all domain controllers
ansible domain_controllers -i ansible/inventory.ini -m win_command -a "ipconfig"

# Run a PowerShell command
ansible windows -i ansible/inventory.ini -m win_shell -a "Get-ADUser -Filter * | Measure-Object"

# Copy a tracked PowerShell script, then run it remotely
ansible dc01 -i ansible/inventory.ini -m win_copy -a "src=scripts/powershell/05-promote-dc01.ps1 dest=C:\\Temp\\05-promote-dc01.ps1"
ansible dc01 -i ansible/inventory.ini -m win_shell -a "powershell -ExecutionPolicy Bypass -File C:\\Temp\\05-promote-dc01.ps1"

# Upgrade the microsoft.ad collection
ansible-galaxy collection install microsoft.ad --upgrade
```

Inventory note:
Use local admin credentials on hosts that are not domain-joined yet. After the domain exists and the workstation is joined, you can switch to domain credentials if preferred.

---

## Active Directory (PowerShell on DC01)

```powershell
# Install AD DS role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote as forest root (first DC)
Install-ADDSForest `
  -DomainName "corp.techcorp.internal" `
  -DomainNetbiosName "TECHCORP" `
  -ForestMode "WinThreshold" `
  -DomainMode "WinThreshold" `
  -InstallDns:$true `
  -SafeModeAdministratorPassword (ConvertTo-SecureString "YourPassword" -AsPlainText -Force) `
  -Force:$true

# Join a workstation to the domain
Add-Computer -DomainName "corp.techcorp.internal" -Credential (Get-Credential "TECHCORP\Administrator") -Restart

# List all users
Get-ADUser -Filter * | Select-Object Name, SamAccountName

# Count all users
(Get-ADUser -Filter *).Count

# List OUs
Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName

# Check domain controllers
Get-ADDomainController -Filter *

# List group members
Get-ADGroupMember -Identity "Domain Admins" | Select-Object Name
```

---

## Service Accounts & SPNs (PowerShell on DC01)

```powershell
# Register an SPN
setspn -A MSSQLSvc/dc01.corp.techcorp.internal:1433 svc_sql

# List SPNs for an account
setspn -L svc_sql

# Query all SPNs in the domain
setspn -T corp.techcorp.internal -Q */*

# Delete an SPN
setspn -D MSSQLSvc/dc01.corp.techcorp.internal:1433 svc_sql
```

---

## AD Replication & Diagnostics (PowerShell on DC01)

```powershell
# Replication summary
repadmin /replsummary

# Detailed replication status
repadmin /showrepl

# Force replication sync
repadmin /syncall /AdeP

# Run replication diagnostics
dcdiag /test:replications

# Force time sync (run on dc02 if skew is causing issues)
w32tm /resync /force
```

---

## Wazuh Agent (Windows PowerShell — run as Administrator)

```powershell
# Download agent installer
Invoke-WebRequest -Uri "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.7.5-1.msi" `
  -OutFile "C:\Temp\wazuh-agent.msi" -UseBasicParsing

# Install silently
msiexec.exe /i "C:\Temp\wazuh-agent.msi" /q `
  WAZUH_MANAGER="192.168.56.103" `
  WAZUH_REGISTRATION_SERVER="192.168.56.103" `
  WAZUH_AGENT_GROUP="windows"

# Start / stop / restart agent service
NET START WazuhSvc
NET STOP WazuhSvc
Restart-Service -Name WazuhSvc
```

---

## Wazuh Server (SSH into siem01)

```bash
# Install Wazuh (use -i to bypass OS version check on Ubuntu 24.04)
curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh
bash wazuh-install.sh -a -i

# Service status
sudo systemctl status wazuh-manager
sudo systemctl status wazuh-indexer
sudo systemctl status wazuh-dashboard

# Restart manager
sudo systemctl restart wazuh-manager

# List enrolled agents
sudo /var/ossec/bin/agent_control -l

# Live alert stream
sudo tail -f /var/ossec/logs/alerts/alerts.json

# Filter alerts for specific EventIDs
sudo tail -f /var/ossec/logs/alerts/alerts.json | grep -i "4769\|4625\|4720"

# Live archive log (all events, not just alerts)
sudo tail -f /var/ossec/logs/archives/archives.json

# Live manager log
sudo tail -f /var/ossec/logs/ossec.log

# Validate rule/config syntax
sudo /var/ossec/bin/wazuh-logtest

# Copy and set permissions for custom rules
sudo cp local_rules.xml /var/ossec/etc/rules/local_rules.xml
sudo chown root:wazuh /var/ossec/etc/rules/local_rules.xml
sudo chmod 660 /var/ossec/etc/rules/local_rules.xml

# Open Wazuh API port
sudo ufw allow 55000/tcp
```

---

## Attack Simulations (PowerShell on DC01 — lab only)

```powershell
# Kerberoasting — list all service accounts with SPNs
Get-ADUser -Filter {ServicePrincipalName -ne "$null"} `
  -Properties ServicePrincipalName, SamAccountName | `
  Select-Object SamAccountName, ServicePrincipalName

# Password spray — check for locked out accounts after simulation
Search-ADAccount -LockedOut | Select-Object Name

# Privilege escalation — verify test account removed after simulation
Get-ADUser -Filter {SamAccountName -eq "sim_escalation_test"}

# Lateral movement — verify drive mapping cleaned up
Get-PSDrive -Name Z -ErrorAction SilentlyContinue
```

---

## Ubuntu / WSL2

```bash
# Install WSL2 with Ubuntu
wsl --install -d Ubuntu

# Install Ansible and dependencies
sudo apt update && sudo apt install -y python3-pip
pip3 install ansible pywinrm requests-credssp

# Apply netplan network config
sudo netplan apply

# Check IP addresses
ip addr show
ip route show
```
