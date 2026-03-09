# Section 2: Prerequisites

## Host Machine Requirements

| Resource | Minimum | Recommended |
|---|---|---|
| RAM | 16 GB | 32 GB |
| CPU | 4 cores (VT-x/AMD-V enabled) | 8 cores |
| Storage | 100 GB free | 200 GB SSD |
| OS | Windows 10/11, macOS, Linux | Windows 11 |

## Required Software

### Hypervisor

- **VirtualBox 7.x** — Download from [virtualbox.org](https://www.virtualbox.org/wiki/Downloads)
- VirtualBox Extension Pack (same version as VirtualBox)

### VM Images / ISOs

- Windows Server 2016 ISO (Evaluation: 180-day free from Microsoft Evaluation Center)
- Windows 10 Pro ISO (22H2 or later)
- Ubuntu Server 24.04 LTS ISO — [ubuntu.com/download/server](https://ubuntu.com/download/server)

### Automation (optional but recommended)

- **WSL2** with Ubuntu — for running Ansible from Windows
- **Ansible 2.15+** — `pip install ansible pywinrm`
- **Python 3.10+**

### Tools on Host

- Git (for cloning this repo)
- A text editor (VS Code recommended)

## VirtualBox Initial Setup

### 1. Create Host-Only Network

1. Open VirtualBox → **File** → **Host Network Manager**
2. Click **Create** — a new `vboxnet0` (or `VirtualBox Host-Only Ethernet Adapter`) appears
3. Set **IPv4 Address:** `192.168.56.1` / **Mask:** `255.255.255.0`
4. **Disable** the DHCP server (all VMs use static IPs)
5. Click **Apply**

### 2. VM Creation Settings (apply to all VMs)

- **Type:** Microsoft Windows / Linux (Ubuntu 64-bit for siem01)
- **Network Adapter 1:** NAT (for internet access during setup — can be disabled later)
- **Network Adapter 2:** Host-Only Adapter → `vboxnet0`

> The NAT adapter is used only to download updates during initial setup. All lab traffic uses the host-only adapter.

## WSL2 + Ansible Setup (Windows Hosts)

```bash
# Install WSL2 (run in elevated PowerShell)
wsl --install -d Ubuntu

# Inside WSL2 Ubuntu
sudo apt update && sudo apt install -y python3-pip
pip3 install ansible pywinrm requests-credssp

# Verify
ansible --version
```

## Checklist Before Starting

- [ ] VirtualBox installed with Extension Pack
- [ ] Host-only network `192.168.56.0/24` created, DHCP disabled
- [ ] Windows Server 2016 ISO available
- [ ] Windows 10 ISO available
- [ ] Ubuntu 24.04 ISO available
- [ ] At least 14 GB RAM available for simultaneous VM operation
