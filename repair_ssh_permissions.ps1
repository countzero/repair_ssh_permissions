#Requires -Version 5.0

<#
.SYNOPSIS
Automatically repairs the permissions of the .ssh directory and files.

.DESCRIPTION
This script automatically repairs the permissions of the .ssh directory and files.

.PARAMETER path
Specifies the path to the .ssh directory. Defaults to '%USERPROFILE%/.ssh'.

.PARAMETER user
Specifies the user that should own the .ssh directory and its contents. Defaults to the current Windows user.

.EXAMPLE
.\repair_ssh_permissions.ps1

.EXAMPLE
.\repair_ssh_permissions.ps1 -path "C:\unusual\path\.ssh"

.EXAMPLE
.\repair_ssh_permissions.ps1 -user "Another User"

#>

[CmdletBinding()]
Param (

    [String]
    $path,

    [String]
    $user
)


# Default the target path to '%USERPROFILE%/.ssh'.
if (!$path) {
    $path = $(Join-Path -Path "$env:USERPROFILE" -ChildPath ".ssh")
}

# Default the user to the current Windows user.
if (!$user) {
    $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
}

function Disable-Inheritance([String] $item) {

    Write-Host "Disable inheritance on '${item}'..." -ForegroundColor "DarkYellow"

    $acl = Get-Acl -Path $item
    $acl.SetAccessRuleProtection($true, $true)
    Set-Acl -Path $item -AclObject $acl
}

function Remove-AllAccessPermissions([String] $item) {

    Write-Host "Removing all access permissions on '${item}'..." -ForegroundColor "DarkYellow"

    $acl = Get-Acl -Path "$item"

    ForEach($accessRule in $acl.Access) {
        $acl.RemoveAccessRule($accessRule) | Out-Null
    }

    Set-Acl -Path $item -AclObject $acl
}

function Grant-UserFullControl([String] $item) {

    Write-Host "Granting '$user' full control over '${item}'..." -ForegroundColor "DarkYellow"

    $acl = Get-Acl -Path $item

    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $user,
        "FullControl",
        "Allow"
    )

    $acl.SetAccessRule($accessRule)

    Set-Acl -Path $item -AclObject $acl
}


Write-Host "Fixing directory and file permissions of '${path}'..." -ForegroundColor "Yellow"

# We are repairing the .ssh directory and everything within it.
$items = @($path) + @($(Get-ChildItem -Path $path -Force -Recurse).FullName)

foreach ($item in $items) {

    Disable-Inheritance -item $item
    Remove-AllAccessPermissions -item $item
    Grant-UserFullControl -item $item
}
