<#
.SYNOPSIS
    Runner script for Privilege Cloud Safe Management using ISPSS Identity Authentication.

.DESCRIPTION
    Authenticates to CyberArk Privilege Cloud via the IdentityAuth module and runs
    Safe-Management.ps1 with the resulting token. Assumes IdentityAuth.psm1 and
    Safe-Management.ps1 are in the same directory as this script.

.EXAMPLE
    # Interactive login - list all safes
    .\runner.ps1 -PCloudSubdomain "mycompany" -Report

.EXAMPLE
    # Interactive login - add a safe
    .\runner.ps1 -PCloudSubdomain "mycompany" -Add -SafeName "MySafe"

.EXAMPLE
    # Login with pre-built credentials
    $creds = Get-Credential
    .\runner.ps1 -PCloudSubdomain "mycompany" -UPCreds $creds -Report
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, HelpMessage = 'Privilege Cloud subdomain (e.g. "mycompany" from mycompany.privilegecloud.cyberark.cloud)')]
    [string]$PCloudSubdomain,

    [Parameter(HelpMessage = 'Username for interactive ISPSS authentication')]
    [string]$IdentityUserName,

    [Parameter(HelpMessage = 'PSCredential for username/password authentication')]
    [PSCredential]$UPCreds,

    [Parameter(HelpMessage = 'List safes')]
    [switch]$Report,

    [Parameter(HelpMessage = 'Add a safe')]
    [switch]$Add,

    [Parameter(HelpMessage = 'Update a safe')]
    [switch]$Update,

    [Parameter(HelpMessage = 'Delete a safe')]
    [switch]$Delete,

    [Parameter(HelpMessage = 'Add members to a safe')]
    [switch]$AddMembers,

    [Parameter(HelpMessage = 'Update safe members')]
    [switch]$UpdateMembers,

    [Parameter(HelpMessage = 'Delete safe members')]
    [switch]$DeleteMembers,

    [Parameter(HelpMessage = 'List safe members')]
    [switch]$Members,

    [Parameter(HelpMessage = 'Safe name')]
    [string]$SafeName
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Import IdentityAuth module ---
$modulePath = Join-Path $scriptDir 'IdentityAuth.psm1'
if (-not (Test-Path $modulePath)) {
    throw "IdentityAuth.psm1 not found at: $modulePath"
}
Import-Module $modulePath -Force

# --- Build Privilege Cloud URL ---
$PCloudURL = "https://$PCloudSubdomain.privilegecloud.cyberark.cloud"
$PVWAURL   = "$PCloudURL/PasswordVault"

# --- Authenticate ---
$authParams = @{ PCloudURL = $PCloudURL }

if ($UPCreds) {
    $authParams['UPCreds'] = $UPCreds
}
elseif ($IdentityUserName) {
    $authParams['IdentityUserName'] = $IdentityUserName
}
else {
    $IdentityUserName = Read-Host 'Enter your ISPSS username'
    $authParams['IdentityUserName'] = $IdentityUserName
}

Write-Host "Authenticating to $PCloudURL ..." -ForegroundColor Cyan
$logonToken = Get-IdentityHeader @authParams
Write-Host 'Authentication successful.' -ForegroundColor Green

# --- Build Safe-Management arguments ---
$smScript = Join-Path $scriptDir 'Safe-Management.ps1'
if (-not (Test-Path $smScript)) {
    throw "Safe-Management.ps1 not found at: $smScript"
}

$smParams = @{
    PVWAURL    = $PVWAURL
    logonToken = $logonToken
}

# Pass through the chosen action
if ($Report)        { $smParams['Report']        = $true }
if ($Add)           { $smParams['Add']           = $true }
if ($Update)        { $smParams['Update']        = $true }
if ($Delete)        { $smParams['Delete']        = $true }
if ($AddMembers)    { $smParams['AddMembers']    = $true }
if ($UpdateMembers) { $smParams['UpdateMembers'] = $true }
if ($DeleteMembers) { $smParams['DeleteMembers'] = $true }
if ($Members)       { $smParams['Members']       = $true }

if ($SafeName) { $smParams['SafeName'] = $SafeName }

# --- Run Safe-Management ---
Write-Host "Running Safe-Management ..." -ForegroundColor Cyan
& $smScript @smParams
