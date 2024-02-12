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

# We are breaking on the first exception.
Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

# We are self elevating this script if it is not executed with administrator privileges.
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (!($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Start-Process PowerShell `
        -Verb RunAs `
        -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -Command `"cd '${pwd}'; & '${PSCommandPath}';`""
    exit
}

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

function Set-UserOwnership([String] $item) {

    Write-Host "Let '$user' own '${item}'..." -ForegroundColor "DarkYellow"

    $acl = Get-Acl -Path $item

    $userAccount = New-Object System.Security.Principal.NTAccount($user)

    $acl.SetOwner($userAccount)

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

function Repair-Item([String] $item) {

    Write-Host "Repairing SSH item '$item'..." -ForegroundColor "White"

    Disable-Inheritance -item $item
    Set-UserOwnership -item $item
    Remove-AllAccessPermissions -item $item
    Grant-UserFullControl -item $item
}

function Repair-DirectoryAndFiles([String] $directoryPath) {

    Repair-Item -item $directoryPath

    $directoryIsEmpty = $($(Get-ChildItem $directoryPath) | Measure-Object).Count -eq 0

    if ($directoryIsEmpty) {
        return;
    }

    $files = @($(Get-ChildItem -File -Path $directoryPath -Force))
    foreach ($file in $files) {

        Repair-Item -item $file.FullName
    }

    $directories = @($(Get-ChildItem -Directory -Path $directoryPath -Force))
    foreach ($directory in $directories) {

        Repair-DirectoryAndFiles($directory.FullName)
    }
}

Write-Host "Repairing SSH directory and file permissions..." -ForegroundColor "Green"

# We have to repair the .ssh directory first to gain read permissions.
Repair-Item -item $path

# If the entry point directory is a symbolic link we
# are also repairing its target and proceed from there.
if ($(Get-Item $path).LinkType -eq 'SymbolicLink') {
    $path = $(Get-Item $path).Target
    Repair-Item -item $path
}

# We are recursively repairing all directories and files.
Repair-DirectoryAndFiles($path)

Write-Host "Successfully repaired SSH directory and file permissions." -ForegroundColor "Green"
