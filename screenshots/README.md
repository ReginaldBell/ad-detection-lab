# Screenshots — AD Detection Lab Build Log

Ordered screenshots documenting the complete lab build process, from prerequisites through Wazuh detection.

> A small number of early screenshots capture Terraform experiments and downloads. Those images are preserved as build-history context only; Terraform was not used in the final lab workflow.

> Errors and troubleshooting screenshots are cross-referenced in [docs/common-issues.md](../docs/common-issues.md).

---

## Phase 1: Host Preparation (01–08)

| File | What it shows |
|---|---|
| `01-prereqs-terraform-download-page.webp` | Terraform download page captured during early tooling exploration; Terraform was not used in the final build |
| `02-prereqs-iso-files-windows-server-win10.webp` | Windows Explorer — ISOs folder with Windows Server and Windows 10 ISOs |
| `03-prereqs-ubuntu-2404-download.webp` | Ubuntu 24.04 LTS download page |
| `04-prereqs-wsl2-install-terraform-gpg.webp` | WSL2: `wsl --install` Ubuntu and early Terraform package prep captured during discarded experimentation |
| `05-prereqs-terraform-114-installed.webp` | WSL2: `terraform --version` confirmation from early experimentation; not part of the final workflow |
| `06-prereqs-ansible-winrm-installed.webp` | WSL2: python3-winrm packages installing, `ansible --version` 2.20.3 |
| `07-prereqs-ansible-pywinrm-lab-dir.webp` | WSL2: Ansible + pywinrm install, enterprise-ad-lab directory created |
| `08-prereqs-ansible-version-confirmed.webp` | WSL2: Ansible version confirmed, ISOs listed in directory |

---

## Phase 2: VirtualBox Setup (09–18)

| File | What it shows |
|---|---|
| `09-terraform-main-tf-vm-configs.webp` | WSL2: discarded local Terraform `main.tf` draft from an abandoned approach; not used in the final build and not tracked in this repo |
| `10-prereqs-isos-with-ubuntu-added.webp` | Explorer — ISOs folder with ubuntu-24.04.4 added |
| `11-vbox-all-vms-powered-off-no-hostonly.webp` | VirtualBox Manager — all 4 VMs Powered Off, siem01 missing host-only adapter |
| `12-vbox-kernel-module-failure-wsl2.webp` | WSL2: VirtualBox kernel module failure + VBoxManage errors ⚠️ |
| `13-vbox-installer-host-only-networking.webp` | VirtualBox installer — Host-Only Networking component selected |
| `14-vbox-installer-missing-dependencies.webp` | VirtualBox installer — Missing Dependencies warning dialog ⚠️ |
| `15-vbox-siem01-host-only-adapter-added.webp` | VirtualBox Manager — siem01 now has Adapter 2 (Host-Only) ✅ |
| `16-vbox-modifyvm-adapter-errors.webp` | PowerShell: VBoxManage modifyvm host-only adapter errors ⚠️ |
| `17-vbox-hostonlyifs-192-168-56-1-working.webp` | PowerShell: `VBoxManage list hostonlyifs` — 192.168.56.1 working ✅ |
| `18-vbox-showvminfo-nic-details.webp` | PowerShell: `VBoxManage showvminfo` NIC details for dc02/wkstn01 |

---

## Phase 3: VM Installation (19–26)

| File | What it shows |
|---|---|
| `19-siem01-ubuntu-install-cdrom-warning.webp` | siem01: Ubuntu install — "Failed unmounting /cdrom" warning |
| `20-vbox-all-vms-running-windows-installing.webp` | VirtualBox — all 4 VMs RUNNING, wkstn01 Windows setup in progress |
| `21-wkstn01-windows-oobe-setup-type.webp` | wkstn01: Windows 10 OOBE — "How would you like to set up?" |
| `22-wkstn01-windows-oobe-microsoft-signin.webp` | wkstn01: Windows 10 OOBE — "Sign in with Microsoft" screen |
| `23-wkstn01-windows-oobe-username.webp` | wkstn01: Windows 10 OOBE — "Who's going to use this PC?" |
| `24-siem01-ssh-enabled-ip-192-168-56-103.webp` | siem01: SSH enabled, `ip a` showing 192.168.56.103 |
| `25-host-ps-vboxmanage-guestproperty-vm-ips.webp` | Host PowerShell: `VBoxManage guestproperty get` IPs for all VMs |
| `26-siem01-ssh-running-ip-addr-output.webp` | siem01: SSH service running, full `ip addr` output |

---

## Phase 4: WinRM Configuration (27–34)

