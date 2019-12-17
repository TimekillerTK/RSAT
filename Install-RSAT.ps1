# Check status of RSAT packages installed in a variable
$check = Get-WindowsCapability -name RSAT* -Online

# Define $finishloop being false
$finishloop = $false

# Memorize current values of registry keys that will be modified (To be added later)
# $currentWU = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" | select -ExpandProperty UseWUServer

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
                    Write-Output "$value installed successfully"
                    $finishloop = $true
                }
            }
            catch {
                $ErrorMessage = $_.Exception
                Write-Output $ErrorMessage
            
                if ($ErrorMessage -like "*0x800f0954*") {
                    Write-Host "Error contains the string 0x800f0954..." -ForegroundColor Cyan
                    New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing -PropertyType ExpandString -Name LocalSourcePath
                    New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing -PropertyType DWord -Name RepairContentServerSource -Value 2

                }
                elseif ($ErrorMessage -like "*0x8024002e*") {
                    Write-Host "Error contains the string 0x8024002e..." -ForegroundColor Cyan
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
        Write-Host $value.name"is already installed, skipping..." -ForegroundColor White
    }
}