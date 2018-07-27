using module .\Include.psm1

param([String]$PSVersion, [String]$NFVersion)

if ($script:MyInvocation.MyCommand.Path) {Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)}

$ProgressPreferenceBackup = $ProgressPreference

Function Get-Version ($Version) {
    # System.Version objects can be compared with -gt and -lt properly
    # This strips out anything that doens't belong in a version, eg. v at the beginning, or -preview1 at the end, and returns a version object
    Return [System.Version]($Version -Split "-" -Replace "[^0-9.]")[0]
}

# Support SSL connection
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

$Name = "PowerShell"
try {
    $ProgressPreference = "SilentlyContinue"
    $Request = Invoke-RestMethod -Uri "https://api.github.com/repos/powershell/$Name/releases" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop

    # Filter to only show the latest non-preview release
    $LatestVersion = $Request.tag_name | Where-Object {$_ -notmatch '-preview|-rc|-beta|-alpha|6.0.2'} | Select-Object -First 1
    $Request = $Request | Where-Object {$_.tag_name -eq $LatestVersion}

    $Version = ($Request.tag_name -replace '^v')
    $URI = $Request.assets | Where-Object Name -EQ "$($Name)-$($Version)-win-x64.msi" | Select-Object -ExpandProperty browser_download_url

    if ( (Get-Version($Version)) -gt (Get-Version($PSVersion)) ) {
        $ProgressPreference = $ProgressPreferenceBackup
        Write-Progress -Activity "Updater" -Status $Name -CurrentOperation "Acquiring Online ($URI)"
        $ProgressPreference = "SilentlyContinue"
        Expand-WebRequest $URI -ErrorAction Stop
    }
}
catch {
    Write-Log -Level Warn "The software ($Name) failed to update. "
}

$ProgressPreference = $ProgressPreferenceBackup

Write-Progress -Activity "Updater" -Completed
