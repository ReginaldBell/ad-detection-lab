# Enterprise AD Detection Lab Phase Runbook

Recovered on 2026-04-11 from surviving project artifacts. This file is rebuilt
from the preserved `HANDOFF.md` execution notes and related session records.

---

## Preconditions

### Host preparation

Run host WinRM setup once per elevated PowerShell session:

```powershell
Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NonInteractive', '-Command', `
  'Start-Service WinRM; Set-Item WSMan:\localhost\Client\TrustedHosts -Value "192.168.56.20,192.168.56.10" -Force'
```

If using WSL, re-add the VirtualBox route when needed:

```bash
sudo ip route add 192.168.56.0/24 via 172.21.96.1 dev eth0
```

Build reusable admin credentials:

```powershell
$cred = New-Object PSCredential('TECHCORP\Administrator', (ConvertTo-SecureString 'LabAdmin@2026!' -AsPlainText -Force))
```

### Connection reference

```powershell
Invoke-Command -ComputerName 192.168.56.10 -Credential $cred -ScriptBlock { hostname }   # dc01
Invoke-Command -ComputerName 192.168.56.20 -Credential $cred -ScriptBlock { hostname }   # wkstn01
```

```bash
ssh -i ~/.ssh/lab_key labadmin@192.168.56.50   # siem01
ssh -i ~/.ssh/lab_key labadmin@192.168.56.105  # ticket01
```

### Important operational notes

- `Start-Process -Credential` does not generate the DC-side events needed for
  authentication detections.
- `net use` from a non-interactive WinRM session can fail with Error 67.
- Long `pywinrm` operations from WSL can time out; use PowerShell WinRM for
  anything substantial.

---

## Phase 8

### T1059.001 PowerShell Abuse Detection

**Goal:** Find the PowerShell detection path in Wazuh, validate the alert, and
route it into osTicket.

**Generate activity on `wkstn01`:**

```powershell
Invoke-Command -ComputerName 192.168.56.20 -Credential $cred -ScriptBlock {
    powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -Command "whoami"
    powershell.exe -EncodedCommand ([Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("whoami")))
}
```

**Inspect Wazuh on `siem01`:**

```bash
sudo tail -n 500 /var/ossec/logs/alerts/alerts.json | python3 -c "
import json,sys
for line in sys.stdin:
    try:
        a=json.loads(line)
        p=a.get('data',{}).get('win',{}).get('system',{}).get('providerName','')
        if 'PowerShell' in p or 'powershell' in a.get('rule',{}).get('description','').lower():
            print(a['timestamp'], 'rule='+a['rule']['id'], a['rule']['description'])
    except: pass
"
sudo cat /var/ossec/ruleset/rules/0915-win-powershell_rules.xml
```

**If integration work is needed:**

- Add the rule to `RULE_MAP` in `/var/ossec/integrations/custom-osticket`
- Add the matching `<integration>` block in `/var/ossec/etc/ossec.conf`
- Add osTicket Help Topic: `PowerShell Abuse`
- Restart Wazuh manager: `sudo systemctl restart wazuh-manager`

---

## Phase 9

### T1021.002 Lateral Movement Via SMB

**Goal:** Understand and detect admin-share access from a domain machine.

**Generate activity from `wkstn01`:**

```powershell
Invoke-Command -ComputerName 192.168.56.20 -Credential $cred -ScriptBlock {
    net use \\192.168.56.10\C$ /user:TECHCORP\Administrator LabAdmin@2026!
    dir \\192.168.56.10\C$\Windows
    net use \\192.168.56.10\C$ /delete /y
}
```

**Check for source events:**

- Event `5140` on `dc01`
- Event `4624` with `LogonType=3`

**Detection note:** This often requires correlation rather than a single built-in
rule. Review `0580-win-security_rules.xml` and `0620-win-generic_rules.xml`,
then decide whether a custom composite rule is needed.

---

## Phase 10

### T1078 Valid Accounts / Explicit Credential Use

**Goal:** Detect Event `4648`.

**Generate activity from `wkstn01`:**

```powershell
Invoke-Command -ComputerName 192.168.56.20 -Credential $cred -ScriptBlock {
    New-Item C:\Temp -ItemType Directory -Force | Out-Null
    runas /user:TECHCORP\Administrator "cmd.exe /c whoami > C:\Temp\out.txt"
}
```

**Validation steps:**

- Check `dc01` for Event `4648`
- Check Wazuh rules:

```bash
sudo grep -n "4648" /var/ossec/ruleset/rules/0580-win-security_rules.xml
```

**Expectation:** Earlier sessions documented this as a likely detection gap,
which may require a custom local rule in `/var/ossec/etc/rules/local_rules.xml`.

---

## Phase 11

### T1053.005 Persistence Via Scheduled Tasks

**Goal:** Detect Event `4698`.

**Generate activity on `wkstn01`:**

```powershell
Invoke-Command -ComputerName 192.168.56.20 -Credential $cred -ScriptBlock {
    Register-ScheduledTask -TaskName "WindowsUpdate" `
      -Action (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command whoami") `
      -Trigger (New-ScheduledTaskTrigger -AtLogOn) `
      -RunLevel Highest
}
```

**Validation steps:**

- Check Event Viewer on `wkstn01` for Event `4698`
- Check Wazuh rules:

```bash
sudo grep -n "4698" /var/ossec/ruleset/rules/0580-win-security_rules.xml
```

**Cleanup:**

```powershell
Invoke-Command -ComputerName 192.168.56.20 -Credential $cred -ScriptBlock {
    Unregister-ScheduledTask -TaskName "WindowsUpdate" -Confirm:$false
}
```

---

## Supporting Tasks

### Account lockout testing

The `wazuh-locktest` account exists and is enabled. Unlock it after testing:

```powershell
Invoke-Command -ComputerName 192.168.56.10 -Credential $cred -ScriptBlock {
    Unlock-ADAccount -Identity wazuh-locktest
}
```

### Infrastructure actions still referenced by the sessions

**DC01 snapshot:**

```powershell
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' snapshot dc01 take 'dc01-4740-agent-fix' --description 'Added EventID=4740 to Security channel query in ossec.conf; Wazuh agent restarted'
```

**Reverse DNS for `ticket01`:**

```powershell
Invoke-Command -ComputerName 192.168.56.10 -Credential $cred -ScriptBlock {
    & 'C:\path\to\dc01_register_ticket01_dns.ps1'
}
```

Or deploy via Ansible from `ansible/playbooks/`.

### Ansible deployment reference

```bash
cd '/mnt/c/Users/demar/Downloads/Enterprise AD Detection Lab/ansible'
wsl bash -c "python3 /mnt/c/Users/demar/write_vaultpass.py && chmod 600 /tmp/vaultpass"
ansible-playbook -i inventory/hosts.ini playbooks/siem01_osticket_integration.yml \
  --private-key ~/.ssh/lab_key \
  --vault-password-file /tmp/vaultpass \
  -e @group_vars/all/vault.yml
```

Vault password: `LabVault@2026!`

---

## Verification

- Confirm the target event exists on the source Windows host.
- Confirm the alert appears in `/var/ossec/logs/alerts/alerts.json`.
- Confirm ticket creation in `/var/ossec/logs/custom-osticket.log`.
- Update `LAB-STATE.md` and related docs after successful validation.
