<#
.SYNOPSIS
    Install AD DS and promote dc01 as the forest root domain controller.
.DESCRIPTION
    Installs the AD-Domain-Services role then creates a new forest:
    corp.techcorp.internal (NetBIOS: TECHCORP) at Windows Server 2016 functional level.
    VM reboots automatically after promotion.
.TARGET
    dc01 (192.168.56.10) — run in elevated PowerShell.
.PREREQUISITES
    - Static IP configured (run 01-dc01-network-config.ps1 first)
    - Set <YOUR_DSRM_PASSWORD> below before running
#>

# ============================================================
# CREDENTIALS — replace placeholder before running
# ============================================================
$DSRMPassword = "<YOUR_DSRM_PASSWORD>"
# ============================================================

# Install AD DS role with management tools
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote to forest root DC
Install-ADDSForest `
    -DomainName 'corp.techcorp.internal' `
    -DomainNetbiosName 'TECHCORP' `
    -ForestMode 'WinThreshold' `
    -DomainMode 'WinThreshold' `
    -InstallDns:$true `
    -SafeModeAdministratorPassword (ConvertTo-SecureString $DSRMPassword -AsPlainText -Force) `
    -Force:$true

# VM reboots here automatically
