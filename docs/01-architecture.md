# Section 1: Lab Architecture

## Overview

This lab simulates a small enterprise Active Directory environment with a dedicated SIEM for detection engineering. The goal is hands-on practice with AD administration, attack simulation, and blue team detection using real MITRE ATT&CK techniques.

## Lab Components

![Lab Architecture](../architecture/lab-architecture-diagram.png)

> Source file: [architecture/lab-architecture-diagram.drawio](../architecture/lab-architecture-diagram.drawio)

See [architecture/network-topology.md](../architecture/network-topology.md) for the full network diagram and port reference.

| VM | Hostname | IP | OS | RAM | Role |
|---|---|---|---|---|---|
| dc01 | DC01 | 192.168.56.10 | Windows Server 2022 | 4 GB | Primary DC, DNS, FSMO holder |
| dc02 | DC02 | 192.168.56.102 | Windows Server 2022 | 2 GB | Replica DC |
| wkstn01 | WKSTN01 | 192.168.56.20 | Windows 10 Pro 22H2 | 4 GB | Domain workstation |
| siem01 | siem01 | 192.168.56.103 | Ubuntu 24.04 LTS | 4 GB | Wazuh 4.7.5 SIEM |

## Domain Configuration

| Setting | Value |
|---|---|
| Domain FQDN | `corp.techcorp.internal` |
| NetBIOS Name | `TECHCORP` |
| Forest Mode | Windows Server 2016 (WinThreshold) |
| Domain Mode | Windows Server 2016 (WinThreshold) |
| DNS | dc01 (192.168.56.10) |

## Credential Reference

> **WARNING: Lab credentials only. Never use these in any production or internet-facing environment.**

| Account | Username | Password | Purpose |
|---|---|---|---|
| Domain Admin | `Administrator` | `<YOUR_ADMIN_PASSWORD>` | Full domain control |
| DSRM | n/a | `<YOUR_DSRM_PASSWORD>` | Directory Services Restore Mode |
| Tier0 Admins | `adm_jdoe`, `adm_asmith`, `adm_mbrown`, `adm_kwilson`, `adm_rjones` | `<YOUR_TIER0_PASSWORD>` | Privileged admin accounts |
| Service Accounts | `svc_sql`, `svc_backup`, `svc_wazuh`, `svc_monitoring`, `svc_deploy` | `<YOUR_SVC_PASSWORD>` | SPNs for Kerberoasting simulation |
| Wazuh Web UI | `admin` | `<YOUR_WAZUH_PASSWORD>` | SIEM dashboard access |

## OU Structure

```
corp.techcorp.internal
├── Tier0 (Privileged Admins)
├── Tier1 (Servers & Service Accounts)
├── Tier2 (Workstations & Users)
│   ├── IT
│   ├── HR
│   ├── Finance
│   ├── Legal
│   ├── Engineering
│   ├── Marketing
│   ├── Sales
│   ├── Operations
│   └── Executive
```

## Technology Stack

| Tool | Version | Purpose |
|---|---|---|
| VirtualBox | 7.x | Hypervisor |
| Ansible | 2.20.3 | Windows automation via WinRM |
| WSL2 | Ubuntu | Ansible control node |
| Wazuh | 4.7.5 | SIEM / XDR |
| PowerShell | 5.1 | Scripting and attack simulation |
