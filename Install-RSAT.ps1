# Initial script source from : Source: http://woshub.com/install-rsat-feature-windows-10-powershell/ 
# Modify to be more automated and easy
$currentWU = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" | select -ExpandProperty UseWUServer 
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value 0 
Restart-Service wuauserv 
Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability –Online 
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value $currentWU 
Restart-Service wuauserv 

# Command to test if everything is installed: 
Get-WindowsCapability -Name RSAT* -Online | Select-Object -Property DisplayName, State 