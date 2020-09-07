# Should also create a check to validate powershell version as 7+ and to validate running as admin.
function Test-RegistryValue {

    param (
     [parameter(Mandatory=$true)] 
     [ValidateNotNullOrEmpty()]$Path,
    
     [parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]$Value
    )
    
    try {
        Get-ItemProperty -Path $Path -Name $Value -ErrorAction Stop | Set-Variable -Name Out
        return $true
    }
    
    catch {
        return $false
    }
    
}


# Set default value of variable to false
$savedLSP = $false
$savedRCSS = $false
$savedWU = $false

# Get a list of current registry values before making any changes
# if (Test-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Value LocalSourcePath){
#     $savedLSP = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Name "LocalSourcePath"
# }

# if (Test-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Value RepairContentServerSource){
#     $savedRCSS = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Name "RepairContentServerSource" | Select-Object -ExpandProperty RepairContentServerSource
# }

if (Test-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Value UseWUServer) {
    $savedWU = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" | Select-Object -ExpandProperty UseWUServer
}


# Check status of RSAT packages installed in a variable
$check = Get-WindowsCapability -name RSAT* -Online

# Define $finishloop being false
$finishloop = $false

# Memorize current values of registry keys that will be modified (To be added later)
# $currentWU = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" | select -ExpandProperty UseWUServer
# $currentLSP = Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing -Name LocalSourcePath
# $currentRCSS = Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing -Name RepairContentServerSource

# Loop through each individual object in the array
foreach ($value in $check) {

    # Check if object state is NotPresent, if it is, proceed with it's installation
    If ($value.State -eq "NotPresent"){
        # This block finds that something is not installs and then move to try to install it

        do {
            try {
                #Try to install it
                Add-WindowsCapability -Name $value.Name –Online -ErrorAction Continue

                #If installed successfully, set $finishloop to $true, otherwise continue
                if ($?) {
                    Write-Output $value.name"installed successfully"
                    $finishloop = $true
                }
            }
            catch {
                # In case of error, write error message that comes up
                $ErrorMessage = $_.Exception
                Write-Output $ErrorMessage
            
                if ($ErrorMessage -like "*0x800f0954*") {
                    # In case of error 0x800f0954, perform the following tasks to fix it
                    Write-Host "Error contains the string 0x800f0954..." -ForegroundColor Cyan

                    # if (Test-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Value LocalSourcePath){
                    #     $savedLSP = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Name "LocalSourcePath"
                    # }
                    # else {
                    #     $savedLSP = "notexist"
                    # }

                    # if (Test-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Value RepairContentServerSource){
                    #     $savedRCSS = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Name "RepairContentServerSource"
                    # }
                    # else {
                    #     $savedRCSS = "notexist"
                    # }

                    New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing -PropertyType ExpandString -Name LocalSourcePath
                    New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing -PropertyType DWord -Name RepairContentServerSource -Value 2

                }
                elseif ($ErrorMessage -like "*0x8024002e*") {
                    # In case of error 0x8024002e, perform the following tasks to fix it
                    Write-Host "Error contains the string 0x8024002e..." -ForegroundColor Cyan

                    # if (Test-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Value UseWUServer){
                    #     $savedWU = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer"
                    # }

                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value 0

                    Write-Host "Restarting service wuauserv"
                    Restart-Service wuauserv
                }
                else {
                    # Unknown error, end loop
                    Write-Host "Unknown error..." -ForegroundColor Yellow
                    $finishloop = $true
                }
                }
            } while ($finishloop -eq $false)
    }
    else {
        # This block says the App is installed.
        Write-Host $value.name"is already installed, skipping..."
    }
}



# Revert the changes made during script run

# LSP: Test current value, if different from one set at start, revert.
# RCSS: Test current value, if different from one set at start, revert.
# WU: Test current value, if different from one set at start, revert.

$currentLSP = 

if ($savedLSP -ne $currentLSP) {
    Write-Output "Value different. No action"
}
else {

}
$savedRCSS
$savedWU

If ($(Test-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Value LocalSourcePath) -eq $false) {

}

Test-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Value RepairContentServerSource
Test-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Value UseWUServer

Remove-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing -Name LocalSourcePath