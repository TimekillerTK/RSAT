# RSAT
Script to automatically reinstall RSAT tools on your workstation after a windows feature update. Automatically reverts changes to registry after completion.

What it does:
* Stores current registry values in PSobjects
* Attempts to install `RSAT*` packages
* If fail - makes changes to registry based on windows error codes
* After successful install of `RSAT*` packages, reverts changes to registry

# How to Use
* Clone the repo or download the `Install-RSAT.ps1` file.
* Run in an administrative powershell prompt `.\Install-RSAT.ps1`

# Requirements
* Powershell 5.1+
* Must be run with administrative privileges due to the following cmdlets:
  * Add-WindowsCapability
  * Restart-Service
