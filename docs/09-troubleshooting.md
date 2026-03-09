# Section 9: Troubleshooting

Common issues encountered during lab setup and their fixes.

## Networking

| Symptom | Root Cause | Fix |
|---|---|---|
| VMs can't ping each other | Host-only adapter not configured | VirtualBox → Host Network Manager → Verify adapter exists on 192.168.56.1/24 with DHCP off |
| Static IP not persisting after reboot | NIC not bound to host-only adapter | Re-run `New-NetIPAddress` script; confirm adapter alias with `Get-NetAdapter` |
| `Ethernet 2` doesn't exist | VirtualBox added adapter as different name | Run `Get-NetAdapter` — use the correct alias in the script |
| DC unreachable from wkstn01 | DNS pointing to wrong server | `Set-DnsClientServerAddress -ServerAddresses 192.168.56.10` |

## Active Directory

| Symptom | Root Cause | Fix |
|---|---|---|
| `Install-ADDSForest` fails — DNS conflict | A DNS role already installed on wrong adapter | Remove existing DNS, re-run with correct IP bound |
| dc02 can't replicate | DNS not pointing to dc01 | On dc02: `Set-DnsClientServerAddress -ServerAddresses 192.168.56.10` |
| `dcdiag` shows replication errors | Time skew between DCs | Sync NTP: `w32tm /resync /force` on dc02 |
| `setspn` returns "Duplicate SPN" | Account already has SPN | Delete with `setspn -D <SPN> <account>` then re-add |
| Bulk user creation fails on some users | SAM account name conflict | Ensure usernames are unique; use `Get-ADUser -Filter {SamAccountName -eq "..."}` to check |
| wkstn01 can't join domain | DNS not resolving `corp.techcorp.internal` | Verify wkstn01 DNS is 192.168.56.10; test with `nslookup corp.techcorp.internal` |

## WinRM / Ansible

| Symptom | Root Cause | Fix |
|---|---|---|
| `ansible win_ping` — Connection refused | WinRM not started | Run `winrm quickconfig -Force` on target |
| `AuthenticationError` | Basic auth disabled | `winrm set winrm/config/service/auth '@{Basic="true"}'` |
| `Timeout` on all hosts | Wrong inventory IP | Verify IPs in `inventory.ini` match `ipconfig` output |
| `Certificate validation failed` | Self-signed cert | Add `ansible_winrm_server_cert_validation=ignore` to inventory |

## Wazuh

| Symptom | Root Cause | Fix |
|---|---|---|
| Install script exits with OS error | Ubuntu 24.04 not supported | Use `-i` flag: `bash wazuh-install.sh -a -i` |
| Agents show "Disconnected" | Agent service not started | `NET START WazuhSvc` on Windows VM |
| No events in dashboard | ossec.conf localfile block missing | Add Security localfile block to agent ossec.conf, restart WazuhSvc |
| Rule not triggering | XML syntax error in local_rules.xml | Run `sudo /var/ossec/bin/wazuh-logtest` and check for parse errors |
| Dashboard login fails | Wrong password | Password is in `/var/ossec/logs/ossec.log` during initial install |
| Wazuh API unreachable (port 55000) | Firewall blocking | `sudo ufw allow 55000/tcp` on siem01 |

## General Tips

- **Check Wazuh manager logs:** `sudo tail -f /var/ossec/logs/ossec.log`
- **Check agent logs (Windows):** `C:\Program Files (x86)\ossec-agent\ossec.log`
- **Validate XML:** `sudo /var/ossec/bin/wazuh-logtest` on siem01
- **Check AD replication:** `repadmin /showrepl` on dc01
- **Reset agent enrollment:** Delete agent in Wazuh dashboard → re-run agent installer with new key
