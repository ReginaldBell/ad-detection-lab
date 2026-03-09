# Section 7: Wazuh Agent Configuration

Configure Wazuh agents on Windows VMs to collect Security Event Log data, with targeted EventID filtering for AD attack detection.

## 7.1 — ossec.conf Security Localfile Block

Add the following `<localfile>` block to `C:\Program Files (x86)\ossec-agent\ossec.conf` on **each Windows VM** (dc01, dc02, wkstn01):

**Config file:** [scripts/config/ossec-localfile-block.conf](../scripts/config/ossec-localfile-block.conf)

```xml
<ossec_config>
  <localfile>
    <location>Security</location>
    <log_format>eventchannel</log_format>
    <query>
      <![CDATA[
        Event/System[
          EventID=4624 or EventID=4625 or EventID=4648 or
          EventID=4662 or EventID=4663 or EventID=4672 or
          EventID=4720 or EventID=4728 or EventID=4732 or
          EventID=4756 or EventID=4768 or EventID=4769 or
          EventID=4771 or EventID=4776
        ]
      ]]>
    </query>
  </localfile>
</ossec_config>
```

## 7.2 — Monitored EventIDs Reference

| EventID | Description | ATT&CK Relevance |
|---|---|---|
| 4624 | Successful logon | Baseline / lateral movement |
| 4625 | Failed logon | Password spray (T1110.003) |
| 4648 | Logon with explicit credentials | Pass-the-hash, lateral movement |
| 4662 | Operation performed on AD object | Privilege escalation (T1078) |
| 4663 | Object access attempt | File/object access |
| 4672 | Special privileges assigned | Privilege escalation |
| 4720 | User account created | Rogue account (T1136.001) |
| 4728 | Member added to global security group | Group membership changes |
| 4732 | Member added to local group | Local privilege escalation |
| 4756 | Member added to universal security group | Group changes |
| 4768 | Kerberos TGT requested | Kerberos activity |
| 4769 | Kerberos service ticket requested | Kerberoasting (T1558.003) |
| 4771 | Kerberos pre-auth failed | Brute force / spray |
| 4776 | NTLM authentication attempt | NTLM auth / spraying |

## 7.3 — Apply Configuration

After editing ossec.conf on each Windows VM, restart the agent:

```powershell
# PowerShell (elevated) on each Windows VM
Restart-Service -Name WazuhSvc
```

Or via Services console: `services.msc` → WazuhSvc → Restart.

## 7.4 — Verify Log Collection

On siem01, confirm events are arriving:

```bash
# Real-time log stream
sudo tail -f /var/ossec/logs/alerts/alerts.json | grep -i "4769\|4625\|4720"
```

In the Wazuh dashboard: **Security Events** → filter by agent name (dc01) and verify events are appearing within 1-2 minutes of a test login.

## 7.5 — Archive Logging (Optional)

Enable full event archiving in `/var/ossec/etc/ossec.conf` on siem01:

```xml
<global>
  <logall>yes</logall>
  <logall_json>yes</logall_json>
</global>
```

**Script:** [scripts/bash/configure-wazuh-logging.sh](../scripts/bash/configure-wazuh-logging.sh)

Restart after change:

```bash
sudo systemctl restart wazuh-manager
```
