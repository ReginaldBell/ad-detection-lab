# Active Directory Detection Lab

A hands-on homelab simulating a small enterprise Active Directory environment for practicing real-world attack techniques and blue team detection engineering. Built from scratch using VirtualBox, Ansible automation, PowerShell scripting, and Wazuh SIEM — fully documented with 86 build screenshots covering every step including troubleshooting.

> **WARNING:** Isolated lab environment only. All credentials are placeholders — never reuse lab passwords in any production or internet-facing system.

---

## Architecture

![Enterprise AD Detection Lab Architecture](architecture/lab-architecture-diagram.png)

> Source: [architecture/lab-architecture-diagram.drawio](architecture/lab-architecture-diagram.drawio)

### Network

| VM | Hostname | IP Address | OS | RAM | vCPU | Role |
|---|---|---|---|---|---|---|
| dc01 | DC01 | 192.168.56.10 | Windows Server 2022 | 4 GB | 2 | Primary DC, DNS, FSMO holder |
| dc02 | DC02 | 192.168.56.102 | Windows Server 2022 | 2 GB | 2 | Replica DC |
| wkstn01 | WKSTN01 | 192.168.56.20 | Windows 10 Pro 22H2 | 4 GB | 2 | Domain-joined workstation, attack surface |
| siem01 | siem01 | 192.168.56.103 | Ubuntu 24.04 LTS | 4 GB | 2 | Wazuh 4.7.5 SIEM server |

- **Hypervisor:** VirtualBox 7.x — Host-Only Adapter (`192.168.56.0/24`), DHCP disabled, all static IPs
- **Domain FQDN:** `corp.techcorp.internal` | **NetBIOS:** `TECHCORP` | **Forest/Domain Mode:** Windows Server 2016
- **DNS:** dc01 (`192.168.56.10`) — all VMs point here

See [architecture/network-topology.md](architecture/network-topology.md) for the full port and adapter reference.

### Domain Structure

- **1,800 domain users** spread across 9 OUs: IT, HR, Finance, Legal, Engineering, Marketing, Sales, Operations, Executive
- **Tier model:** Tier0 (5 privileged admins), Tier1 (5 service accounts with SPNs), Tier2 (workstations and bulk users)
- **Service accounts with SPNs:** `svc_sql`, `svc_backup`, `svc_wazuh`, `svc_monitoring`, `svc_deploy` — intentionally Kerberoastable
- **Dual DC HA:** dc01 is the forest root and FSMO holder; dc02 is a replica DC for replication testing

---

## Tech Stack

| Component | Version | Purpose |
|---|---|---|
| VirtualBox | 7.x | Hypervisor — hosts all 4 VMs |
| Windows Server 2022 | — | Domain Controllers (dc01, dc02) |
| Windows 10 Pro | 22H2 | Domain workstation — attack surface |
| Ubuntu Server | 24.04 LTS | Wazuh SIEM host |
| Wazuh | 4.7.5 | SIEM, XDR, detection rules, MITRE dashboard |
| Ansible | 2.20.3 | Windows automation via WinRM from WSL2 |
| PowerShell | 5.1 | AD provisioning, attack simulation scripts |
| WSL2 (Ubuntu) | - | Ansible control node on Windows host |
| Sysmon | — | Process, network, and file event logging on Windows VMs |

---

## MITRE ATT&CK Coverage

| # | Technique | ID | Tactic | Windows Event IDs | Wazuh Rule |
|---|---|---|---|---|---|
| 1 | Kerberoasting | T1558.003 | Credential Access | 4769 (RC4 ticket request) | 100001 |
| 2 | Password Spray | T1110.003 | Credential Access | 4625 (logon failure) | 100002 |
| 3 | Privilege Escalation (valid accounts) | T1078 | Privilege Escalation | 4728 (Domain Admins group membership) | 100003 |
| 4 | Lateral Movement via SMB | T1021.002 | Lateral Movement | 4648 (explicit credential logon) | 100004 |
| 5 | Rogue Account Creation | T1136.001 | Persistence | 4720 (account created) | 100005 |

Each technique has a corresponding PowerShell simulation script in [scripts/powershell/](scripts/powershell/) and a custom Wazuh detection rule in [scripts/config/local_rules.xml](scripts/config/local_rules.xml).

---

## How It Works

### Infrastructure Provisioning
This lab is provisioned manually in VirtualBox on a host-only network adapter at `192.168.56.0/24`. Windows VMs boot from ISO and are manually installed; Ubuntu (siem01) is installed from the Ubuntu Server 24.04 ISO.

### Automation & Configuration
**Ansible** (run from WSL2) is used in this repo as a connectivity and remote-execution layer via WinRM. The tracked repo includes sample inventory data plus the PowerShell scripts used for:
- Promoting dc01 as forest root and dc02 as replica DC
- Creating the full OU structure, 1,800 bulk users, service accounts, and SPNs
- Joining wkstn01 to the domain
- Installing and registering Wazuh agents on all Windows VMs

