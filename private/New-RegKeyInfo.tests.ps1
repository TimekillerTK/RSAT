#region:Header
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
#endregion

Describe "New-RegKeyInfo function" {
    Context "Check Parameters" {
        It "Checking Name" {

            Get-Command "New-RegKeyInfo" | Should -HaveParameter Name

        }
        It "Checking Path" {

            Get-Command "New-RegKeyInfo" | Should -HaveParameter Path

        }

    }
}