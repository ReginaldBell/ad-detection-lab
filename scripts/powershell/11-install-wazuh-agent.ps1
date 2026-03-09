<#
.SYNOPSIS
    Download and install the Wazuh 4.7.5 agent on a Windows VM.
.DESCRIPTION
    Downloads the Wazuh MSI agent, installs it silently, enrolls it with
    the Wazuh manager at siem01 (192.168.56.103), and starts the service.
.TARGET
    Run on dc01, dc02, and wkstn01 (each separately, in elevated PowerShell).
.PREREQUISITES
    - siem01 running with Wazuh manager active
    - Temp directory exists: C:\Temp
#>

# Ensure temp directory exists
if (-not (Test-Path 'C:\Temp')) { New-Item -ItemType Directory -Path 'C:\Temp' | Out-Null }

$WazuhManagerIP = "192.168.56.103"
$AgentMSI       = "C:\Temp\wazuh-agent-4.7.5-1.msi"
$AgentURL       = "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.7.5-1.msi"

Write-Host "Downloading Wazuh agent 4.7.5..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $AgentURL -OutFile $AgentMSI -UseBasicParsing

Write-Host "Installing Wazuh agent..." -ForegroundColor Cyan
msiexec.exe /i $AgentMSI /q `
    WAZUH_MANAGER=$WazuhManagerIP `
    WAZUH_REGISTRATION_SERVER=$WazuhManagerIP `
    WAZUH_AGENT_GROUP='windows'

# Wait for install to complete
Start-Sleep -Seconds 10

# Start the Wazuh agent service
NET START WazuhSvc

Write-Host "Wazuh agent installed and started." -ForegroundColor Green
Write-Host "Verify enrollment in Wazuh dashboard: Agents → look for this hostname" -ForegroundColor Cyan
