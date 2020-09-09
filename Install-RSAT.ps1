#Requires -version 5.0
#Requires -RunAsAdministrator

# Function for the building block of objects which will store information about current registry status
function Store-RegistryValue ($Name, $Path, $PropertyType, $Value, $Exists, $Changed) {

    # properties of the future objects
    $properties = @{
        
        Name = $Name
        Path = $Path
        PropertyType = $PropertyType
        Value = $Value
        Exists = [bool]$Exists
        Changed = [bool]$Changed

    }

    # New object being created when function is called
    $object = New-Object -TypeName psobject -Property $properties
    
    # Object is returned after function is called
    return $object

}


# Check whether the items exist in Try/Catch blocks.
# These blocks are objectively bad, rewrite later in a single function that is called for the different registry properties.
try {
    # ErrorAction Stop is necessary for the try/catch blocks to catch the error since it's a non-terminating error
    $checkUseWUServer = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -ErrorAction Stop    
    
    # Runs only if there's no error
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU')
    $UseWUServer = Store-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value $($checkUseWUServer.UseWUServer) -PropertyType $key.GetValueKind('UseWUServer') -Exists $true -Changed $false
    $key.Dispose()
}
catch {
    $UseWUServer = Store-RegistryValue -Name UseWUServer -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Exists $false -Changed $false
}

try {
    # ErrorAction Stop is necessary for the try/catch blocks to catch the error since it's a non-terminating error
    $checkLocalSourcePath = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Name "LocalSourcePath" -ErrorAction Stop    

    # Runs only if there's no error
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing')
    $LocalSourcePath = Store-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Name "LocalSourcePath" -Value $($checkLocalSourcePath.LocalSourcePath) -PropertyType $key.GetValueKind('LocalSourcePath') -Exists $true -Changed $false
    $key.Dispose()
}
catch {
    $LocalSourcePath = Store-RegistryValue -Name LocalSourcePath -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Exists $false -Changed $false
}

try {

    # ErrorAction Stop is necessary for the try/catch blocks to catch the error since it's a non-terminating error
    $checkRepairContentServerSource = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Name "RepairContentServerSource" -ErrorAction Stop    
    # Runs only if there's no error
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing')
    $RepairContentServerSource = Store-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Name "RepairContentServerSource" -Value $($checkRepairContentServerSource.RepairContentServerSource) -PropertyType $key.GetValueKind('RepairContentServerSource')  -Exists $true  -Changed $false
    $key.Dispose()

}
catch {
    $RepairContentServerSource = Store-RegistryValue -Name RepairContentServerSource -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Exists $false -Changed $false
}


# Check status of RSAT packages installed in a variable
$check = Get-WindowsCapability -name RSAT* -Online

# Define $finishloop being false
$finishloop = $false

# Loop through each individual object in the array
foreach ($value in $check) {

    # Check if object state is NotPresent, if it is, proceed with it's installation
    If ($value.State -eq "NotPresent"){
        # This block finds that something is not installed and then moves on to try to install it

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

                    New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing -PropertyType ExpandString -Name LocalSourcePath
                    New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing -PropertyType DWord -Name RepairContentServerSource -Value 2

                    # flagging changes
                    $LocalSourcePath.Changed = $true
                    $RepairContentServerSource.Changed = $true


                }
                elseif (($ErrorMessage -like "*0x8024002e*") -or ($ErrorMessage -like "*0x8024402c*")) {
                    # In case of error 0x8024002e, perform the following tasks to fix it
                    Write-Host "Error contains the string 0x8024002e or 0x8024402c..." -ForegroundColor Cyan

                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value 0

                    # flagging changes
                    $UseWUServer.Changed = $true

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

# Revert the changes made during script run
# Cleanup happens here
<# If a registry property has not changed, SKIP.

However, if a registry property has changed, if it does NOT EXIST,
-> delete the registry property

Also, if a registry property has changed, if it DOES EXIST,
-> Set the item property to the value stored in the object property
#>
Write-Host "Reverting changes made to registry..."
$LocalSourcePath, $RepairContentServerSource, $UseWUServer | ForEach-Object {

    if ($_.Changed -eq $true) {
        Write-Host "Currently fixing $($_.Name)" -ForegroundColor Magenta

        If ($_.Exists -eq $false) {
            # Since this property did not exist before, it should be deleted
            Write-Host "--- Deleting property $($_.Name) ---" -ForegroundColor Yellow
            Remove-ItemProperty -Path $_.path -Name $_.name
        } else {
            # This property existed, so we need to set the previous value
            Write-Host "--- Resetting property $($_.Name) to default---"
            Set-ItemProperty -Path $_.path -Name $_.name -Value $_.value
        }
    } else {
        Write-Host "No change to $($_.Name), skipping..."
    }
}