### Detection Pipeline
1. **Wazuh agents** on dc01, dc02, and wkstn01 forward Security event logs to siem01 via port 1514
2. **ossec.conf** on each agent includes a localfile block capturing Windows Security channel events
3. **Custom rules** in `local_rules.xml` map specific event IDs and conditions to MITRE ATT&CK technique IDs
4. **Attack simulation scripts** generate real telemetry (Kerberos ticket requests, failed logons, SMB share access, new accounts) which appear in the Wazuh MITRE ATT&CK dashboard

---

## Detection Examples

Sample Wazuh alert output for two of the five techniques. All five techniques follow the same pattern — see [detections/mitre-attack-mapping.md](detections/mitre-attack-mapping.md) for the full reference.

### Kerberoasting (T1558.003) — Rule 100001

Triggered when an EventID 4769 arrives with `ticketEncryptionType = 0x17` (RC4). AES-only environments should never see this value.

```json
{
  "rule": {
    "id": "100001",
    "level": 12,
    "description": "Possible Kerberoasting: RC4 Kerberos service ticket requested (T1558.003)",
    "groups": ["attack", "kerberoasting", "credential_access"]
  },
  "agent": { "name": "WKSTN01", "ip": "192.168.56.20" },
  "data": {
    "win": {
      "system":    { "eventID": "4769", "computer": "DC01.corp.techcorp.internal" },
      "eventdata": {
        "serviceName":          "svc_sql",
        "ticketEncryptionType": "0x17",
        "clientAddress":        "192.168.56.20"
      }
    }
  }
}
```

**Wazuh DQL:** `rule.id:100001`
**Pivot:** filter `agent.ip:192.168.56.20` to see all 5 SPN requests from the same source within seconds of each other.

---

### Password Spray (T1110.003) — Rule 100002

Triggered when 10+ EventID 4625 (failed logon) events arrive from the same source IP within 60 seconds. The frequency/timeframe counters are built into the Wazuh rule.

```json
{
  "rule": {
    "id": "100002",
    "level": 10,
    "description": "Password spray detected: 10+ failed logons from same source IP within 60s (T1110.003)",
    "groups": ["attack", "password_spray", "credential_access"]
  },
  "agent": { "name": "DC01", "ip": "192.168.56.10" },
  "data": {
    "win": {
      "system":    { "eventID": "4625" },
      "eventdata": {
        "ipAddress":    "192.168.56.20",
        "targetUserName": "hr_user7",
        "logonType":    "3"
      }
    }
  }
}
```

**Wazuh DQL:** `rule.id:100002`
**Pivot:** run `agent.name:DC01 AND data.win.system.eventID:4625` to see every individual failed attempt that fed the aggregation.

---

## Investigation Walkthrough — Kerberoasting Alert

A full triage-to-close example using a Kerberoasting alert fired in this lab.

### 1. Alert triage

Open the Wazuh Security Events dashboard and filter:

```
rule.id:100001
```

You see **5 alerts** arrive within 3 seconds, all sourced from `192.168.56.20` (WKSTN01). Each alert targets a different service account SPN — a pattern consistent with automated SPN enumeration, not a single application making a legitimate service ticket request.

| # | ServiceName | EncryptionType | ClientAddress | Time |
|---|---|---|---|---|
| 1 | svc_sql | 0x17 | 192.168.56.20 | 14:32:01 |
| 2 | svc_backup | 0x17 | 192.168.56.20 | 14:32:01 |
| 3 | svc_wazuh | 0x17 | 192.168.56.20 | 14:32:02 |
| 4 | svc_monitoring | 0x17 | 192.168.56.20 | 14:32:02 |
| 5 | svc_deploy | 0x17 | 192.168.56.20 | 14:32:03 |

**Key questions at this stage:**
- Is `192.168.56.20` a known asset? Yes — WKSTN01, domain-joined workstation.
- Is RC4 expected in this environment? No — domain is configured for AES.
- Is the velocity (5 SPNs, 2 seconds) consistent with legitimate use? No.

### 2. Scope the source host

Pivot to the agent `WKSTN01` and widen the time window by 15 minutes before the alert:

```
agent.name:WKSTN01 AND @timestamp:[now-15m TO now]
```

Look for:
- **4624 Logon Type 2/10** — who logged in interactively before the spray?
- **4688 Process Creation** — any `powershell.exe` with encoded command or unusual parent process?
- **7045 Service Install** — any new services or tooling dropped?

In the lab simulation, you'll see a PowerShell process spawned from `explorer.exe` shortly before the 4769 events — a human operator running the simulation script.

### 3. Confirm the technique

Run the DC-side corroboration query on dc01:

```
agent.name:DC01 AND data.win.system.eventID:4769 AND data.win.eventdata.ticketEncryptionType:0x17
```

DC01 is the KDC — all ticket requests are logged here. Confirm the same 5 requests appear in DC01's logs, originating from `192.168.56.20`. This cross-agent correlation proves the ticket requests reached the domain controller, not just that a local event fired.

