<#
.SYNOPSIS
    Configure WinRM for Ansible automation (lab use only).
.DESCRIPTION
    Enables WinRM, Basic auth, and unencrypted transport — permissive settings
    appropriate ONLY for an isolated host-only lab network. Also creates a
    firewall rule scoped to the lab subnet and sets trusted hosts.
.TARGET
    Run on dc01, dc02, and wkstn01 (each separately, in elevated PowerShell).
.WARNING
    NEVER apply these settings on production or internet-facing systems.
#>

# Enable WinRM service
winrm quickconfig -Force

# Enable Basic authentication (required by Ansible pywinrm)
winrm set winrm/config/service/auth '@{Basic="true"}'

# Allow unencrypted transport (lab-only — acceptable on isolated network)
winrm set winrm/config/service '@{AllowUnencrypted="true"}'

# Firewall rule — restrict WinRM to the lab subnet only
New-NetFirewallRule `
    -DisplayName 'WinRM-Lab' `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5985 `
    -RemoteAddress 192.168.56.0/24 `
    -Action Allow

# Trust all lab subnet hosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Value '192.168.56.*' -Force

# Confirm listener is active
Write-Host "`nWinRM listeners:" -ForegroundColor Cyan
winrm enumerate winrm/config/listener

Write-Host "`nWinRM setup complete. Test with: Test-WSMan 192.168.56.10" -ForegroundColor Green
