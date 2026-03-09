<#
.SYNOPSIS
    Create the tiered OU structure for corp.techcorp.internal.
.DESCRIPTION
    Creates three top-level tier OUs (Tier0, Tier1, Tier2) and nine department
    sub-OUs under Tier2. All OUs are protected from accidental deletion.
.TARGET
    dc01 (192.168.56.10) — run in elevated PowerShell after AD DS promotion.
#>

$BaseDN = "DC=corp,DC=techcorp,DC=internal"

# --- Top-level tier OUs ---
$Tiers = @("Tier0", "Tier1", "Tier2")

foreach ($Tier in $Tiers) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$Tier'" -SearchBase $BaseDN -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $Tier -Path $BaseDN -ProtectedFromAccidentalDeletion $true
        Write-Host "Created OU: $Tier" -ForegroundColor Green
    } else {
        Write-Host "OU already exists: $Tier" -ForegroundColor Yellow
    }
}

# --- Department sub-OUs under Tier2 ---
$Departments = @(
    "IT", "HR", "Finance", "Legal",
    "Engineering", "Marketing", "Sales",
    "Operations", "Executive"
)

$Tier2DN = "OU=Tier2,$BaseDN"

foreach ($Dept in $Departments) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$Dept'" -SearchBase $Tier2DN -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $Dept -Path $Tier2DN -ProtectedFromAccidentalDeletion $true
        Write-Host "Created OU: $Dept (under Tier2)" -ForegroundColor Green
    } else {
        Write-Host "OU already exists: $Dept" -ForegroundColor Yellow
    }
}

Write-Host "`nOU structure creation complete." -ForegroundColor Cyan
Write-Host "Verify with: Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName"
