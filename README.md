# Active Directory Detection Lab

A homelab environment for practicing Active Directory administration, attack simulation, and blue team detection using Wazuh SIEM. Built as a portfolio project covering real-world MITRE ATT&CK techniques and detection engineering.

> **WARNING:** This is an isolated lab environment. All credentials are placeholders — never reuse lab passwords in any production or internet-facing system.

---

## Architecture Overview

| VM | Hostname | IP Address | OS | RAM | Role |
|---|---|---|---|---|---|
| dc01 | DC01 | 192.168.56.10 | Windows Server 2016 | 4 GB | Primary Domain Controller, DNS |
| dc02 | DC02 | 192.168.56.102 | Windows Server 2016 | 2 GB | Replica Domain Controller |
| wkstn01 | WKSTN01 | 192.168.56.20 | Windows 10 Pro | 4 GB | Domain Workstation |
| siem01 | siem01 | 192.168.56.103 | Ubuntu 24.04 LTS | 4 GB | Wazuh SIEM Server |

**Network:** VirtualBox Host-Only Adapter — `192.168.56.0/24`
**Domain:** `corp.techcorp.internal` | NetBIOS: `TECHCORP` | Functional Level: Windows Server 2016

See [architecture/network-topology.md](architecture/network-topology.md) for the full network diagram.

---

## Tech Stack

| Component | Version | Purpose |
|---|---|---|
| VirtualBox | 7.x | Hypervisor |
| Windows Server 2016 | — | Domain Controllers |
| Windows 10 Pro | 22H2 | Workstation |
| Ubuntu Server | 24.04 LTS | SIEM host |
| Wazuh | 4.7.5 | SIEM / detection |
| Ansible | 2.15+ | Windows automation |
| PowerShell | 5.1 | AD provisioning & attack sims |

---

## MITRE ATT&CK Coverage

| # | Technique | ID | Tactic | Wazuh Rule |
|---|---|---|---|---|
| 1 | Kerberoasting | T1558.003 | Credential Access | 100001 |
| 2 | Password Spray | T1110.003 | Credential Access | 100002 |
| 3 | Privilege Escalation | T1078 | Privilege Escalation | 100003 |
| 4 | Lateral Movement (SMB) | T1021.002 | Lateral Movement | 100004 |
| 5 | Rogue Account Creation | T1136.001 | Persistence | 100005 |

---

## Quick Start

1. [Prerequisites & software requirements](docs/02-prerequisites.md)
2. [Network configuration (VirtualBox)](docs/03-network-configuration.md)
3. [WinRM & Ansible setup](docs/04-winrm-ansible-setup.md)
4. [Active Directory setup](docs/05-active-directory-setup.md)
5. [Wazuh SIEM deployment](docs/06-wazuh-siem-setup.md)
6. [Wazuh agent & log configuration](docs/07-wazuh-agent-configuration.md)
7. [Detection rules](docs/08-detection-rules.md)
8. [Run attack simulations](detections/attack-simulation-guide.md)

**Reference:**
- [Useful Commands](docs/useful-commands.md) — all key commands used in this lab
- [Common Issues & Fixes](docs/common-issues.md) — real errors encountered with solutions and screenshots

---

## Repository Structure

```
ad-detection-lab/
├── README.md
├── LICENSE
├── .gitignore
├── architecture/           # Network diagrams and topology docs
├── docs/                   # Step-by-step setup guides (10 sections)
├── scripts/
│   ├── powershell/         # AD setup and attack simulation scripts
│   ├── bash/               # Wazuh server install and config scripts
│   └── config/             # ossec.conf snippet and detection rules XML
├── detections/             # Attack simulation guide and MITRE mapping
├── screenshots/            # Wazuh alert evidence (add your own)
└── ansible/                # Inventory template for WinRM automation
```

---

## Screenshots

86 sequential screenshots document the full build process, from prerequisites through Wazuh detection. See the [screenshots README](screenshots/README.md) for the complete index.

---

## License

MIT — see [LICENSE](LICENSE)
