# Section 5: Active Directory Setup

Complete AD DS deployment: forest creation, replica DC, OU structure, bulk users, service accounts, and privileged admin accounts.

## Recommended Execution Order

Follow this sequence to reproduce the tracked lab build cleanly:

1. Configure networking on all VMs from [docs/03-network-configuration.md](../docs/03-network-configuration.md)
2. Configure WinRM from [docs/04-winrm-ansible-setup.md](../docs/04-winrm-ansible-setup.md) if you want remote execution from WSL2
3. Promote `dc01`
4. Promote `dc02`
5. Join `wkstn01` to the domain
6. Create the OU structure
7. Create the 1,800 bulk users
8. Create the service accounts and SPNs
9. Create the Tier0 admin accounts

You can run the tracked PowerShell scripts directly inside each VM or copy/run them remotely with Ansible after WinRM is working.

## 5.1 — Promote dc01 (Primary Domain Controller)

**Script:** [scripts/powershell/05-promote-dc01.ps1](../scripts/powershell/05-promote-dc01.ps1)

```powershell
# Install AD DS role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote to forest root DC
Install-ADDSForest `
    -DomainName 'corp.techcorp.internal' `
    -DomainNetbiosName 'TECHCORP' `
    -ForestMode 'WinThreshold' `
    -DomainMode 'WinThreshold' `
    -InstallDns:$true `
    -SafeModeAdministratorPassword (ConvertTo-SecureString '<YOUR_DSRM_PASSWORD>' -AsPlainText -Force) `
    -Force:$true
```

VM reboots automatically after promotion.

**Verify before continuing:**

```powershell
Get-ADDomain
Get-ADDomainController -Filter *
```

## 5.2 — Promote dc02 (Replica Domain Controller)

**Script:** [scripts/powershell/06-promote-dc02.ps1](../scripts/powershell/06-promote-dc02.ps1)

```powershell
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Install-ADDSDomainController `
    -DomainName 'corp.techcorp.internal' `
    -InstallDns:$true `
    -Credential (Get-Credential 'TECHCORP\Administrator') `
    -SafeModeAdministratorPassword (ConvertTo-SecureString '<YOUR_DSRM_PASSWORD>' -AsPlainText -Force) `
    -Force:$true
```

**Verify before continuing:**

```powershell
Get-ADDomainController -Filter *
repadmin /replsummary
```

## 5.3 — Join wkstn01 to Domain

Run on wkstn01 after dc01 is promoted:

```powershell
Add-Computer -DomainName 'corp.techcorp.internal' `
    -Credential (Get-Credential 'TECHCORP\Administrator') `
    -Restart
```

**Verify after reboot:**

```powershell
whoami
nltest /dsgetdc:corp.techcorp.internal
```

## 5.4 — Create OU Structure

**Script:** [scripts/powershell/07-create-ou-structure.ps1](../scripts/powershell/07-create-ou-structure.ps1)

Creates a tiered OU model with 3 tiers and 9 department sub-OUs:

```powershell
$BaseDN = "DC=corp,DC=techcorp,DC=internal"

# Top-level tiers
$Tiers = @("Tier0", "Tier1", "Tier2")
foreach ($Tier in $Tiers) {
    New-ADOrganizationalUnit -Name $Tier -Path $BaseDN -ProtectedFromAccidentalDeletion $true
}

# Department OUs under Tier2
$Departments = @("IT","HR","Finance","Legal","Engineering","Marketing","Sales","Operations","Executive")
$Tier2DN = "OU=Tier2,$BaseDN"
foreach ($Dept in $Departments) {
    New-ADOrganizationalUnit -Name $Dept -Path $Tier2DN -ProtectedFromAccidentalDeletion $true
}
```

**Verify:**

```powershell
Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName
```

## 5.5 — Bulk User Creation (1,800 Users)

**Script:** [scripts/powershell/08-bulk-user-creation.ps1](../scripts/powershell/08-bulk-user-creation.ps1)

Creates 200 users per department across 9 departments (1,800 total):

```powershell
$Departments = @("IT","HR","Finance","Legal","Engineering","Marketing","Sales","Operations","Executive")
$BaseDN = "DC=corp,DC=techcorp,DC=internal"

foreach ($Dept in $Departments) {
    $OuPath = "OU=$Dept,OU=Tier2,$BaseDN"
    for ($i = 1; $i -le 200; $i++) {
        $Username = "$($Dept.ToLower())_user$i"
        New-ADUser `
            -Name "$Dept User$i" `
            -SamAccountName $Username `
            -UserPrincipalName "$Username@corp.techcorp.internal" `
            -Path $OuPath `
            -AccountPassword (ConvertTo-SecureString '<YOUR_USER_PASSWORD>' -AsPlainText -Force) `
            -Enabled $true `
            -PasswordNeverExpires $true
    }
}
```

**Verify:**

```powershell
(Get-ADUser -Filter *).Count
```

## 5.6 — Service Accounts & SPNs

**Script:** [scripts/powershell/09-service-accounts-spns.ps1](../scripts/powershell/09-service-accounts-spns.ps1)

Creates 5 service accounts with registered SPNs (required for Kerberoasting simulation T1558.003):

```powershell
$ServiceAccounts = @(
    @{ Name="svc_sql";        SPN="MSSQLSvc/dc01.corp.techcorp.internal:1433" },
    @{ Name="svc_backup";     SPN="BackupAgent/dc01.corp.techcorp.internal"   },
    @{ Name="svc_wazuh";      SPN="WazuhAgent/siem01.corp.techcorp.internal"  },
    @{ Name="svc_monitoring"; SPN="MonitorSvc/dc01.corp.techcorp.internal"    },
    @{ Name="svc_deploy";     SPN="DeployAgent/dc01.corp.techcorp.internal"   }
)

$Tier1DN = "OU=Tier1,DC=corp,DC=techcorp,DC=internal"

foreach ($SA in $ServiceAccounts) {
    New-ADUser -Name $SA.Name -SamAccountName $SA.Name `
        -Path $Tier1DN `
        -AccountPassword (ConvertTo-SecureString '<YOUR_SVC_PASSWORD>' -AsPlainText -Force) `
        -Enabled $true -PasswordNeverExpires $true
    setspn -A $SA.SPN $SA.Name
}
```

**Verify:**

```powershell
setspn -T corp.techcorp.internal -Q */*
```

## 5.7 — Tier0 Privileged Admin Accounts

**Script:** [scripts/powershell/10-tier0-admins.ps1](../scripts/powershell/10-tier0-admins.ps1)

```powershell
$Tier0Admins = @("adm_jdoe","adm_asmith","adm_mbrown","adm_kwilson","adm_rjones")
$Tier0DN = "OU=Tier0,DC=corp,DC=techcorp,DC=internal"

foreach ($Admin in $Tier0Admins) {
    New-ADUser -Name $Admin -SamAccountName $Admin `
        -Path $Tier0DN `
        -AccountPassword (ConvertTo-SecureString '<YOUR_TIER0_PASSWORD>' -AsPlainText -Force) `
        -Enabled $true -PasswordNeverExpires $true

    # Add to Domain Admins
    Add-ADGroupMember -Identity 'Domain Admins' -Members $Admin
}
```

**Verify:**

```powershell
Get-ADGroupMember -Identity 'Domain Admins' | Select-Object Name
```

## Verification

```powershell
# Confirm domain is healthy
dcdiag /test:replications

# Confirm OUs exist
Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName

# Confirm user count
(Get-ADUser -Filter *).Count   # Should be ~1,810

# Confirm SPNs
setspn -L svc_sql
```
