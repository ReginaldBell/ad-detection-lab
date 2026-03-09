# Section 4: WinRM & Ansible Setup

Configure WinRM on all Windows VMs to enable Ansible automation from WSL2.

> **WARNING:** These WinRM settings (Basic auth, unencrypted) are intentionally permissive for a **lab-only** isolated network. Never apply these settings on production systems.

## Configure WinRM on Each Windows VM

Run the following on **dc01**, **dc02**, and **wkstn01**:

**Script:** [scripts/powershell/04-winrm-setup.ps1](../scripts/powershell/04-winrm-setup.ps1)

```powershell
# Enable WinRM
winrm quickconfig -Force

# Enable Basic authentication
winrm set winrm/config/service/auth '@{Basic="true"}'

# Allow unencrypted transport (lab only)
winrm set winrm/config/service '@{AllowUnencrypted="true"}'

# Firewall rule — allow WinRM only from the lab subnet
New-NetFirewallRule -DisplayName 'WinRM-Lab' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5985 `
    -RemoteAddress 192.168.56.0/24 `
    -Action Allow

# Trust all lab hosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Value '192.168.56.*' -Force
```

Verify WinRM is running:

```powershell
winrm enumerate winrm/config/listener
```

Expected output includes a listener on port 5985.

## Ansible Inventory

**File:** [ansible/inventory.ini.template](../ansible/inventory.ini.template)

Copy and fill in your credentials:

```ini
[domain_controllers]
dc01 ansible_host=192.168.56.10
dc02 ansible_host=192.168.56.102

[workstations]
wkstn01 ansible_host=192.168.56.20

[windows:children]
domain_controllers
workstations

[windows:vars]
ansible_user=Administrator
ansible_password=<YOUR_ADMIN_PASSWORD>
ansible_connection=winrm
ansible_winrm_transport=basic
ansible_winrm_server_cert_validation=ignore
ansible_port=5985
```

## Test Ansible Connectivity

From WSL2:

```bash
# Test all Windows hosts
ansible windows -i ansible/inventory.ini -m win_ping

# Expected output for each host:
# dc01 | SUCCESS => { "changed": false, "ping": "pong" }
```

## Troubleshooting WinRM

| Symptom | Fix |
|---|---|
| `Connection refused` on port 5985 | Run `winrm quickconfig -Force` again; check firewall rule |
| `AuthenticationError` | Verify Basic auth: `winrm get winrm/config/service/auth` |
| `Certificate error` | Set `ansible_winrm_server_cert_validation=ignore` |
| `Timeout` | Verify host-only network IP with `ipconfig` |
