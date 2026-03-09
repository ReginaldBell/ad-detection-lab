<#
.SYNOPSIS
    Create 1,800 bulk users across 9 departments in Tier2 OUs.
.DESCRIPTION
    Creates 200 users per department (9 departments = 1,800 users total).
    Users are placed in their respective department OUs under Tier2.
    All accounts are enabled with non-expiring passwords.
.TARGET
    dc01 (192.168.56.10) — run in elevated PowerShell after OU structure is created.
.PREREQUISITES
    - Run 07-create-ou-structure.ps1 first
    - Set <YOUR_USER_PASSWORD> below before running
.NOTE
    This script takes several minutes. Progress is shown per department.
#>

# ============================================================
# CREDENTIALS — replace placeholder before running
# ============================================================
$UserPassword = "<YOUR_USER_PASSWORD>"
# ============================================================

$BaseDN      = "DC=corp,DC=techcorp,DC=internal"
$Domain      = "corp.techcorp.internal"
$SecurePass  = ConvertTo-SecureString $UserPassword -AsPlainText -Force

$Departments = @(
    "IT", "HR", "Finance", "Legal",
    "Engineering", "Marketing", "Sales",
    "Operations", "Executive"
)

$TotalCreated = 0

foreach ($Dept in $Departments) {
    $OuPath = "OU=$Dept,OU=Tier2,$BaseDN"
    Write-Host "`nCreating users for $Dept..." -ForegroundColor Cyan

    for ($i = 1; $i -le 200; $i++) {
        $Username  = "$($Dept.ToLower())_user$i"
        $FullName  = "$Dept User$i"
        $UPN       = "$Username@$Domain"

        try {
            New-ADUser `
                -Name $FullName `
                -GivenName $Dept `
                -Surname "User$i" `
                -SamAccountName $Username `
                -UserPrincipalName $UPN `
                -Path $OuPath `
                -AccountPassword $SecurePass `
                -Enabled $true `
                -PasswordNeverExpires $true `
                -ErrorAction Stop

            $TotalCreated++
        } catch {
            Write-Warning "Failed to create $Username : $_"
        }
    }
    Write-Host "  $Dept: 200 users created" -ForegroundColor Green
}

Write-Host "`nBulk user creation complete. Total: $TotalCreated users" -ForegroundColor Cyan
Write-Host "Verify: (Get-ADUser -Filter *).Count"
