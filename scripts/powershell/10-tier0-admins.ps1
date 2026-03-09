<#
.SYNOPSIS
    Create Tier0 privileged admin accounts and add to Domain Admins.
.DESCRIPTION
    Creates 5 named admin accounts (adm_*) in the Tier0 OU and adds each
    to the Domain Admins group. These accounts simulate real-world privileged
    identity targets for attack simulations (T1078, T1021.002).
.TARGET
    dc01 (192.168.56.10) — run in elevated PowerShell.
.MITRE
    T1078 — Valid Accounts (Privileged Account Abuse)
#>

# ============================================================
# CREDENTIALS — replace placeholder before running
# ============================================================
$AdminPassword = "<YOUR_TIER0_PASSWORD>"
# ============================================================

$BaseDN     = "DC=corp,DC=techcorp,DC=internal"
$Tier0DN    = "OU=Tier0,$BaseDN"
$SecurePass = ConvertTo-SecureString $AdminPassword -AsPlainText -Force

$Tier0Admins = @(
    "adm_jdoe",
    "adm_asmith",
    "adm_mbrown",
    "adm_kwilson",
    "adm_rjones"
)

foreach ($Admin in $Tier0Admins) {
    # Create privileged admin account in Tier0 OU
    New-ADUser `
        -Name $Admin `
        -SamAccountName $Admin `
        -UserPrincipalName "$Admin@corp.techcorp.internal" `
        -Path $Tier0DN `
        -AccountPassword $SecurePass `
        -Enabled $true `
        -PasswordNeverExpires $true `
        -Description "Tier0 privileged admin account"

    # Add to Domain Admins
    Add-ADGroupMember -Identity 'Domain Admins' -Members $Admin
    Write-Host "Created Tier0 admin: $Admin (added to Domain Admins)" -ForegroundColor Green
}

Write-Host "`nTier0 admin accounts created." -ForegroundColor Cyan
Write-Host "Verify: Get-ADGroupMember -Identity 'Domain Admins' | Select-Object Name"
