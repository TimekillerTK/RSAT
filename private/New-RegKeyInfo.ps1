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