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
.\repair_ssh_permissions.ps1 -path "C:\Users\John Doe\.ssh"

#>

[CmdletBinding(

)]
Param (

    [String]
    $path
)


# Default the target directory path to '%USERPROFILE%/.ssh'.
if (!$path) {
    $path = $(Join-Path -Path "$env:USERPROFILE" -ChildPath ".ssh")
}

function Disable-Inheritance([String] $item) {

    Write-Host "Disable inheritance on '${item}'..."

    $acl = Get-Acl -Path $item
    $acl.SetAccessRuleProtection($true, $true)
    Set-Acl -Path $item -AclObject $acl
}

function Remove-AllAccessPermissions([String] $item) {

    Write-Host "Removing all access permissions on '${item}'..."

    $acl = Get-Acl -Path "$item"

    ForEach($accessRule in $acl.Access) {
        $acl.RemoveAccessRule($accessRule) | Out-Null
    }

    Set-Acl -Path $item -AclObject $acl
}

function Grant-CurrentUserFullControl([String] $item) {

    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    Write-Host "Granting '$currentUser' full control over '${item}'..."

    $acl = Get-Acl -Path $item

    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $currentUser,
        "FullControl",
        "Allow"
    )

    $acl.SetAccessRule($accessRule)

    Set-Acl -Path $item -AclObject $acl
}


Write-Host "Fixing directory and file permissions of '${path}'..."

$directories = @(Get-ChildItem -Path $path -Directory -Recurse).FullName

foreach ($directory in $directories) {

    Disable-Inheritance -item $directory
    Remove-AllAccessPermissions -item $directory
    Grant-CurrentUserFullControl -item $directory
}

#
# TODO:
#
#     1. Include the root directory
#     2. Include all files within
#     3. Group all items and loop once
#
