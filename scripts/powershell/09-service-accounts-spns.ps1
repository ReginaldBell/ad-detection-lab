<#
.SYNOPSIS
    Create service accounts and register SPNs for Kerberoasting simulation.
.DESCRIPTION
    Creates 5 service accounts in the Tier1 OU and registers Service Principal
    Names (SPNs) on each. SPNs make accounts vulnerable to Kerberoasting (T1558.003),
    enabling the attack simulation to request RC4-encrypted Kerberos tickets.
.TARGET
    dc01 (192.168.56.10) — run in elevated PowerShell.
.MITRE
    T1558.003 — Steal or Forge Kerberos Tickets: Kerberoasting
#>

# ============================================================
# CREDENTIALS — replace placeholder before running
# ============================================================
$SvcPassword = "<YOUR_SVC_PASSWORD>"
# ============================================================

$BaseDN     = "DC=corp,DC=techcorp,DC=internal"
$Tier1DN    = "OU=Tier1,$BaseDN"
$SecurePass = ConvertTo-SecureString $SvcPassword -AsPlainText -Force

# Service accounts with their SPNs
$ServiceAccounts = @(
    @{ Name = "svc_sql";        SPN = "MSSQLSvc/dc01.corp.techcorp.internal:1433" },
    @{ Name = "svc_backup";     SPN = "BackupAgent/dc01.corp.techcorp.internal"   },
    @{ Name = "svc_wazuh";      SPN = "WazuhAgent/siem01.corp.techcorp.internal"  },
    @{ Name = "svc_monitoring"; SPN = "MonitorSvc/dc01.corp.techcorp.internal"    },
    @{ Name = "svc_deploy";     SPN = "DeployAgent/dc01.corp.techcorp.internal"   }
)

foreach ($SA in $ServiceAccounts) {
    # Create account
    New-ADUser `
        -Name $SA.Name `
        -SamAccountName $SA.Name `
        -UserPrincipalName "$($SA.Name)@corp.techcorp.internal" `
        -Path $Tier1DN `
        -AccountPassword $SecurePass `
        -Enabled $true `
        -PasswordNeverExpires $true `
        -Description "Service account — Kerberoasting simulation target"

    # Register SPN
    setspn -A $SA.SPN $SA.Name
    Write-Host "Created: $($SA.Name) | SPN: $($SA.SPN)" -ForegroundColor Green
}

Write-Host "`nVerify SPNs: setspn -T corp.techcorp.internal -Q */*" -ForegroundColor Cyan
