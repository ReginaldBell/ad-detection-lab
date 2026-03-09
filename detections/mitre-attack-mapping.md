# MITRE ATT&CK Mapping

Full mapping of lab simulations to MITRE ATT&CK framework, detection artifacts, and Wazuh queries.

## Coverage Matrix

| # | ATT&CK ID | Technique | Sub-technique | Tactic | Script | Wazuh Rule | Level |
|---|---|---|---|---|---|---|---|
| 1 | T1558.003 | Steal or Forge Kerberos Tickets | Kerberoasting | Credential Access | `attack-t1558-kerberoasting.ps1` | 100001 | 12 |
| 2 | T1110.003 | Brute Force | Password Spraying | Credential Access | `attack-t1110-password-spray.ps1` | 100002 | 10 |
| 3 | T1078 | Valid Accounts | — | Privilege Escalation | `attack-t1078-privilege-escalation.ps1` | 100003 | 12 |
| 4 | T1021.002 | Remote Services | SMB/Windows Admin Shares | Lateral Movement | `attack-t1021-lateral-movement.ps1` | 100004 | 10 |
| 5 | T1136.001 | Create Account | Local Account | Persistence | `attack-t1136-rogue-account.ps1` | 100005 | 12 |

---

## Detailed Technique Reference

### T1558.003 — Kerberoasting

| Field | Value |
|---|---|
| **Tactic** | Credential Access (TA0006) |
| **Platform** | Windows |
| **Permissions Required** | Domain User |
| **Data Source** | Windows Security Log |
| **Key EventID** | 4769 (Kerberos Service Ticket Operations) |
| **Detection Indicator** | `TicketEncryptionType = 0x17` (RC4-HMAC — weak downgrade from AES) |
| **Wazuh Rule** | 100001 (Level 12) |
| **DQL Query** | `rule.id:100001` or `data.win.system.eventID:4769 AND data.win.eventdata.ticketEncryptionType:0x17` |
| **False Positives** | Legacy applications requiring RC4; Windows Server 2008 DCs |
| **Remediation** | Disable RC4 support on service accounts; use Group Policy to enforce AES only |

**ATT&CK Navigator:** Credential Access → Steal or Forge Kerberos Tickets → Kerberoasting

---

### T1110.003 — Password Spraying

| Field | Value |
|---|---|
| **Tactic** | Credential Access (TA0006) |
| **Platform** | Windows |
| **Permissions Required** | None (attempts only) |
| **Data Source** | Windows Security Log |
| **Key EventID** | 4625 (An account failed to log on) |
| **Detection Indicator** | Multiple 4625 events across different accounts from the same source IP within 60 seconds |
| **Wazuh Rule** | 100002 (Level 10, frequency=10, timeframe=60) |
| **DQL Query** | `rule.id:100002` or `data.win.system.eventID:4625` |
| **False Positives** | Users forgetting passwords; expired passwords causing application retries |
| **Remediation** | Account lockout policy (threshold ≤5); MFA; FIDO2 for privileged accounts |

---

### T1078 — Valid Accounts (Privilege Escalation)

| Field | Value |
|---|---|
| **Tactic** | Privilege Escalation (TA0004), Persistence (TA0003) |
| **Platform** | Windows |
| **Permissions Required** | Domain Admin (to modify group membership) |
| **Data Source** | Windows Security Log |
| **Key EventID** | 4728 (Member added to global security group) |
| **Detection Indicator** | Subject added to `Domain Admins` group |
| **Wazuh Rule** | 100003 (Level 12) |
| **DQL Query** | `rule.id:100003` or `data.win.system.eventID:4728 AND data.win.eventdata.targetUserName:"Domain Admins"` |
| **False Positives** | Authorized admin onboarding |
| **Remediation** | Alert on all Domain Admins changes; Just-In-Time (JIT) privileged access |

---

### T1021.002 — SMB/Windows Admin Shares (Lateral Movement)

| Field | Value |
|---|---|
| **Tactic** | Lateral Movement (TA0008) |
| **Platform** | Windows |
| **Permissions Required** | Domain User with SMB access |
| **Data Source** | Windows Security Log |
| **Key EventID** | 4648 (Logon with explicit credentials), 4624 Logon Type 3 |
| **Detection Indicator** | 4648 with `TargetServerName` ≠ localhost |
| **Wazuh Rule** | 100004 (Level 10) |
| **DQL Query** | `rule.id:100004` or `data.win.system.eventID:4648` |
| **False Positives** | Admins using `runas`, mapped network drives, legitimate remote management |
| **Remediation** | Disable admin shares; require PAW for privileged remote tasks; network segmentation |

---

### T1136.001 — Create Account (Persistence)

| Field | Value |
|---|---|
| **Tactic** | Persistence (TA0003) |
| **Platform** | Windows |
| **Permissions Required** | Domain Admin |
| **Data Source** | Windows Security Log |
| **Key EventID** | 4720 (A user account was created), 4722 (enabled) |
| **Detection Indicator** | New account creation outside of approved provisioning workflow |
| **Wazuh Rule** | 100005 (Level 12) |
| **DQL Query** | `rule.id:100005` or `data.win.system.eventID:4720` |
| **False Positives** | Authorized HR onboarding; service account provisioning |
| **Remediation** | Restrict account creation to specific privileged OUs; alert on all 4720 events |

---

## Wazuh Dashboard DQL Quick Reference

```
# All custom lab alerts
rule.id: [100001 TO 100005]

# By tactic
rule.groups: credential_access
rule.groups: lateral_movement
rule.groups: privilege_escalation
rule.groups: persistence

# High severity only (level 12)
rule.level: 12

# Time-bounded search (last 1 hour)
rule.id: [100001 TO 100005] AND @timestamp: [now-1h TO now]

# By agent (specific VM)
agent.name: DC01 AND rule.id: [100001 TO 100005]
```
