# Section 4: WinRM & Ansible Setup

Configure WinRM on all Windows VMs to enable optional Ansible remote execution from WSL2.

> **WARNING:** These WinRM settings (Basic auth, unencrypted) are intentionally permissive for a **lab-only** isolated network. Never apply these settings on production systems.

> **Recommended path:** Run the tracked WinRM script locally on each Windows VM first. After WinRM is working, use Ansible from WSL2 to verify connectivity and optionally copy/run the tracked PowerShell scripts remotely.

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

Copy the template to `ansible/inventory.ini` and fill in the credentials that match your stage of the build:

- `dc01` and `dc02`: local `Administrator` before domain tasks, or domain admin after promotion
- `wkstn01`: the local admin account you created during Windows setup before domain join, or a domain admin after join

Example:

```ini
[domain_controllers]
dc01 ansible_host=192.168.56.10 ansible_user=Administrator
dc02 ansible_host=192.168.56.102 ansible_user=Administrator

[workstations]
wkstn01 ansible_host=192.168.56.20 ansible_user=<YOUR_WKSTN_ADMIN_USER>

[windows:children]
domain_controllers
workstations

[windows:vars]
ansible_password=<YOUR_PASSWORD>
ansible_connection=winrm
ansible_winrm_transport=basic
ansible_winrm_server_cert_validation=ignore
ansible_port=5985
```

## Recommended Ansible Usage In This Repo

This repo does not rely on tracked Ansible playbooks. The practical pattern is:

1. Configure networking manually on each VM
2. Run `04-winrm-setup.ps1` locally on each Windows VM
3. Verify connectivity with `win_ping`
4. Use `win_copy` and `win_shell` to run the tracked PowerShell scripts remotely when convenient

Example:

```bash
ansible dc01 -i ansible/inventory.ini -m win_copy -a "src=scripts/powershell/05-promote-dc01.ps1 dest=C:\\Temp\\05-promote-dc01.ps1"
ansible dc01 -i ansible/inventory.ini -m win_shell -a "powershell -ExecutionPolicy Bypass -File C:\\Temp\\05-promote-dc01.ps1"
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
