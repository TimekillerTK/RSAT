# RSAT
Script to automatically reinstall RSAT tools on your workstation after a windows feature update.

# Requirements
* Powershell 7+
* Must be run with administrative privileges due to the following cmdlets:
  * Add-WindowsCapability
  * Restart-Service

# Todo
- Add mechanism to reverse changes after script finishes, currently it must be done manually by the user
- Tested only on PWSH7, test on 5.