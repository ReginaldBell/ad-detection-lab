<#
.SYNOPSIS
    Configure static network settings for dc01 (Primary Domain Controller).
.DESCRIPTION
    Sets static IP 192.168.56.10 on the host-only adapter, configures DNS to point
    to itself, disables IPv6, and disables the unused NAT adapter.
.TARGET
    dc01 (192.168.56.10) — run in elevated PowerShell before AD DS promotion.
.NOTES
    Verify adapter aliases with: Get-NetAdapter
    Default VirtualBox adapter names: 'Ethernet' (NAT), 'Ethernet 2' (Host-Only)
#>

# -- Verify adapter names before running --
# Get-NetAdapter | Select-Object Name, InterfaceDescription

# Set static IP on host-only adapter
New-NetIPAddress `
    -InterfaceAlias 'Ethernet 2' `
    -IPAddress 192.168.56.10 `
    -PrefixLength 24 `
    -DefaultGateway 192.168.56.1

# Point DNS to itself (dc01 will host DNS)
Set-DnsClientServerAddress `
    -InterfaceAlias 'Ethernet 2' `
    -ServerAddresses 192.168.56.10

# Disable IPv6 on host-only adapter
Disable-NetAdapterBinding -Name 'Ethernet 2' -ComponentID ms_tcpip6

# Disable NAT adapter (no internet needed after initial setup)
Disable-NetAdapter -Name 'Ethernet' -Confirm:$false

Write-Host "dc01 network configuration complete." -ForegroundColor Green
Write-Host "IP: 192.168.56.10 | DNS: 192.168.56.10" -ForegroundColor Cyan
