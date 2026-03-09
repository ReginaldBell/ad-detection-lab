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
| dc01 | DC01 | 192.168.56.10 | Windows Server 2016 | 4 GB | 2 | Primary DC, DNS, FSMO holder |
| dc02 | DC02 | 192.168.56.102 | Windows Server 2016 | 2 GB | 2 | Replica DC |
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
| Windows Server 2016 | — | Domain Controllers (dc01, dc02) |
| Windows 10 Pro | 22H2 | Domain workstation — attack surface |
| Ubuntu Server | 24.04 LTS | Wazuh SIEM host |
| Wazuh | 4.7.5 | SIEM, XDR, detection rules, MITRE dashboard |
| Ansible | 2.20.3 | Windows automation via WinRM from WSL2 |
| Terraform | 1.14.6 | VM provisioning (infrastructure as code) |
| PowerShell | 5.1 | AD provisioning, attack simulation scripts |
| WSL2 (Ubuntu) | — | Ansible and Terraform control node on Windows host |
| Sysmon | — | Process, network, and file event logging on Windows VMs |

---

## MITRE ATT&CK Coverage

| # | Technique | ID | Tactic | Windows Event IDs | Wazuh Rule |
|---|---|---|---|---|---|
| 1 | Kerberoasting | T1558.003 | Credential Access | 4769 (RC4 ticket request) | 100001 |
| 2 | Password Spray | T1110.003 | Credential Access | 4625 (logon failure) | 100002 |
| 3 | Privilege Escalation (valid accounts) | T1078 | Privilege Escalation | 4672 (special logon) | 100003 |
| 4 | Lateral Movement via SMB | T1021.002 | Lateral Movement | 4624 Type 3 logon | 100004 |
| 5 | Rogue Account Creation | T1136.001 | Persistence | 4720 (account created) | 100005 |

Each technique has a corresponding PowerShell simulation script in [scripts/powershell/](scripts/powershell/) and a custom Wazuh detection rule in [scripts/config/local_rules.xml](scripts/config/local_rules.xml).

---

## How It Works

### Infrastructure Provisioning
VMs are defined and provisioned using **Terraform** (`main.tf`) from WSL2. VirtualBox is configured with a host-only network adapter on `192.168.56.0/24`. Windows VMs boot from ISO and are manually installed; Ubuntu (siem01) is installed from the Ubuntu Server 24.04 ISO.

### Automation & Configuration
**Ansible** (run from WSL2) automates all Windows configuration via WinRM:
- Promotes dc01 as forest root and dc02 as replica DC
- Creates the full OU structure, 1,800 bulk users, service accounts, and SPNs
- Joins wkstn01 to the domain
- Installs and registers Wazuh agents on all Windows VMs

### Detection Pipeline
1. **Wazuh agents** on dc01, dc02, and wkstn01 forward Security event logs to siem01 via port 1514
2. **ossec.conf** on each agent includes a localfile block capturing Windows Security channel events
3. **Custom rules** in `local_rules.xml` map specific event IDs and conditions to MITRE ATT&CK technique IDs
4. **Attack simulation scripts** generate real telemetry (Kerberos ticket requests, failed logons, SMB share access, new accounts) which appear in the Wazuh MITRE ATT&CK dashboard

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
    └── inventory.ini.template           # WinRM inventory template (no credentials)
```

---

## Screenshots

86 sequential screenshots document the complete build — from Terraform and prerequisites through Wazuh detection results. Includes real troubleshooting: WinRM errors, network misconfigurations, Ansible failures, and AD replication issues.

See [screenshots/README.md](screenshots/README.md) for the full phase-by-phase index.

---

## Reproducibility

- Credentials are never committed — use `ansible/inventory.ini.template` and local overrides
- Real ISO paths and host-specific values go in untracked `terraform.tfvars`
- Terraform state and secret artifacts are excluded via `.gitignore`

---

## License

MIT — see [LICENSE](LICENSE)
