#Requires -RunAsAdministrator

$grafanaAgentService = Get-Service -Name "Grafana Agent" -ErrorAction SilentlyContinue

if ($grafanaAgentService.Length -lt 2 -and $grafanaAgentService.Status -ne 'Running') {
    Start-Service 'Grafana Agent'
    Start-Sleep -Seconds 5
}

$opsverseWEService = Get-Service -Name "opsverse-windows-exporter" -ErrorAction SilentlyContinue

if ($opsverseWEService.Length -lt 2 -and $opsverseWEService.Status -ne 'Running') {
    Start-Service 'opsverse-windows-exporter'
    Start-Sleep -Seconds 5
}