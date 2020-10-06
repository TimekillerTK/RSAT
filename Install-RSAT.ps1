#Requires -version 5.1
#Requires -RunAsAdministrator

# Function for the building block of objects which will store information about current registry status
function New-RegKeyInfo ($Name, $Path) {

        # properties of the future objects
        $properties = @{
        
        Name         = $Name
        Path         = $Path
        PropertyType = $PropertyType
        Value        = $Value
        Exists       = [bool]$Exists
        Changed      = [bool]$Changed

    }

    # New object being created when function is called
    $object = New-Object -TypeName psobject -Property $properties

    # Setting object properties
    $object.Path = $Path
    $object.Name = $Name
    $object.Changed = $false

    try {

        # Query the registry key
        $check = Get-ItemProperty -Name $Name -Path $Path -ErrorAction Stop

        # Runs only if there's no error
        $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("$($Path -replace '^.{6}','')")

        # Set object properties
        $object.Value = $($check.$Name)
        $object.PropertyType = $key.GetValueKind($Name)
        $object.Exists = $true

        return $object

    }
    catch {

        # Runs only if $check returns an error
        $object.Exists = $false

        return $object

    }

}

$UseWUServer = New-RegKeyInfo -Name UseWUServer -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
$LocalSourcePath = New-RegKeyInfo -Name LocalSourcePath -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing"
$RepairContentServerSource = New-RegKeyInfo -Name RepairContentServerSource -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing"


# Check status of RSAT packages installed in a variable
$check = Get-WindowsCapability -name RSAT* -Online

# Define $finishloop being false
$finishloop = $false

# Loop through each individual object in the array
foreach ($value in $check) {

    # Check if object state is NotPresent, if it is, proceed with it's installation
    If ($value.State -eq "NotPresent") {
        # This block finds that something is not installed and then moves on to try to install it

        do {
            try {
                # Try to install it
                Add-WindowsCapability -Name $value.Name -Online -ErrorAction Stop

                # This block will only run if the above command is successful
                $finishloop = $true
                Write-Host "$($value.name) installed successfully"
            }
            catch {
                # In case of error, write error message that comes up
                $ErrorMessage = $_.Exception
                Write-Output $ErrorMessage
            
                if ($ErrorMessage -like "*0x800f0954*") {
                    # In case of error 0x800f0954, perform the following tasks to fix it
                    Write-Host "Error contains the string 0x800f0954..." -ForegroundColor Cyan

                    New-Item -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing -ErrorAction SilentlyContinue
                    New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing -PropertyType ExpandString -Name LocalSourcePath
                    New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing -PropertyType DWord -Name RepairContentServerSource -Value 2

                    # flagging changes
                    $LocalSourcePath.Changed = $true
                    $RepairContentServerSource.Changed = $true


                }
                elseif (($ErrorMessage -like "*0x8024002e*") -or ($ErrorMessage -like "*0x8024402c*") -or ($ErrorMessage -like "*0x8024500c*")) {
                    # In case of error 0x8024002e, perform the following tasks to fix it
                    Write-Host "Error contains the string 0x8024002e, 0x8024402c or 0x8024500c..." -ForegroundColor Cyan

                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value 0

                    # flagging changes
                    $UseWUServer.Changed = $true
                    s
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
        Write-Host "$($value.name) is already installed, skipping..."
    }
}

#Revert the changes made during script run
#Cleanup happens here

Write-Host "Reverting changes made to registry..."
$LocalSourcePath, $RepairContentServerSource, $UseWUServer | ForEach-Object {

    if ($_.Changed -eq $true) {
        Write-Host "Currently fixing $($_.Name)" -ForegroundColor Magenta

        If ($_.Exists -eq $false) {
            # Since this property did not exist before, it should be deleted
            Write-Host "--- Deleting property $($_.Name) ---" -ForegroundColor Yellow
            Remove-ItemProperty -Path $_.path -Name $_.name
        }
        else {
            # This property existed, so we need to set the previous value
            Write-Host "--- Resetting property $($_.Name) to default---"
            Set-ItemProperty -Path $_.path -Name $_.name -Value $_.value
            
            if ($_.name -eq "UseWUServer") {
                Write-Host "--- Restarting service wuauserv ---"
                Restart-Service wuauserv
            }
        }
    }
    else {
       Write-Output "No change to $($_.Name), skipping..."
    }
}
