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


# Main Loop below
Get-WindowsCapability -name RSAT* -Online | ForEach-Object {
    If($_ -eq "Installed"){
        Write-Output "True!!!!"
    }
    else {
        Write-Output "FALSE"
    }
}


if ((Get-WindowsCapability -name RSAT* -Online).State -contains "NotPresent") {
    Write-Output (Get-WindowsCapability -name RSAT* -Online).State
    Write-Output "Something is Missing..."
    Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online
}
else {
    Write-Output "OK!"
}


$check = Get-WindowsCapability -name RSAT* -Online

foreach ($state in $check.State) {
    If ($state -eq "NotPresent"){
        Write-Output "It's Not Present"
        Write-Output "Code would execute here...."
        Write-Output $state
    }
    else {
        Write-Output "This one is OK"
    }
}

# Check status of RSAT packages installed and store them in an array (?)
$check = Get-WindowsCapability -name RSAT* -Online

# Loop through each individual object in the array
foreach ($value in $check) {
    # Check if object state is NotPresent, if it is, proceed with it's installation
    If ($value.State -eq "NotPresent"){
        # This block finds that something is not installs and then move to try to install it.
        #Line below is just debug
        Write-Output $value
        try {
            #Try to install it
            Add-WindowsCapability -Name $value.Name –Online -ErrorAction Stop
        }
        catch {
            $ErrorMessage = $_.Exception
            Write-Output $ErrorMessage
        }
    }
    else {
        # This block says everything is OK
        #Line below is just debug
        Write-Output "This one is OK"
    }
}