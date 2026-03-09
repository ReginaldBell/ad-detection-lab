<#
.SYNOPSIS
    Install AD DS and promote dc02 as a replica domain controller.
.DESCRIPTION
    Joins dc02 to corp.techcorp.internal as a replica DC with DNS.
    VM reboots automatically after promotion.
.TARGET
    dc02 (192.168.56.102) — run in elevated PowerShell.
.PREREQUISITES
    - dc01 promoted and reachable at 192.168.56.10
    - dc02 network configured (run 02-dc02-network-config.ps1 first)
    - Set credentials below before running
#>

# ============================================================
# CREDENTIALS — replace placeholders before running
# ============================================================
$AdminUser    = "TECHCORP\Administrator"
$AdminPass    = "<YOUR_ADMIN_PASSWORD>"
$DSRMPassword = "<YOUR_DSRM_PASSWORD>"
# ============================================================

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

$Credential = New-Object System.Management.Automation.PSCredential(
    $AdminUser,
    (ConvertTo-SecureString $AdminPass -AsPlainText -Force)
)

Install-ADDSDomainController `
    -DomainName 'corp.techcorp.internal' `
    -InstallDns:$true `
    -Credential $Credential `
    -SafeModeAdministratorPassword (ConvertTo-SecureString $DSRMPassword -AsPlainText -Force) `
    -Force:$true

# VM reboots here automatically
