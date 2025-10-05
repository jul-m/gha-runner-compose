#!/usr/bin/env pwsh
########################################################################################################################
##  File:  docker-build/local-install/Install-PowerShellModules.ps1
##  Desc:  Installs PowerShell modules in gha-runner-compose builds
########################################################################################################################

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Specifies the installation policy
Set-PSRepository -InstallationPolicy Trusted -Name PSGallery
Install-Module -Name PowerShellGet -Force -SkipPublisherCheck -Scope AllUsers

# Modules to install by default
$baseModules = @('Pester')

# If script is called with PWSH_MODULES from Dockerfile, install those modules instead of the base ones
if ($env:PWSH_MODULES) {
    foreach($module in $env:PWSH_MODULES -split ',') {
        $module = $module.Trim()
        if ($module) {
            Write-Host "Installing additional $module module"
            Install-Module -Name $module -Force -SkipPublisherCheck -Scope AllUsers
        }
    }
} else {
    foreach($module in $baseModules) {
        Write-Host "Installing $module module"
        Install-Module -Name $module -Force -SkipPublisherCheck -Scope AllUsers
    }
}
