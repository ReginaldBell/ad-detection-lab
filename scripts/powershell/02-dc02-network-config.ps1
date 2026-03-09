<#
.SYNOPSIS
    Configure static network settings for dc02 (Replica Domain Controller).
.DESCRIPTION
    Sets static IP 192.168.56.102, points DNS to primary DC (dc01), disables IPv6.
.TARGET
    dc02 (192.168.56.102) — run in elevated PowerShell before replica promotion.
#>

New-NetIPAddress `
    -InterfaceAlias 'Ethernet 2' `
    -IPAddress 192.168.56.102 `
    -PrefixLength 24 `
    -DefaultGateway 192.168.56.1

# Primary DNS = dc01, Secondary = self
Set-DnsClientServerAddress `
    -InterfaceAlias 'Ethernet 2' `
    -ServerAddresses 192.168.56.10, 192.168.56.102

Disable-NetAdapterBinding -Name 'Ethernet 2' -ComponentID ms_tcpip6
Disable-NetAdapter -Name 'Ethernet' -Confirm:$false

Write-Host "dc02 network configuration complete." -ForegroundColor Green
Write-Host "IP: 192.168.56.102 | DNS: 192.168.56.10 (primary), 192.168.56.102 (self)" -ForegroundColor Cyan
