<#
.SYNOPSIS
    Simulate rogue account creation (MITRE ATT&CK T1136.001).
.DESCRIPTION
    Creates a new domain user account to simulate persistence via account creation.
    Generates EventID 4720 (new user account created), triggering Wazuh rule 100005.
    The account is deleted at the end of the simulation as cleanup.
.TARGET
    Run from dc01 as Domain Admin.
.MITRE
    T1136.001 — Create Account: Local Account / Domain Account
.DETECTION
    EventID: 4720 (A user account was created)
    EventID: 4722 (A user account was enabled)
    Wazuh Rule: 100005
.CLEANUP
    Test account is deleted automatically at script end.
#>

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

Write-Host "=== Rogue Account Creation Simulation (T1136.001) ===" -ForegroundColor Red
Write-Host "WARNING: Run this only in your isolated lab environment." -ForegroundColor Yellow
Write-Host ""

# ============================================================
# CONFIGURATION
# ============================================================
$RogueUsername = "svc_backdoor"
$RoguePassword = "<YOUR_SIM_PASSWORD>"
$RogueDesc     = "Legitimate service account"  # Deceptive description (realistic simulation)
# ============================================================

$BaseDN     = "DC=corp,DC=techcorp,DC=internal"
$SecurePass = ConvertTo-SecureString $RoguePassword -AsPlainText -Force

# Step 1: Create the rogue account (generates EventID 4720)
Write-Host "[*] Creating rogue account: $RogueUsername..." -ForegroundColor Yellow
Write-Host "    Blending in as a 'service account' in Tier1 OU..." -ForegroundColor DarkGray

New-ADUser `
    -Name $RogueUsername `
    -SamAccountName $RogueUsername `
    -UserPrincipalName "$RogueUsername@corp.techcorp.internal" `
    -Path "OU=Tier1,$BaseDN" `
    -AccountPassword $SecurePass `
    -Description $RogueDesc `
    -Enabled $true `
    -PasswordNeverExpires $true

Write-Host "[+] Rogue account created: $RogueUsername" -ForegroundColor Green
Write-Host "[!] EventID 4720 generated — Wazuh Rule 100005 should fire." -ForegroundColor Magenta

# Pause for Wazuh detection
Start-Sleep -Seconds 5

# Optional: Add to a sensitive group to escalate impact
# Add-ADGroupMember -Identity 'Domain Admins' -Members $RogueUsername

# Step 2: Verify account exists
$Account = Get-ADUser -Identity $RogueUsername -Properties Description
Write-Host "`n[*] Account details:" -ForegroundColor Cyan
$Account | Select-Object Name, SamAccountName, Enabled, Description | Format-List

# Step 3: Cleanup
Write-Host "[*] Cleanup: deleting rogue account..." -ForegroundColor Cyan
Remove-ADUser -Identity $RogueUsername -Confirm:$false

Write-Host "[+] Rogue account deleted. Simulation complete." -ForegroundColor Green
Write-Host "[!] Check Wazuh dashboard for Rule 100005 / EventID 4720." -ForegroundColor Yellow
Write-Host "    Filter: rule.id:100005 or win.system.eventID:4720" -ForegroundColor DarkGray
