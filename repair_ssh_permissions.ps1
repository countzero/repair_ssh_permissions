#Requires -Version 5.0

<#
.SYNOPSIS
Automatically repairs the permissions of the .ssh directory and files.

.DESCRIPTION
This script automatically repairs the permissions of the .ssh directory and files.

.PARAMETER path
Specifies the path to the .ssh directory.

.EXAMPLE
.\repair_ssh_permissions.ps1

.EXAMPLE
.\repair_ssh_permissions.ps1 -path "C:\Users\Finn Kumkar\.ssh"

#>

[CmdletBinding(

)]
Param (

    [String]
    $path
)

Write-Host "Not yet implemented..."
Write-Host "${path}"