### 4. Assess impact

Kerberoasting is **offline credential theft**. The attacker already has the ticket hashes by the time the alert fires — the question is whether any service account password is weak enough to crack.

Check the service accounts targeted:

```powershell
# On dc01 — review password age for Kerberoastable accounts
Get-ADUser -Filter {ServicePrincipalName -ne "$null"} -Properties PasswordLastSet, ServicePrincipalName |
  Select-Object SamAccountName, PasswordLastSet, ServicePrincipalName
```

If any service account has a password older than 90 days or set at account creation, treat it as potentially compromised and rotate immediately.

### 5. Containment and response

| Action | Command / Location |
|---|---|
| Rotate targeted svc account passwords | AD Users & Computers or `Set-ADAccountPassword` |
| Disable RC4 on service accounts | AD → Account tab → uncheck "Use DES encryption types" / enforce AES via GPO |
| Isolate WKSTN01 if compromise confirmed | VirtualBox → disable host-only adapter |
| Check for Pass-the-Ticket follow-on | Filter for EventID 4768/4769/4770 from the same source in the next 30 min |

### 6. Document the finding

```
Title:       Kerberoasting Attempt — WKSTN01 → DC01
Technique:   T1558.003
Time:        2026-03-14 14:32:01 UTC
Source:      192.168.56.20 (WKSTN01)
Target:      5 service accounts (svc_sql, svc_backup, svc_wazuh, svc_monitoring, svc_deploy)
Evidence:    Wazuh rule 100001 fired x5, EventID 4769, EncType 0x17
Impact:      RC4 ticket hashes exposed — offline cracking possible
Containment: Passwords rotated, RC4 disabled via GPO
Status:      Resolved (lab simulation — no real compromise)
```

---

## Quick Start

1. [Lab architecture overview](docs/01-architecture.md)
2. [Prerequisites & software requirements](docs/02-prerequisites.md)
3. [Network configuration (VirtualBox)](docs/03-network-configuration.md)
4. [WinRM & Ansible setup](docs/04-winrm-ansible-setup.md)
5. [Active Directory setup](docs/05-active-directory-setup.md)
6. [Wazuh SIEM deployment](docs/06-wazuh-siem-setup.md)
7. [Wazuh agent & log configuration](docs/07-wazuh-agent-configuration.md)
8. [Detection rules](docs/08-detection-rules.md)
9. [Troubleshooting](docs/09-troubleshooting.md)
10. [Extensions & next steps](docs/10-extensions.md)
11. [Run attack simulations](detections/attack-simulation-guide.md)

**Reference:**
- [Useful Commands](docs/useful-commands.md) — all key commands used across this lab
- [Common Issues & Fixes](docs/common-issues.md) — real errors encountered with screenshots and solutions

---

## Repository Structure

```
ad-detection-lab/
├── README.md
├── LICENSE
├── .gitignore
├── architecture/
│   ├── lab-architecture-diagram.png     # Architecture diagram
│   ├── lab-architecture-diagram.drawio  # Editable source
│   └── network-topology.md              # Full network, IP, and port reference
├── docs/                                # Step-by-step setup guides (10 sections)
│   ├── 01-architecture.md
│   ├── 02-prerequisites.md
│   ├── 03-network-configuration.md
│   ├── 04-winrm-ansible-setup.md
│   ├── 05-active-directory-setup.md
│   ├── 06-wazuh-siem-setup.md
│   ├── 07-wazuh-agent-configuration.md
│   ├── 08-detection-rules.md
│   ├── 09-troubleshooting.md
│   ├── 10-extensions.md
│   ├── common-issues.md                 # 19 real issues with fixes and screenshots
│   └── useful-commands.md               # All key commands by category
├── scripts/
│   ├── powershell/                      # AD setup + 5 attack simulation scripts
│   ├── bash/                            # Wazuh server install and config scripts
│   └── config/                          # ossec.conf snippet + local_rules.xml
├── detections/
│   ├── attack-simulation-guide.md
│   └── mitre-attack-mapping.md
├── screenshots/                         # 86 sequential build log screenshots
│   └── README.md                        # Phase-by-phase index with ⚠️/✅ markers
└── ansible/
    ├── inventory.ini                    # Sanitized sample inventory (no credentials)
    └── inventory.ini.template           # WinRM inventory template (no credentials)
```

---

## Screenshots

86 sequential screenshots document the complete build - from host preparation and prerequisites through Wazuh detection results. Includes real troubleshooting: WinRM errors, network misconfigurations, Ansible failures, and AD replication issues.

See [screenshots/README.md](screenshots/README.md) for the full phase-by-phase index.

---

## Reproducibility

- Tracked inventory examples are sanitized — add credentials locally before use
- Real ISO paths, credentials, and host-specific values stay local and untracked

---

## License

MIT — see [LICENSE](LICENSE)

