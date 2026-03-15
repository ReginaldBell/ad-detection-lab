# Common Issues & Fixes

Real errors encountered during this lab build, with screenshots and solutions.

---

## 1. WinRM — Network Profile Blocking (Public Network)

**Symptom:** `winrm quickconfig` fails because the network is set to Public.

**Screenshot:** `28-wkstn01-winrm-firewall-public-network-error.webp`

**Fix:**
```powershell
Set-NetConnectionProfile -InterfaceAlias "Ethernet" -NetworkCategory Private
winrm quickconfig -Force
```

**Screenshot (resolved):** `29-wkstn01-winrm-network-private-fix-working.webp`

---

## 2. WinRM — `winrm quickconfig -y` Unknown Switch

**Symptom:** Running `winrm quickconfig -y` throws an "unknown switch" error.

**Screenshot:** `27-wkstn01-winrm-quickconfig-y-flag-error.webp`

**Fix:** Use `-Force` instead:
```powershell
winrm quickconfig -Force
```

---

## 3. WinRM — WSMan Path Does Not Exist

**Symptom:** `Set-Item WSMan:\localhost\...` or `winrm set winrm/config/service/...` returns path errors.

**Screenshots:** `31-wkstn01-wsman-path-not-exist-errors.webp`, `32-wkstn01-winrm-config-errors.webp`, `33-wkstn01-allowunencrypted-path-error.webp`

**Fix:** Ensure WinRM is started first (`winrm quickconfig -Force`), then set auth and allow unencrypted:
```powershell
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
```

---

## 4. WinRM — TrustedHosts Access Denied

**Symptom:** Setting TrustedHosts returns Access Denied.

**Screenshot:** `35-wkstn01-trustedhosts-access-denied.webp`

**Fix:** Must run as Administrator:
```powershell
Set-Item WSMan:\localhost\Client\TrustedHosts -Value '192.168.56.*' -Force
```

---

## 5. WinRM — `Set-NetConnectionProfile` NetworkingCategory Error (dc02)

**Symptom:** `Set-NetConnectionProfile` fails with a parameter error on dc02.

**Screenshot:** `34-dc02-netconnectionprofile-error.webp`

**Fix:** Use `-NetworkCategory` (not `-NetworkingCategory`):
```powershell
Set-NetConnectionProfile -InterfaceAlias "Ethernet 2" -NetworkCategory Private
```

---

## 6. VirtualBox — Kernel Module Failure in WSL2

**Symptom:** VBoxManage commands fail with kernel module errors when run from WSL2.

**Screenshot:** `12-vbox-kernel-module-failure-wsl2.webp`

**Fix:** Run VBoxManage from **Windows PowerShell/CMD**, not WSL2. VirtualBox kernel modules run on the Windows host.

---

## 7. VirtualBox — Host-Only Adapter Missing

**Symptom:** VMs can't reach each other; host-only adapter not listed.

**Screenshot:** `11-vbox-all-vms-powered-off-no-hostonly.webp`

**Fix:** Install VirtualBox with Host-Only Networking component selected, then configure via File → Host Network Manager → Create (`192.168.56.1/24`, DHCP disabled).

**Screenshots:** `13-vbox-installer-host-only-networking.webp`, `17-vbox-hostonlyifs-192-168-56-1-working.webp`

---

## 8. VirtualBox — `modifyvm` Adapter Errors

**Symptom:** `VBoxManage modifyvm` returns errors when adding host-only adapters.

**Screenshot:** `16-vbox-modifyvm-adapter-errors.webp`

**Fix:** Add the adapter through the VirtualBox GUI instead (Settings → Network → Adapter 2 → Host-Only Adapter), then verify with:
```powershell
VBoxManage showvminfo <vmname> --details | Select-String "NIC"
```

**Screenshot:** `15-vbox-siem01-host-only-adapter-added.webp`

---

## 9. Network — `Ethernet 2` Adapter Not Found

**Symptom:** `Set-NetIPAddress` or `New-NetIPAddress` can't find "Ethernet 2".

**Screenshots:** `36-wkstn01-set-netipaddress-ethernet2-not-found.webp`, `43-wkstn01-only-ethernet-adapter2-not-yet-visible.webp`

**Fix:** Check the actual adapter name first:
```powershell
Get-NetAdapter | Select-Object Name, InterfaceDescription
```
Use the exact name returned. If Adapter 2 isn't visible yet, reboot the VM after adding it in VirtualBox.

**Screenshot (resolved):** `44-wkstn01-ethernet2-visible-ip-104.webp`

---

## 10. Network — `New-NetIPAddress` Access Denied

**Symptom:** IP assignment fails with Access Denied.

**Screenshot:** `45-wkstn01-netipaddress-access-denied-not-admin.webp`

**Fix:** Open PowerShell as Administrator before running network commands.

---

## 11. Network — "The Object Already Exists"

**Symptom:** `New-NetIPAddress` fails because an IP is already assigned to the adapter.

**Screenshot:** `46-wkstn01-ip-object-already-exists.webp`

**Fix:** Remove the existing IP first:
```powershell
Remove-NetIPAddress -InterfaceAlias "Ethernet 2" -Confirm:$false
New-NetIPAddress -InterfaceAlias "Ethernet 2" -IPAddress 192.168.56.105 -PrefixLength 24
```

