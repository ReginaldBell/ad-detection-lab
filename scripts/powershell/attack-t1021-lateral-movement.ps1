<#
.SYNOPSIS
    Simulate lateral movement via SMB/explicit credentials (MITRE ATT&CK T1021.002).
.DESCRIPTION
    Uses explicit credentials (New-PSDrive / Invoke-Command) to connect to a remote
    host over SMB, simulating lateral movement. Generates EventID 4648 (explicit
    credential logon) on the source host and EventID 4624 on the target.
.TARGET
    Run from wkstn01 targeting dc01, or dc01 targeting wkstn01.
.MITRE
    T1021.002 — Remote Services: SMB/Windows Admin Shares
.DETECTION
    EventID: 4648 (Logon using explicit credentials)
    EventID: 4624 (Successful logon — logon type 3 = network)
    Wazuh Rule: 100004
.CLEANUP
    Drive mapping is removed at the end. No persistent changes.
#>

#Requires -Version 5.1

Write-Host "=== Lateral Movement Simulation (T1021.002) ===" -ForegroundColor Red
Write-Host "WARNING: Run this only in your isolated lab environment." -ForegroundColor Yellow
Write-Host ""

# ============================================================
# CONFIGURATION — set target and credentials
# ============================================================
$TargetHost  = "192.168.56.10"         # dc01
$AdminUser   = "TECHCORP\Administrator"
$AdminPass   = "<YOUR_ADMIN_PASSWORD>"
$DriveLetter = "Z"
# ============================================================

$SecurePass  = ConvertTo-SecureString $AdminPass -AsPlainText -Force
$Credential  = New-Object System.Management.Automation.PSCredential($AdminUser, $SecurePass)

# Step 1: Map admin share using explicit credentials (generates EventID 4648)
Write-Host "[*] Mapping \\$TargetHost\C$ with explicit credentials..." -ForegroundColor Cyan
Write-Host "    This generates EventID 4648 on this host." -ForegroundColor DarkGray

try {
    New-PSDrive `
        -Name $DriveLetter `
        -PSProvider FileSystem `
        -Root "\\$TargetHost\C$" `
        -Credential $Credential `
        -ErrorAction Stop | Out-Null

    Write-Host "[+] Drive mapped: ${DriveLetter}:\ → \\$TargetHost\C$" -ForegroundColor Green

    # Step 2: Access the remote filesystem
    Write-Host "[*] Listing remote C:\Windows\System32..." -ForegroundColor Cyan
    Get-ChildItem "${DriveLetter}:\Windows\System32" | Select-Object -First 5 | Format-Table Name

    # Step 3: Simulate remote command execution via WinRM
    Write-Host "[*] Executing remote command via Invoke-Command..." -ForegroundColor Cyan
    $Result = Invoke-Command -ComputerName $TargetHost -Credential $Credential -ScriptBlock {
        hostname; whoami; Get-Date
    }
    Write-Host "[+] Remote execution result:" -ForegroundColor Green
    $Result | ForEach-Object { Write-Host "    $_" }

} catch {
    Write-Warning "Lateral movement failed: $_"
} finally {
    # Cleanup: remove mapped drive
    if (Get-PSDrive -Name $DriveLetter -ErrorAction SilentlyContinue) {
        Remove-PSDrive -Name $DriveLetter -Force
        Write-Host "`n[*] Drive mapping removed (cleanup complete)." -ForegroundColor Cyan
    }
}

Write-Host "[!] Check Wazuh dashboard for Rule 100004 / EventID 4648." -ForegroundColor Yellow
Write-Host "    Filter: rule.id:100004 or win.system.eventID:4648" -ForegroundColor DarkGray
