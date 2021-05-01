# Repair the permissions of the .ssh directory and files
The best practice configuration for the personal .ssh directory is to restrict all access to the corresponding local user. This will be enforced by OpenSSH and any misconfiguration will result in OpenSSH ignoring the .ssh directory contents with a warning.

This PowerShell script automatically repairs the permissions of the .ssh directory and files. It does the following for all items within and including the given .ssh directory:

* Disables inheritance
* Sets ownership to one user
* Removes all permissions
* Grants one user full control

## Installation
Download and unpack the [latest release](https://github.com/countzero/repair_ssh_permissions/releases/latest) to your machine.

## Usage
Open a PowerShell console at the location of the unpacked release and execute the [./repair_ssh_permissions.ps1](https://github.com/countzero/repair_ssh_permissions/blob/main/repair_ssh_permissions.ps1).

**Hint:** If you are running into an `SeSecurityPrivilege` Error execute the command with administrator privileges.

## Examples

### Repair the current users default .ssh directory
Execute the following command with administrator privileges to repair the '%USERPROFILE%/.ssh' directory (and all items within) for the current Windows user.

```PowerShell
.\repair_ssh_permissions.ps1
```

### Repair a specific .ssh directory for a specific user
Execute the following command with administrator privileges to repair a specific directory for a specific local Windows user.

```PowerShell
.\repair_ssh_permissions.ps1 -path "X:\unsual\path\to\.ssh" -user "John Doe"
```

### Get detailed help
Execute the following command to get detailed help.

```PowerShell
Get-Help .\repair_ssh_permissions.ps1 -detailed
```