**Screenshot:** `49-wkstn01-change-ip-104-to-105.webp`

---

## 12. Ansible — dc01 Unreachable on First Run

**Symptom:** `ansible win_ping` returns UNREACHABLE immediately.

**Screenshots:** `50-ansible-inventory-dc01-unreachable.webp`, `51-ansible-still-failing.webp`

**Fix:** Verify WinRM is running on the target, IP is correct in inventory, and the control host can reach it:
```bash
# From WSL2
ping 192.168.56.10
ansible dc01 -i inventory.ini -m win_ping -vvv
```
Also confirm the inventory password is correct — use `sed` to fix placeholder values:

**Screenshot:** `52-ansible-sed-password-fix.webp`

**Screenshot (resolved):** `53-ansible-dc01-success-pong.webp`

---

## 13. Ansible — wkstn01 Unreachable (No Route to Host)

**Symptom:** dc01/dc02/siem01 ping fine but wkstn01 returns UNREACHABLE or no route.

**Screenshots:** `54-ansible-dc01-dc02-siem01-success-wkstn01-unreachable.webp`, `61-wsl2-ping-104-failing-no-route.webp`, `62-wsl2-ping-104-destination-unreachable.webp`

**Root Cause:** WSL2 and the VirtualBox host-only adapter were on different subnets. wkstn01 only had a NAT adapter and no host-only adapter configured.

**Note:** The intermediate workstation IPs `192.168.56.104` and `192.168.56.105` shown in this section were temporary troubleshooting assignments. The intended steady-state IP for wkstn01 in the finished lab is `192.168.56.20`.

**Fix:**
1. Add a second adapter (Host-Only) to wkstn01 in VirtualBox
2. Assign the static IP inside Windows:
```powershell
New-NetIPAddress -InterfaceAlias "Ethernet 2" -IPAddress 192.168.56.105 -PrefixLength 24
```
3. Add a WinRM firewall rule for the host-only subnet:
```powershell
New-NetFirewallRule -DisplayName "WinRM-Lab" -Direction Inbound -Protocol TCP -LocalPort 5985 -RemoteAddress 192.168.56.0/24 -Action Allow
```

**Screenshot (resolved):** `66-ansible-wkstn01-all-hosts-success.webp`

---

## 14. Ansible — AD DS Promotion Unsupported Module Parameters

**Symptom:** `microsoft.ad.domain` module fails with "Unsupported parameters" error.

**Screenshot:** `70-ansible-promote-unsupported-module-params.webp`

**Fix:** Check the Ansible `microsoft.ad` collection version. Older versions don't support certain parameters. Remove unsupported keys from the playbook or upgrade:
```bash
ansible-galaxy collection install microsoft.ad --upgrade
```

---

## 15. Ansible — DC Promotion Reboot Timeout

**Symptom:** DC promotion succeeds (`changed: [dc01]`) but the reboot wait times out after 684 seconds.

**Screenshots:** `72-ansible-promote-changed-dc01-reboot-timeout.webp`, `73-ansible-promote-success-reboot-timeout-684s.webp`

**Fix:** This is expected behavior — Windows Server reboots after ADDS promotion and the WinRM connection drops. The promotion itself succeeded. Wait for the VM to come back up, then verify:
```powershell
Get-ADDomainController -Filter *
repadmin /replsummary
```

---

## 16. AD Replication — `repadmin` Sync Errors

**Symptom:** `repadmin /syncall` returns RPC errors; replication is failing between dc01 and dc02.

**Screenshots:** `74-wsl2-repadmin-replsummary-get-addomaincontroller.webp`, `75-dc01-server-manager-repadmin-sync-errors.webp`

**Fix:**
1. Confirm both DCs are online and reachable
2. Ensure dc02's DNS points to dc01:
```powershell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ServerAddresses 192.168.56.10
```
3. Force a time sync:
```powershell
w32tm /resync /force
```
4. Run `dcdiag /test:replications` to see the specific failure

---

## 17. Wazuh — Ubuntu 24.04 Not Supported

**Symptom:** `wazuh-install.sh` exits with an unsupported OS error.

**Fix:** Pass the `-i` (ignore check) flag:
```bash
bash wazuh-install.sh -a -i
```

---

## 18. Wazuh — EventID 4672 Returning No Results

**Symptom:** Filtering for EventID 4672 in MITRE ATT&CK shows zero hits even with agents active.

**Screenshot:** `82-wazuh-mitre-eventid-4672-no-results.webp`

**Fix:** In this lab, the issue was missing audit policy coverage for sensitive privilege use, not just dashboard filtering. On Windows Server 2022, enable the required audit subcategory first, then widen the dashboard time range if needed and verify the event stream in `archives.json`:
```powershell
auditpol /get /category:*
auditpol /set /subcategory:"Sensitive Privilege Use" /success:enable /failure:enable
```

```bash
sudo tail -f /var/ossec/logs/archives/archives.json | grep "4672"
```

---

## 19. Wazuh — EventID 4769 Initially No Results

**Symptom:** Filtering for EventID 4769 (Kerberoasting) shows no results.

**Screenshot:** `79-wazuh-mitre-eventid-4769-no-results.webp`

**Fix:** Widen the time range. After adjusting, 2 hits appeared from DC01.

**Screenshot (resolved):** `80-wazuh-mitre-eventid-4769-2-hits.webp`