| File | What it shows |
|---|---|
| `27-wkstn01-winrm-quickconfig-y-flag-error.webp` | wkstn01: `winrm quickconfig -y` unknown switch error ⚠️ |
| `28-wkstn01-winrm-firewall-public-network-error.webp` | wkstn01: WinRM fails — network is Public, firewall blocks it ⚠️ |
| `29-wkstn01-winrm-network-private-fix-working.webp` | wkstn01: `Set-NetConnectionProfile -NetworkCategory Private` → WinRM working ✅ |
| `30-wkstn01-winrm-set-auth-errors.webp` | wkstn01: `winrm set` authentication path errors ⚠️ |
| `31-wkstn01-wsman-path-not-exist-errors.webp` | wkstn01: `Set-Item WSMan:\` path does not exist errors ⚠️ |
| `32-wkstn01-winrm-config-errors.webp` | wkstn01: WinRM config errors during troubleshooting ⚠️ |
| `33-wkstn01-allowunencrypted-path-error.webp` | wkstn01: AllowUnencrypted WSMan path not found error ⚠️ |
| `34-dc02-netconnectionprofile-error.webp` | dc02: `Set-NetConnectionProfile` NetworkingCategory parameter error ⚠️ |

---

## Phase 5: Network IP Configuration (35–49)

| File | What it shows |
|---|---|
| `35-wkstn01-trustedhosts-access-denied.webp` | wkstn01: TrustedHosts Access Denied, IP showing as 10.0.2.15 (NAT only) ⚠️ |
| `36-wkstn01-set-netipaddress-ethernet2-not-found.webp` | wkstn01: `Set-NetIPAddress` — Ethernet 2 adapter not found ⚠️ |
| `37-wkstn01-new-netipaddress-192-168-56-104.webp` | wkstn01: `New-NetIPAddress` on "Ethernet" → 192.168.56.104 assigned |
| `38-wkstn01-winrm-ok-ip-104-confirmed.webp` | wkstn01: Admin PS — WinRM OK, IP 192.168.56.104, Ethernet 2 visible ✅ |
| `39-wkstn01-winrm-auth-set-only-one-adapter.webp` | wkstn01: WinRM auth configured, Get-NetAdapter shows only "Ethernet" |
| `40-vbox-wkstn01-network-nat-disabled.webp` | VirtualBox wkstn01 Settings — Adapter 1 NAT disabled |
| `41-vbox-wkstn01-network-nat-enabled.webp` | VirtualBox wkstn01 Settings — Adapter 1 NAT re-enabled |
| `42-vbox-wkstn01-adapter2-host-only-added.webp` | VirtualBox wkstn01 Settings — Adapter 2 Host-Only attached ✅ |
| `43-wkstn01-only-ethernet-adapter2-not-yet-visible.webp` | wkstn01: Admin PS — only "Ethernet", Adapter 2 not yet showing in OS ⚠️ |
| `44-wkstn01-ethernet2-visible-ip-104.webp` | wkstn01: Ethernet 2 now visible in OS, IP 192.168.56.104 ✅ |
| `45-wkstn01-netipaddress-access-denied-not-admin.webp` | wkstn01: `New-NetIPAddress` Access Denied (ran as non-admin) ⚠️ |
| `46-wkstn01-ip-object-already-exists.webp` | wkstn01: Admin PS — "The object already exists" error ⚠️ |
| `47-wkstn01-winrm-firewall-rule-ip-104.webp` | wkstn01: netsh WinRM firewall rule added, IP 192.168.56.104 confirmed ✅ |
| `48-host-ps-ethernet3-192-168-56-1-virtualbox.webp` | Host PS: network adapters — Ethernet 3 = 192.168.56.1 (VirtualBox host-only) |
| `49-wkstn01-change-ip-104-to-105.webp` | wkstn01: `Remove-NetIPAddress` .104, `New-NetIPAddress` .105 on Ethernet 2 |

---

## Phase 6: Ansible Connectivity (50–66)

| File | What it shows |
|---|---|
| `50-ansible-inventory-dc01-unreachable.webp` | WSL2: Ansible inventory created, dc01 win_ping UNREACHABLE ⚠️ |
| `51-ansible-still-failing.webp` | WSL2: repeated dc01 connectivity failure while validating the inventory and WinRM state ⚠️ |
| `52-ansible-sed-password-fix.webp` | WSL2: `sed` to fix password placeholder in inventory |
| `53-ansible-dc01-success-pong.webp` | WSL2: dc01 SUCCESS — pong! First successful win_ping ✅ |
| `54-ansible-dc01-dc02-siem01-success-wkstn01-unreachable.webp` | WSL2: dc01+dc02+siem01 SUCCESS, wkstn01 unreachable (no route to .104) ⚠️ |
| `55-ansible-dc01-dc02-siem01-success-wkstn01-no-route.webp` | WSL2: all hosts except wkstn01 reachable; wkstn01 still failing with no-route symptoms ⚠️ |
| `56-siem01-ssh-status-ansible-not-found.webp` | siem01: SSH status running, `ansible` not installed on siem01 |
| `57-ansible-wkstn01-unreachable-siem01-ok.webp` | WSL2: siem01 reachable over SSH while wkstn01 remains unreachable over WinRM ⚠️ |
| `58-ansible-all-except-wkstn01-success.webp` | WSL2: dc01/dc02/siem01 SUCCESS, wkstn01 UNREACHABLE ⚠️ |
| `59-ansible-wkstn01-unreachable-ping-100pct-loss.webp` | WSL2: wkstn01 still unreachable with 100% ping loss during routing troubleshooting ⚠️ |
| `60-ansible-wkstn01-ping-failing.webp` | WSL2: direct ping and Ansible checks against wkstn01 continue to fail before the final IP correction ⚠️ |
| `61-wsl2-ping-104-failing-no-route.webp` | WSL2: ping 192.168.56.104 failing; `ip route/addr` shows WSL2 subnet only ⚠️ |
| `62-wsl2-ping-104-destination-unreachable.webp` | WSL2: ping .104 "Destination Host Unreachable" ⚠️ |
| `63-wsl2-ping-104-105-both-fail.webp` | WSL2: ping .104 fail, sed to .105, ping .105 also fail ⚠️ |
| `64-wkstn01-ping-dc01-wkstn01-success.webp` | wkstn01: ping 192.168.56.10 SUCCESS, ping 192.168.56.20 SUCCESS ✅ |
| `65-wsl2-ping-192-168-56-20-success.webp` | WSL2: ping 192.168.56.20 SUCCESS (3 packets received) ✅ |
| `66-ansible-wkstn01-all-hosts-success.webp` | WSL2: ping .20 success, ansible wkstn01 SUCCESS pong — all hosts reachable ✅ |

---

## Phase 7: AD DS Promotion (67–75)

| File | What it shows |
|---|---|
| `67-ansible-promote-dc01-first-attempt-unreachable.webp` | WSL2: local `01-promote-dc01.yml` playbook attempt — dc01 UNREACHABLE on first run ⚠️ |
| `68-ansible-promote-dc01-read-timeout.webp` | WSL2: promote-dc01.yml read timed out (WinRM timeout during AD DS install) ⚠️ |
| `69-ansible-promote-dc01-adds-feature-installed.webp` | WSL2: checking `Get-WindowsFeature AD-Domain-Services` → Installed ✅ |
| `70-ansible-promote-unsupported-module-params.webp` | WSL2: Promote fails — "Unsupported parameters for microsoft.ad.domain module" ⚠️ |
| `71-ansible-promote-playbook-yaml-view.webp` | WSL2: viewing the local promote-dc01.yml YAML content used during the build, then re-running it |
| `72-ansible-promote-changed-dc01-reboot-timeout.webp` | WSL2: `changed: [dc01]` (promotion succeeded), reboot timed out (684s elapsed) ⚠️ |
| `73-ansible-promote-success-reboot-timeout-684s.webp` | WSL2: DC promotion changed, reboot waited 684s then timed out (expected) ✅ |
| `74-wsl2-repadmin-replsummary-get-addomaincontroller.webp` | WSL2: `repadmin /replsummary` replication errors, `Get-ADDomainController` shows two DCs ⚠️ |
| `75-dc01-server-manager-repadmin-sync-errors.webp` | dc01 VirtualBox: Server Manager open, `repadmin /syncall` RPC errors ⚠️ |

---

## Phase 8: Wazuh SIEM & Detection (76–86)

| File | What it shows |
|---|---|
| `76-wazuh-security-events-3-agents-active.webp` | Wazuh Security Events — DC01, WKSTN01, siem01 agents reporting events ✅ |
| `77-wazuh-ossec-conf-archives-json-events.png` | WSL2: ossec.conf localfile block + `tail archives.json` showing AD Security events |
| `78-wazuh-rule-4720-rogue-account-alert.png` | Wazuh Security Events — EventID 4720 (account created) alert firing ✅ |
| `79-wazuh-mitre-eventid-4769-no-results.webp` | Wazuh MITRE ATT&CK — EventID 4769 filter, no results (time range too narrow) ⚠️ |
| `80-wazuh-mitre-eventid-4769-2-hits.webp` | Wazuh MITRE ATT&CK — EventID 4769, 2 hits from DC01 ✅ |
| `81-wazuh-mitre-eventid-4625-6-logon-failures.webp` | Wazuh MITRE ATT&CK — EventID 4625, 6 logon failure events from DC01 during password spray validation (T1110.003) ✅ |
| `82-wazuh-mitre-eventid-4672-no-results.webp` | Wazuh MITRE ATT&CK — EventID 4672, no results before the required audit policy was enabled ⚠️ |
| `83-wazuh-mitre-eventid-4672-no-results-2.webp` | Wazuh MITRE ATT&CK — second 4672 validation attempt still returning no results while audit policy coverage was incomplete ⚠️ |
| `84-wazuh-mitre-eventid-4672-no-results-dashboard.webp` | Wazuh dashboard view confirming 4672 remained absent until audit policy was corrected ⚠️ |
| `85-wazuh-mitre-47-hits-t1078-logon-events.webp` | Wazuh MITRE ATT&CK — 47 hits, T1078 Windows logon success events from DC01 ✅ |
| `86-wazuh-mitre-dc01-logon-type3-events.webp` | Wazuh MITRE ATT&CK — DC01 LogonType:3 events, 47 hits ✅ |

---

## Notes

- ⚠️ = error/problem encountered — see [docs/common-issues.md](../docs/common-issues.md) for the fix
- ✅ = working state confirmed
- Screenshots are `.webp` format or `.png`
- Timestamps in Wazuh screenshots: **Mar 8, 2026** (lab build date)


