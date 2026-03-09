# Attack Simulation Guide

Step-by-step instructions for running all 5 MITRE ATT&CK simulations, verifying Wazuh detection, and cleaning up.

> **Prerequisites:**
> - Lab fully provisioned (all VMs running, Wazuh agents active)
> - Wazuh dashboard accessible at `https://192.168.56.103`
> - Credentials set in each script (replace `<YOUR_*_PASSWORD>` placeholders)
> - Run simulations one at a time to keep alerts clean and attributable

---

## Pre-Simulation Checklist

- [ ] All 3 Windows agents show **Active** in Wazuh dashboard → Agents
- [ ] Wazuh Security Events page is open and updating
- [ ] Custom rules 100001–100005 are deployed (`local_rules.xml` in place)
- [ ] ossec.conf localfile block deployed on all Windows VMs

---

## Simulation 1: Kerberoasting (T1558.003)

**Script:** `scripts/powershell/attack-t1558-kerberoasting.ps1`
**Run on:** wkstn01 or dc01 (any domain user context)

### Steps

1. Open PowerShell on wkstn01 as a domain user
2. Run:
   ```powershell
   .\attack-t1558-kerberoasting.ps1
   ```
3. Script enumerates SPNs and requests RC4 service tickets

### Expected Output
```
[+] Found 5 Kerberoastable accounts
[+] Ticket requested for: MSSQLSvc/dc01.corp.techcorp.internal:1433
[+] Ticket requested for: BackupAgent/dc01.corp.techcorp.internal
...
```

### Expected Wazuh Alert
- **Rule:** 100001 | **Level:** 12
- **EventID:** 4769
- **Field:** `win.eventdata.ticketEncryptionType = 0x17`

### Dashboard Verification
```
rule.id:100001
```
Look for 5 alerts (one per SPN), all from the source IP of wkstn01.

### Cleanup
No persistent changes. Kerberos tickets expire per domain ticket lifetime policy.

---

## Simulation 2: Password Spray (T1110.003)

**Script:** `scripts/powershell/attack-t1110-password-spray.ps1`
**Run on:** wkstn01 or dc01

### Steps

1. Edit script: confirm `$SprayPassword`, `$MaxAccounts = 15`, `$DelaySeconds = 1`
2. Run:
   ```powershell
   .\attack-t1110-password-spray.ps1
   ```
3. Script attempts `Winter2024!` against 15 domain user accounts

### Expected Output
```
[-] Failed: it_user1
[-] Failed: it_user2
...
[*] Spray complete. 15/15 accounts failed (expected).
```

### Expected Wazuh Alert
- **Rule:** 100002 | **Level:** 10
- **Trigger:** 10+ EventID 4625 from same source IP in 60 seconds

### Dashboard Verification
```
rule.id:100002
```
Check source IP matches wkstn01 (192.168.56.20).

### Cleanup
No account lockouts if `$MaxAccounts` stays ≤15 and default lockout threshold is 10+. Verify:
```powershell
Search-ADAccount -LockedOut | Select-Object Name
```

---

## Simulation 3: Privilege Escalation (T1078)

**Script:** `scripts/powershell/attack-t1078-privilege-escalation.ps1`
**Run on:** dc01 (as Domain Admin)

### Steps

1. Edit script: set `$TestPassword` placeholder
2. Run:
   ```powershell
   .\attack-t1078-privilege-escalation.ps1
   ```
3. Script creates `sim_escalation_test` user → adds to Domain Admins → removes → deletes account

### Expected Wazuh Alert
- **Rule:** 100003 | **Level:** 12
- **EventID:** 4728 (Group: Domain Admins)

### Dashboard Verification
```
rule.id:100003
```
Alert shows `TargetUserName: Domain Admins` and `MemberName: sim_escalation_test`.

### Cleanup
Script handles cleanup automatically (account deleted). Verify:
```powershell
Get-ADUser -Filter {SamAccountName -eq "sim_escalation_test"} -ErrorAction SilentlyContinue
```
Should return nothing.

---

## Simulation 4: Lateral Movement via SMB (T1021.002)

**Script:** `scripts/powershell/attack-t1021-lateral-movement.ps1`
**Run on:** wkstn01 (targeting dc01)

### Steps

1. Edit script: set `$AdminPass` placeholder
2. Run:
   ```powershell
   .\attack-t1021-lateral-movement.ps1
   ```
3. Script maps `\\192.168.56.10\C$` with explicit credentials and runs a remote command

### Expected Wazuh Alerts
- **Rule:** 100004 | **Level:** 10
- **EventID 4648** on wkstn01 (explicit credential logon)
- **EventID 4624** on dc01 (Logon Type 3 — network logon)

### Dashboard Verification
```
rule.id:100004
```
Source: wkstn01 | Target: dc01 (192.168.56.10).

### Cleanup
Script removes the drive mapping automatically. No persistent changes.

---

## Simulation 5: Rogue Account Creation (T1136.001)

**Script:** `scripts/powershell/attack-t1136-rogue-account.ps1`
**Run on:** dc01 (as Domain Admin)

### Steps

1. Edit script: set `$RoguePassword` placeholder
2. Run:
   ```powershell
   .\attack-t1136-rogue-account.ps1
   ```
3. Script creates `svc_backdoor` in Tier1 OU → pauses 5s → deletes account

### Expected Wazuh Alert
- **Rule:** 100005 | **Level:** 12
- **EventID:** 4720 (A user account was created)

### Dashboard Verification
```
rule.id:100005
```
Alert shows `TargetUserName: svc_backdoor`, creator = Administrator.

### Cleanup
Script deletes the account automatically. Verify:
```powershell
Get-ADUser -Filter {SamAccountName -eq "svc_backdoor"} -ErrorAction SilentlyContinue
```

---

## Post-Simulation: Writing an IR Report

Practice your documentation for each simulation:

| Section | Content |
|---|---|
| **What happened** | Technique name, ATT&CK ID, method used |
| **When** | Timestamp of first alert |
| **Source** | Source IP / hostname |
| **Target** | Target account, host, or service |
| **Evidence** | EventID, Wazuh rule ID, alert level |
| **Impact** | Potential impact if this was a real attack |
| **Containment** | What would you do to stop it? |
| **Remediation** | How to prevent recurrence? |

See [docs/10-extensions.md](../docs/10-extensions.md) for SOC scenario practice tickets.
