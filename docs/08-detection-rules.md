# Section 8: Detection Rules

Custom Wazuh detection rules mapped to MITRE ATT&CK techniques. Rules are stored in `local_rules.xml` on siem01.

## 8.1 — Deploy Rules

**Config file:** [scripts/config/local_rules.xml](../scripts/config/local_rules.xml)

From the repo root, copy the tracked rule file to `siem01`:

```bash
scp scripts/config/local_rules.xml labadmin@192.168.56.103:/tmp/local_rules.xml
```

Then on `siem01`:

```bash
sudo cp /tmp/local_rules.xml /var/ossec/etc/rules/local_rules.xml
sudo chown root:wazuh /var/ossec/etc/rules/local_rules.xml
sudo chmod 660 /var/ossec/etc/rules/local_rules.xml
sudo systemctl restart wazuh-manager
```

Verify no XML errors:

```bash
sudo /var/ossec/bin/wazuh-logtest
```

## 8.2 — Rule Definitions

### Rule 100001 — Kerberoasting (T1558.003)

Triggers on EventID 4769 with RC4 encryption (downgraded ticket — a Kerberoasting indicator).

```xml
<rule id="100001" level="12">
  <if_group>windows</if_group>
  <field name="win.system.eventID">^4769$</field>
  <field name="win.eventdata.ticketEncryptionType">^0x17$</field>
  <description>Possible Kerberoasting: RC4 Kerberos service ticket requested (T1558.003)</description>
  <mitre>
    <id>T1558.003</id>
  </mitre>
  <group>attack,kerberoasting,credential_access</group>
</rule>
```

### Rule 100002 — Password Spray (T1110.003)

Triggers on multiple EventID 4625 failures from a single source within 60 seconds.

```xml
<rule id="100002" level="10" frequency="10" timeframe="60">
  <if_matched_sid>60122</if_matched_sid>
  <same_field>win.eventdata.ipAddress</same_field>
  <description>Password spray detected: 10+ failed logons from same source (T1110.003)</description>
  <mitre>
    <id>T1110.003</id>
  </mitre>
  <group>attack,password_spray,credential_access</group>
</rule>
```

### Rule 100003 — Privilege Escalation (T1078)

Triggers on EventID 4728 (member added to a global security group) where the target group is `Domain Admins`.

```xml
<rule id="100003" level="12">
  <if_group>windows</if_group>
  <field name="win.system.eventID">^4728$</field>
  <field name="win.eventdata.targetUserName" type="pcre2">(?i)Domain Admins</field>
  <description>User added to Domain Admins group (T1078)</description>
  <mitre>
    <id>T1078</id>
  </mitre>
  <group>attack,privilege_escalation</group>
</rule>
```

### Rule 100004 — Lateral Movement via SMB (T1021.002)

Triggers on EventID 4648 (explicit credential logon) targeting a remote host.

```xml
<rule id="100004" level="10">
  <if_group>windows</if_group>
  <field name="win.system.eventID">^4648$</field>
  <field name="win.eventdata.targetServerName" negate="yes">(?i)localhost|127\.0\.0\.1</field>
  <description>Lateral movement: explicit credential logon to remote host (T1021.002)</description>
  <mitre>
    <id>T1021.002</id>
  </mitre>
  <group>attack,lateral_movement</group>
</rule>
```

### Rule 100005 — Rogue Account Creation (T1136.001)

Triggers on EventID 4720 (new user account created).

```xml
<rule id="100005" level="12">
  <if_group>windows</if_group>
  <field name="win.system.eventID">^4720$</field>
  <description>New user account created — verify if authorized (T1136.001)</description>
  <mitre>
    <id>T1136.001</id>
  </mitre>
  <group>attack,persistence,account_creation</group>
</rule>
```

## 8.3 — Rule-to-ATT&CK Summary

| Rule ID | EventID | Technique | Tactic | Level | Trigger |
|---|---|---|---|---|---|
| 100001 | 4769 | T1558.003 | Credential Access | 12 | RC4 ticket encryption |
| 100002 | 4625 | T1110.003 | Credential Access | 10 | 10 failures / 60s / same IP |
| 100003 | 4728 | T1078 | Privilege Escalation | 12 | Added to Domain Admins |
| 100004 | 4648 | T1021.002 | Lateral Movement | 10 | Remote explicit credential logon |
| 100005 | 4720 | T1136.001 | Persistence | 12 | New account created |

## 8.4 — Wazuh Dashboard DQL Queries

Search for triggered rules in the Security Events view:

```
# All custom lab rules
rule.id: [100001 TO 100005]

# Kerberoasting alerts only
rule.id: 100001

# Password spray events
rule.id: 100002

# All critical (level 12) alerts
rule.level: 12
```

