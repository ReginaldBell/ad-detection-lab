# Section 3: Network Configuration

Configure static IPs on all Windows VMs using the host-only network adapter. Run each script on the corresponding VM.

> **Note:** VirtualBox typically names adapters `Ethernet` (NAT/first adapter) and `Ethernet 2` (host-only/second adapter). Verify adapter names in Device Manager before running.
>
> **Final-state IP note:** wkstn01 should end on `192.168.56.20`. The `192.168.56.104` and `192.168.56.105` addresses shown elsewhere in troubleshooting docs were temporary during debugging and are not the intended steady-state configuration.

## dc01 — Primary Domain Controller

**Script:** [scripts/powershell/01-dc01-network-config.ps1](../scripts/powershell/01-dc01-network-config.ps1)

```powershell
# Run in elevated PowerShell on dc01
New-NetIPAddress -InterfaceAlias 'Ethernet 2' `
    -IPAddress 192.168.56.10 `
    -PrefixLength 24 `
    -DefaultGateway 192.168.56.1

Set-DnsClientServerAddress -InterfaceAlias 'Ethernet 2' `
    -ServerAddresses 192.168.56.10

# Disable IPv6 and unused NAT adapter (optional after setup)
Disable-NetAdapterBinding -Name 'Ethernet 2' -ComponentID ms_tcpip6
Disable-NetAdapter -Name 'Ethernet' -Confirm:$false
```

## dc02 — Replica Domain Controller

**Script:** [scripts/powershell/02-dc02-network-config.ps1](../scripts/powershell/02-dc02-network-config.ps1)

```powershell
New-NetIPAddress -InterfaceAlias 'Ethernet 2' `
    -IPAddress 192.168.56.102 `
    -PrefixLength 24 `
    -DefaultGateway 192.168.56.1

Set-DnsClientServerAddress -InterfaceAlias 'Ethernet 2' `
    -ServerAddresses 192.168.56.10, 192.168.56.102

Disable-NetAdapterBinding -Name 'Ethernet 2' -ComponentID ms_tcpip6
Disable-NetAdapter -Name 'Ethernet' -Confirm:$false
```

## wkstn01 — Domain Workstation

**Script:** [scripts/powershell/03-wkstn01-network-config.ps1](../scripts/powershell/03-wkstn01-network-config.ps1)

```powershell
New-NetIPAddress -InterfaceAlias 'Ethernet 2' `
    -IPAddress 192.168.56.20 `
    -PrefixLength 24 `
    -DefaultGateway 192.168.56.1

Set-DnsClientServerAddress -InterfaceAlias 'Ethernet 2' `
    -ServerAddresses 192.168.56.10

Disable-NetAdapterBinding -Name 'Ethernet 2' -ComponentID ms_tcpip6
Disable-NetAdapter -Name 'Ethernet' -Confirm:$false
```

## siem01 — Ubuntu SIEM

Edit `/etc/netplan/00-installer-config.yaml` on siem01:

```yaml
network:
  version: 2
  ethernets:
    enp0s3:        # NAT adapter (for updates)
      dhcp4: true
    enp0s8:        # Host-only adapter
      addresses:
        - 192.168.56.103/24
      nameservers:
        addresses: [192.168.56.10]
```

Apply:

```bash
sudo netplan apply
```

```bash
ip addr show
ip route show
ping -c 2 192.168.56.10
```

## Verify Connectivity

From dc01, test that all VMs are reachable:

```powershell
Test-Connection 192.168.56.102 -Count 2   # dc02
Test-Connection 192.168.56.20  -Count 2   # wkstn01
Test-Connection 192.168.56.103 -Count 2   # siem01
```

Expected: all return `Status: Success`
