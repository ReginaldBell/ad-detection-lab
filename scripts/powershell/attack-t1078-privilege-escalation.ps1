<#
.SYNOPSIS
    Simulate privilege escalation via group membership manipulation (MITRE ATT&CK T1078).
.DESCRIPTION
    Creates a test user, adds them to Domain Admins (generating EventID 4728),
    then immediately removes them and deletes the account as cleanup.
    Wazuh rule 100003 triggers on the Domain Admins membership change.
.TARGET
    Run from dc01 as Domain Admin.
.MITRE
    T1078 — Valid Accounts (Privileged Account Abuse)
.DETECTION
    EventID: 4728 (Member added to global security group — Domain Admins)
    EventID: 4672 (Special privileges assigned to new logon)
    Wazuh Rule: 100003
.CLEANUP
    Script removes the test account automatically at the end.
#>

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

Write-Host "=== Privilege Escalation Simulation (T1078) ===" -ForegroundColor Red
Write-Host "WARNING: Run this only in your isolated lab environment." -ForegroundColor Yellow
Write-Host ""

# ============================================================
# CONFIGURATION
# ============================================================
$TestAccountName = "sim_escalation_test"
$TestPassword    = "<YOUR_SIM_PASSWORD>"
# ============================================================

$BaseDN     = "DC=corp,DC=techcorp,DC=internal"
$SecurePass = ConvertTo-SecureString $TestPassword -AsPlainText -Force

# Step 1: Create a low-privilege test user
Write-Host "[*] Creating test user: $TestAccountName..." -ForegroundColor Cyan
New-ADUser `
    -Name $TestAccountName `
    -SamAccountName $TestAccountName `
    -Path "OU=Tier2,$BaseDN" `
    -AccountPassword $SecurePass `
    -Enabled $true

# Step 2: Add to Domain Admins — generates EventID 4728 (triggers Rule 100003)
Write-Host "[*] Adding $TestAccountName to Domain Admins (EventID 4728)..." -ForegroundColor Yellow
Add-ADGroupMember -Identity 'Domain Admins' -Members $TestAccountName

Write-Host "[+] $TestAccountName added to Domain Admins." -ForegroundColor Green
Write-Host "[!] EventID 4728 generated — Wazuh Rule 100003 should fire now." -ForegroundColor Magenta

# Pause so Wazuh has time to detect
Start-Sleep -Seconds 5

# Step 3: Cleanup — remove from group and delete account
Write-Host "`n[*] Cleanup: removing $TestAccountName from Domain Admins..." -ForegroundColor Cyan
Remove-ADGroupMember -Identity 'Domain Admins' -Members $TestAccountName -Confirm:$false

Write-Host "[*] Deleting test account..." -ForegroundColor Cyan
Remove-ADUser -Identity $TestAccountName -Confirm:$false

Write-Host "[+] Cleanup complete." -ForegroundColor Green
Write-Host "[!] Check Wazuh dashboard for Rule 100003 alert." -ForegroundColor Yellow
Write-Host "    Filter: rule.id:100003 or win.system.eventID:4728" -ForegroundColor DarkGray
