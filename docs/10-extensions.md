# Section 10: Lab Extensions

Optional enhancements to expand the lab for deeper attack simulation and detection practice.

## 10.1 — Add a Kali Linux Attacker VM

Add a fifth VM to simulate external/internal attacker perspective.

**Recommended config:**
- OS: Kali Linux 2024.x
- IP: 192.168.56.200 (static, host-only adapter)
- RAM: 2-4 GB

**Useful Kali tools for this lab:**

```bash
# Kerberoasting
impacket-GetUserSPNs corp.techcorp.internal/user:<YOUR_USER_PASSWORD> -dc-ip 192.168.56.10 -request

# Password spray
crackmapexec smb 192.168.56.0/24 -u users.txt -p '<YOUR_SPRAY_PASSWORD>' --continue-on-success

# Lateral movement
impacket-psexec TECHCORP/Administrator:<YOUR_ADMIN_PASSWORD>@192.168.56.20

# BloodHound data collection
bloodhound-python -u Administrator -p '<YOUR_ADMIN_PASSWORD>' -d corp.techcorp.internal -ns 192.168.56.10 --zip -c all
```

## 10.2 — Sysmon Integration

Deploy Sysmon on Windows VMs for enriched endpoint telemetry (process creation, network connections, registry changes).

```powershell
# Download Sysmon (run on Windows VM)
Invoke-WebRequest -Uri 'https://download.sysinternals.com/files/Sysmon.zip' -OutFile 'C:\Temp\Sysmon.zip'
Expand-Archive -Path 'C:\Temp\Sysmon.zip' -DestinationPath 'C:\Temp\Sysmon'

# Install with SwiftOnSecurity config (recommended baseline)
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml' `
    -OutFile 'C:\Temp\sysmonconfig.xml'

C:\Temp\Sysmon\Sysmon64.exe -accepteula -i C:\Temp\sysmonconfig.xml
```

Add Sysmon localfile block to ossec.conf:

```xml
<localfile>
  <location>Microsoft-Windows-Sysmon/Operational</location>
  <log_format>eventchannel</log_format>
</localfile>
```

## 10.3 — Azure AD Connect (Hybrid Identity)

Simulate a hybrid identity environment by connecting the on-premises lab domain to an Azure AD tenant (free tier works).

**Requirements:**
- A Microsoft Azure free account
- Azure AD tenant (M365 developer account provides E5 licenses free)
- Azure AD Connect installed on dc01

Use case: Practice detecting Azure AD sync anomalies, pass-the-hash across hybrid boundaries, and token theft.

## 10.4 — Atomic Red Team

Install the Atomic Red Team framework on wkstn01 for standardized ATT&CK test execution:

```powershell
# Install on wkstn01 (PowerShell as admin)
IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing)
Install-AtomicRedTeam -getAtomics -Force

# Run a specific technique
Invoke-AtomicTest T1558.003   # Kerberoasting
Invoke-AtomicTest T1110.003   # Password spray
Invoke-AtomicTest T1136.001   # Account creation
```

## 10.5 — SOC Analyst Scenario Practice

Use the lab as a SOC simulation platform. Sample ticket scenarios:

| Ticket | Alert | Investigation Steps |
|---|---|---|
| INC-001 | Rule 100001 triggered — RC4 Kerberos ticket | Identify SPN targeted, source IP, time correlation |
| INC-002 | Rule 100002 triggered — 10 failed logons | Identify sprayed accounts, source IP, spray timing |
| INC-003 | Rule 100005 triggered — new account created | Verify creator, OU placement, group memberships |
| INC-004 | Multiple 4624 from new IP | Check if wkstn01 or new device; correlate with 4648 |
| INC-005 | Rule 100003 triggered — Domain Admins change | Who added whom, at what time, from which host |

**Practice workflow:**
1. Run the attack simulation script
2. Open Wazuh dashboard
3. Find the triggered alert
4. Write a short IR report: *What happened? When? From where? Impact?*

## 10.6 — ELK Stack Alternative

Swap Wazuh for a custom ELK stack (Elasticsearch + Logstash + Kibana) for deeper pipeline experience. Use Wazuh only as a shipper to ELK.

Winlogbeat → Logstash → Elasticsearch → Kibana
