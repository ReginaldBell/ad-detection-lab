<#
.SYNOPSIS
    Configure static network settings for wkstn01 (Domain Workstation).
.DESCRIPTION
    Sets static IP 192.168.56.20, points DNS to dc01 for domain resolution.
.TARGET
    wkstn01 (192.168.56.20) — run in elevated PowerShell before domain join.
#>

New-NetIPAddress `
    -InterfaceAlias 'Ethernet 2' `
    -IPAddress 192.168.56.20 `
    -PrefixLength 24 `
    -DefaultGateway 192.168.56.1

# DNS must point to dc01 for domain join to succeed
Set-DnsClientServerAddress `
    -InterfaceAlias 'Ethernet 2' `
    -ServerAddresses 192.168.56.10

Disable-NetAdapterBinding -Name 'Ethernet 2' -ComponentID ms_tcpip6
Disable-NetAdapter -Name 'Ethernet' -Confirm:$false

Write-Host "wkstn01 network configuration complete." -ForegroundColor Green
Write-Host "IP: 192.168.56.20 | DNS: 192.168.56.10" -ForegroundColor Cyan
