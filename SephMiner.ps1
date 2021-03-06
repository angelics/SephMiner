﻿using module .\Include.psm1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [Alias("BTC")]
    [String]$Wallet, 
    [Parameter(Mandatory = $false)]
    [Alias("User")]
    [String]$UserName, 
    [Parameter(Mandatory = $false)]
    [Alias("Worker")]
    [String]$WorkerName = "sephminer", 
    [Parameter(Mandatory = $false)]
    [Int]$API_ID = 0, 
    [Parameter(Mandatory = $false)]
    [String]$API_Key = "", 
    [Parameter(Mandatory = $false)]
    [Int]$Interval = 60, #seconds before reading hash rate from miners
    [Parameter(Mandatory = $false)]
    [Alias("Location")]
    [String]$Region = "europe", #europe/us/asia
    [Parameter(Mandatory = $false)]
    [Switch]$SSL = $false, 
    [Parameter(Mandatory = $false)]
    [Array]$Type = @(), #AMD/NVIDIA/CPU
    [Parameter(Mandatory = $false)]
    [Array]$Algorithm = @(), #i.e. Ethash, Equihash, CryptoNightV7 etc.
    [Parameter(Mandatory = $false)]
    [Alias("Miner")]
    [Array]$MinerName = @(), 
    [Parameter(Mandatory = $false)]
    [Alias("Pool")]
    [Array]$PoolName = @(), 
    [Parameter(Mandatory = $false)]
    [Array]$ExcludeAlgorithm = @(), #i.e. Ethash, Equihash, CryptoNightV7 etc.
    [Parameter(Mandatory = $false)]
    [Alias("ExcludeMiner")]
    [Array]$ExcludeMinerName = @(), 
    [Parameter(Mandatory = $false)]
    [Alias("ExcludePool")]
    [Array]$ExcludePoolName = @(), 
    [Parameter(Mandatory = $false)]
    [Array]$Currency = ("BTC", "USD"), #i.e. GBP, EUR, ZEC, ETH etc.
    [Parameter(Mandatory = $false)]
    [Int]$Donate = 24, #Minutes per Day
    [Parameter(Mandatory = $false)]
    [String]$Proxy = "", #i.e http://192.0.0.1:8080
    [Parameter(Mandatory = $false)]
    [Int]$Delay = 0, #seconds before opening each miner
    [Parameter(Mandatory = $false)]
    [Double]$SwitchingPrevention = 1, #zero does not prevent miners switching
    [Parameter(Mandatory = $false)]
    [Switch]$ShowPoolBalances = $false
)

Clear-Host
$Strikes = 3
$SyncWindow = 5 #minutes

#Get miner hw info
$Devices = Get-Devices

Set-Location (Split-Path $MyInvocation.MyCommand.Path)
Import-Module NetSecurity -ErrorAction Ignore
Import-Module Defender -ErrorAction Ignore
Import-Module "$env:Windir\System32\WindowsPowerShell\v1.0\Modules\NetSecurity\NetSecurity.psd1" -ErrorAction Ignore
Import-Module "$env:Windir\System32\WindowsPowerShell\v1.0\Modules\Defender\Defender.psd1" -ErrorAction Ignore

$Algorithm = $Algorithm | ForEach-Object {Get-Algorithm $_}
$ExcludeAlgorithm = $ExcludeAlgorithm | ForEach-Object {Get-Algorithm $_}
$Region = $Region | ForEach-Object {Get-Region $_}
$Currency = $Currency | ForEach-Object {$_.ToUpper()}

$Timer = (Get-Date).ToUniversalTime()
$StatEnd = $Timer
$DecayStart = $Timer
$DecayPeriod = 60 #seconds
$DecayBase = 1 - 0.1 #decimal percentage

$ActiveMiners = @()
$Rates = [PSCustomObject]@{BTC = [Double]1}

#Start the log
Start-Transcript ".\Logs\SephMiner_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").txt"

#Set process priority to BelowNormal to avoid hash rate drops on systems with weak CPUs
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

if (Get-Command "Unblock-File" -ErrorAction SilentlyContinue) {Get-ChildItem . -Recurse | Unblock-File}
if ((Get-Command "Get-MpPreference" -ErrorAction SilentlyContinue) -and (Get-MpComputerStatus -ErrorAction SilentlyContinue) -and (Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)) {
    Start-Process (@{desktop = "powershell"; core = "pwsh"}.$PSEdition) "-Command Import-Module '$env:Windir\System32\WindowsPowerShell\v1.0\Modules\Defender\Defender.psd1'; Add-MpPreference -ExclusionPath '$(Convert-Path .)'" -Verb runAs
}

#Check for software updates
if (Test-Path .\Updater.ps1) {$Downloader = Start-Job -InitializationScript ([scriptblock]::Create("Set-Location('$(Get-Location)')")) -ArgumentList ($PSVersionTable.PSVersion, "") -FilePath .\Updater.ps1}

#Set donation parameters
$LastDonated = $Timer.AddDays(-1).AddHours(1)
$WalletDonate = "19pQKDfdspXm6ouTDnZHpUcmEFN8a1x9zo"
$UserNameDonate = "SephMiner"
$WorkerNameDonate = "SephMiner"
$WalletType = "BTC"
# Create config.txt if it is missing
if (!(Test-Path "Config.txt")) {
    if (Test-Path "Config.default.txt") {
        Copy-Item -Path "Config.default.txt" -Destination "Config.txt"
    }
    else {
        Write-Log -Level Error "Config.txt and Config.default.txt are missing. Cannot continue. "
        Start-Sleep 10
        Exit
    }
}

while ($true) {
    #Display downloader progress
    if ($Downloader) {$Downloader | Receive-Job}
	
    #Load the config
    $ConfigBackup = $Config
    if (Test-Path "Config.txt") {
        $Config = Get-ChildItemContent "Config.txt" -Parameters @{
            Wallet                        = $Wallet
            UserName                      = $UserName
            WorkerName                    = $WorkerName
            API_ID                        = $API_ID
            API_Key                       = $API_Key
            Interval                      = $Interval
            Region                        = $Region
            SSL                           = $SSL
            Type                          = $Type
            Algorithm                     = $Algorithm
            MinerName                     = $MinerName
            PoolName                      = $PoolName
            ExcludeAlgorithm              = $ExcludeAlgorithm
            ExcludeMinerName              = $ExcludeMinerName
            ExcludePoolName               = $ExcludePoolName
            Currency                      = $Currency
            Donate                        = $Donate
            Proxy                         = $Proxy
            Delay                         = $Delay
            SwitchingPrevention           = $SwitchingPrevention
            ShowPoolBalances              = $ShowPoolBalances
        } | Select-Object -ExpandProperty Content
    }

    #Only use configured types that are present in system
    #Explicitly include CPU, because it won't show up as a device if OpenGL drivers for CPU are not installed
    $Config.Type = $Config.Type | Where-Object {$Devices.$_ -or $_ -eq 'CPU'}

    #Error in Config.txt
    if ($Config -isnot [PSCustomObject]) {
        Write-Log -Level Error "---------------------------------------"
        Write-Log -Level Error "Critical error: Config.txt is invalid. "
        Write-Log -Level Error "---------------------------------------"
        Start-Sleep 10
        Exit
    }

    Get-ChildItem "Pools" -File | Where-Object {-not $Config.Pools.($_.BaseName)} | ForEach-Object {
        $Config.Pools | Add-Member $_.BaseName (
            [PSCustomObject]@{
                BTC     = $Wallet
                User    = $UserName
                Worker  = $WorkerName
                API_ID  = $API_ID
                API_Key = $API_Key
            }
        )
    }

    # Copy the user's config before changing anything for donation runs
    # This is used when getting pool balances so it doesn't get pool balances of the donation address instead
    $UserConfig = $Config
	
#Unprofitable algorithms
    if (Test-Path ".\UnprofitableAlgorithms.txt" -PathType Leaf -ErrorAction Ignore) {$UnprofitableAlgorithms = [Array](Get-Content ".\UnprofitableAlgorithms.txt" | ConvertFrom-Json -ErrorAction SilentlyContinue | Sort-Object -Unique)} else {$UnprofitableAlgorithms = @()}
	
    #Activate or deactivate donation
    if ($Config.Donate -lt 10) {$Config.Donate = 10}
    if ($Timer.AddDays(-1) -ge $LastDonated.AddSeconds(59)) {$LastDonated = $Timer}
    if ($Timer.AddDays(-1).AddMinutes($Config.Donate) -ge $LastDonated) {
        Write-Log "Donation run, mining to donation address for the next $(($LastDonated - ($Timer.AddDays(-1))).Minutes +1) minutes. Note: SephMiner will use ALL available pools. "
        Get-ChildItem "Pools" -File | ForEach-Object {
            $Config.Pools | Add-Member $_.BaseName (
                [PSCustomObject]@{
                    $WalletType = $WalletDonate
                    User        = $UserNameDonate
                    Worker      = $WorkerNameDonate
                }
            ) -Force
        }
        $Config | Add-Member ExcludePoolName @() -Force
    }
    else {
        Write-Log ("Mining for you. Donation run will start in {0:hh} hour(s) {0:mm} minute(s). " -f $($LastDonated.AddDays(1) - ($Timer.AddMinutes($Config.Donate))))
    }

    #Clear pool cache if the pool configuration has changed
    if (($ConfigBackup.Pools | ConvertTo-Json -Compress) -ne ($Config.Pools | ConvertTo-Json -Compress)) {$AllPools = $null}

    if ($Config.Proxy) {$PSDefaultParameterValues["*:Proxy"] = $Config.Proxy}
    else {$PSDefaultParameterValues.Remove("*:Proxy")}

    Get-ChildItem "APIs" -File | ForEach-Object {. $_.FullName}

    $Timer = (Get-Date).ToUniversalTime()

    $StatStart = $StatEnd
    $StatEnd = $Timer.AddSeconds($Config.Interval)
    $StatSpan = New-TimeSpan $StatStart $StatEnd

    $DecayExponent = [int](($Timer - $DecayStart).TotalSeconds / $DecayPeriod)

    #Update the exchange rates
    try {
        Write-Log "Updating exchange rates from Coinbase. "
        $NewRates = Invoke-RestMethod "https://api.coinbase.com/v2/exchange-rates?currency=BTC" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop | Select-Object -ExpandProperty data | Select-Object -ExpandProperty rates
        $Config.Currency | Where-Object {$NewRates.$_} | ForEach-Object {$Rates | Add-Member $_ ([Double]$NewRates.$_) -Force}
    }
    catch {
        Write-Log -Level Warn "Coinbase is down. "
    }

    #Update the pool balances
    if ($Config.ShowPoolBalances) {
        Write-Log "Getting pool balances. "
        $BalancesData = Get-Balance -Config $UserConfig -NewRates $NewRates
    }
	
    #Load the stats
    Write-Log "Loading saved statistics. "
    $Stats = Get-Stat

    #Load information about the pools
    Write-Log "Loading pool information. "
    $NewPools = @()
    if (Test-Path "Pools") {
        $NewPools = Get-ChildItem "Pools" -File | Where-Object {$Config.Pools.$($_.BaseName) -and $Config.ExcludePoolName -inotcontains $_.BaseName} | ForEach-Object {
            $Pool_Name = $_.BaseName
            $Pool_Parameters = @{StatSpan = $StatSpan}
            $Config.Pools.$Pool_Name | Get-Member -MemberType NoteProperty | ForEach-Object {$Pool_Parameters.($_.Name) = $Config.Pools.$Pool_Name.($_.Name)}
            Get-ChildItemContent "Pools\$($_.Name)" -Parameters $Pool_Parameters
        } | ForEach-Object {$_.Content | Add-Member Name $_.Name -PassThru}
    }

    # This finds any pools that were already in $AllPools (from a previous loop) but not in $NewPools. Add them back to the list. Their API likely didn't return in time, but we don't want to cut them off just yet
    # since mining is probably still working.  Then it filters out any algorithms that aren't being used.
    $AllPools = @($NewPools) + @(Compare-Object @($NewPools | Select-Object -ExpandProperty Name -Unique) @($AllPools | Select-Object -ExpandProperty Name -Unique) | Where-Object SideIndicator -EQ "=>" | Select-Object -ExpandProperty InputObject | ForEach-Object {$AllPools | Where-Object Name -EQ $_}) | 
        Where-Object {$Config.Algorithm.Count -eq 0 -or (Compare-Object $Config.Algorithm $_.Algorithm -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0} | 
        Where-Object {$Config.ExcludeAlgorithm.Count -eq 0 -or (Compare-Object $Config.ExcludeAlgorithm $_.Algorithm -IncludeEqual -ExcludeDifferent | Measure-Object).Count -eq 0} | 
        Where-Object {$Config.ExcludePoolName.Count -eq 0 -or (Compare-Object $Config.ExcludePoolName $_.Name -IncludeEqual -ExcludeDifferent | Measure-Object).Count -eq 0}

    #Update the active pools
    if ($AllPools.Count -eq 0) {
        Write-Log -Level Warn "No pools available. "
        Start-Sleep $Config.Interval
        continue
    }
    $Pools = [PSCustomObject]@{}

    Write-Log "Selecting best pool for each algorithm. "
    $AllPools.Algorithm | ForEach-Object {$_.ToLower()} | Select-Object -Unique | ForEach-Object {$Pools | Add-Member $_ ($AllPools | Where-Object Algorithm -EQ $_ | Sort-Object -Descending {$Config.PoolName.Count -eq 0 -or (Compare-Object $Config.PoolName $_.Name -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0}, {($Timer - $_.Updated).TotalMinutes -le ($SyncWindow * $Strikes)}, {$_.StablePrice * (1 - $_.MarginOfError)}, {$_.Region -EQ $Config.Region}, {$_.SSL -EQ $Config.SSL} | Select-Object -First 1)}
    if (($Pools | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {$Pools.$_.Name} | Select-Object -Unique | ForEach-Object {$AllPools | Where-Object Name -EQ $_ | Measure-Object Updated -Maximum | Select-Object -ExpandProperty Maximum} | Measure-Object -Minimum -Maximum | ForEach-Object {$_.Maximum - $_.Minimum} | Select-Object -ExpandProperty TotalMinutes) -gt $SyncWindow) {
        Write-Log -Level Warn "Pool prices are out of sync ($([Int]($Pools | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {$Pools.$_} | Measure-Object Updated -Minimum -Maximum | ForEach-Object {$_.Maximum - $_.Minimum} | Select-Object -ExpandProperty TotalMinutes)) minutes). "
    }
    $Pools | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {$Pools.$_ | Add-Member Price_Bias ($Pools.$_.Price * (1 - ($Pools.$_.MarginOfError * (& {if($Pools.$_.SwitchingPrevention){$Pools.$_.SwitchingPrevention}else{$Config.SwitchingPrevention}}) * [Math]::Pow($DecayBase, $DecayExponent)))) -Force}
    $Pools | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {$Pools.$_ | Add-Member Price_Unbias $Pools.$_.Price -Force}

    #Load information about the miners
    #Messy...?
    Write-Log "Getting miner information. "
    # Get all the miners, get just the .Content property and add the name, select only the ones that match our $Config.Type (CPU, AMD, NVIDIA) or all of them if type is unset,
    # select only the ones that have a HashRate matching our algorithms, and that only include algorithms we have pools for
    # select only the miners that match $Config.MinerName, if specified, and don't match $Config.ExcludeMinerName
    $AllMiners = if (Test-Path "Miners") {
        Get-ChildItemContentParallel "Miners" -Parameters @{Pools = $Pools; Stats = $Stats; Config = $Config; Devices = $Devices} | ForEach-Object {$_.Content | Add-Member Name $_.Name -PassThru -Force} | 
            Where-Object {$Config.Type.Count -eq 0 -or (Compare-Object $Config.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0} | 
            Where-Object {($Config.Algorithm.Count -eq 0 -or (Compare-Object $Config.Algorithm $_.HashRates.PSObject.Properties.Name | Where-Object SideIndicator -EQ "=>" | Measure-Object).Count -eq 0) -and ((Compare-Object $Pools.PSObject.Properties.Name $_.HashRates.PSObject.Properties.Name | Where-Object SideIndicator -EQ "=>" | Measure-Object).Count -eq 0)} | 
            Where-Object {$Config.ExcludeAlgorithm.Count -eq 0 -or (Compare-Object $Config.ExcludeAlgorithm $_.HashRates.PSObject.Properties.Name -IncludeEqual -ExcludeDifferent | Measure-Object).Count -eq 0} | 
            Where-Object {$UnprofitableAlgorithms -notcontains (($_.HashRates.PSObject.Properties.Name | Select-Object -Index 0) -replace 'NiceHash'<#temp fix#>)} | 
            Where-Object {$Config.MinerName.Count -eq 0 -or (Compare-Object $Config.MinerName $_.Name -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0} | 
            Where-Object {$Config.ExcludeMinerName.Count -eq 0 -or (Compare-Object $Config.ExcludeMinerName $_.Name -IncludeEqual -ExcludeDifferent | Measure-Object).Count -eq 0}
    }
    Write-Log "Calculating profit for each miner. "
    $AllMiners | ForEach-Object {
        $Miner = $_

        $Miner_HashRates = [PSCustomObject]@{}
        $Miner_Pools = [PSCustomObject]@{}
        $Miner_Pools_Comparison = [PSCustomObject]@{}
        $Miner_Profits = [PSCustomObject]@{}
        $Miner_Profits_Comparison = [PSCustomObject]@{}
        $Miner_Profits_MarginOfError = [PSCustomObject]@{}
        $Miner_Profits_Bias = [PSCustomObject]@{}
        $Miner_Profits_Unbias = [PSCustomObject]@{}

        $Miner_Types = $Miner.Type | Select-Object -Unique
        $Miner_Indexes = $Miner.Index | Select-Object -Unique

        $Miner.HashRates.PSObject.Properties.Name | ForEach-Object { #temp fix, must use 'PSObject.Properties' to preserve order
            $Miner_HashRates | Add-Member $_ ([Double]$Miner.HashRates.$_)
            $Miner_Pools | Add-Member $_ ([PSCustomObject]$Pools.$_)
            $Miner_Pools_Comparison | Add-Member $_ ([PSCustomObject]$Pools.$_)
            $Miner_Profits | Add-Member $_ ([Double]$Miner.HashRates.$_ * $Pools.$_.Price)
            $Miner_Profits_Comparison | Add-Member $_ ([Double]$Miner.HashRates.$_ * $Pools.$_.StablePrice)
            $Miner_Profits_Bias | Add-Member $_ ([Double]$Miner.HashRates.$_ * $Pools.$_.Price_Bias)
            $Miner_Profits_Unbias | Add-Member $_ ([Double]$Miner.HashRates.$_ * $Pools.$_.Price_Unbias)
        }

        $Miner_Profit = [Double]($Miner_Profits.PSObject.Properties.Value | Measure-Object -Sum).Sum
        $Miner_Profit_Comparison = [Double]($Miner_Profits_Comparison.PSObject.Properties.Value | Measure-Object -Sum).Sum
        $Miner_Profit_Bias = [Double]($Miner_Profits_Bias.PSObject.Properties.Value | Measure-Object -Sum).Sum
        $Miner_Profit_Unbias = [Double]($Miner_Profits_Unbias.PSObject.Properties.Value | Measure-Object -Sum).Sum

        $Miner.HashRates | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
            $Miner_Profits_MarginOfError | Add-Member $_ ([Double]$Pools.$_.MarginOfError * (& {if ($Miner_Profit) {([Double]$Miner.HashRates.$_ * $Pools.$_.StablePrice) / $Miner_Profit}else {1}}))
        }

        $Miner_Profit_MarginOfError = [Double]($Miner_Profits_MarginOfError.PSObject.Properties.Value | Measure-Object -Sum).Sum
        if ($Miner_Profit_MarginOfError -LT 0) {Write-Log -Level Warn "$($Miner.HashRates.PSObject.Properties.Name) less than zero $($Miner_Profit_MarginOfError)"}
		
        $Miner.HashRates | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
            if (-not [String]$Miner.HashRates.$_) {
                $Miner_HashRates.$_ = $null
                $Miner_Profits.$_ = $null
                $Miner_Profits_Comparison.$_ = $null
                $Miner_Profits_Bias.$_ = $null
                $Miner_Profits_Unbias.$_ = $null
                $Miner_Profit = $null
                $Miner_Profit_Comparison = $null
                $Miner_Profits_MarginOfError = $null
                $Miner_Profit_Bias = $null
                $Miner_Profit_Unbias = $null
            }
        }

        if ($Miner_Types -eq $null) {$Miner_Types = $AllMiners.Type | Select-Object -Unique}
        if ($Miner_Indexes -eq $null) {$Miner_Indexes = $AllMiners.Index | Select-Object -Unique}

        if ($Miner_Types -eq $null) {$Miner_Types = ""}
        if ($Miner_Indexes -eq $null) {$Miner_Indexes = 0}

        $Miner.HashRates = $Miner_HashRates

        $Miner | Add-Member Pools $Miner_Pools
        $Miner | Add-Member Profits $Miner_Profits
        $Miner | Add-Member Profits_Comparison $Miner_Profits_Comparison
        $Miner | Add-Member Profits_Bias $Miner_Profits_Bias
        $Miner | Add-Member Profits_Unbias $Miner_Profits_Unbias
        $Miner | Add-Member Profit $Miner_Profit
        $Miner | Add-Member Profit_Comparison $Miner_Profit_Comparison
        $Miner | Add-Member Profit_MarginOfError $Miner_Profit_MarginOfError
        $Miner | Add-Member Profit_Bias $Miner_Profit_Bias
        $Miner | Add-Member Profit_Unbias $Miner_Profit_Unbias

        $Miner | Add-Member Type ($Miner_Types | Sort-Object) -Force
        $Miner | Add-Member Index ($Miner_Indexes | Sort-Object) -Force

        $Miner.Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Miner.Path)
        if ($Miner.PrerequisitePath) {$Miner.PrerequisitePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Miner.PrerequisitePath)}

        if ($Miner.Arguments -isnot [String]) {$Miner.Arguments = $Miner.Arguments | ConvertTo-Json -Compress}

        if (-not $Miner.API) {$Miner | Add-Member API "Miner" -Force}
    }
    $Miners = $AllMiners | Where-Object {(Test-Path $_.Path) -and ((-not $_.PrerequisitePath) -or (Test-Path $_.PrerequisitePath))}
    if ($Miners.Count -ne $AllMiners.Count -and $Downloader.State -ne "Running") {
        Write-Log -Level Warn "Some miners binaries are missing, starting downloader. "
        $Downloader = Start-Job -InitializationScript ([scriptblock]::Create("Set-Location('$(Get-Location)')")) -ArgumentList (@($AllMiners | Where-Object {$_.PrerequisitePath} | Select-Object @{name = "URI"; expression = {$_.PrerequisiteURI}}, @{name = "Path"; expression = {$_.PrerequisitePath}}, @{name = "Searchable"; expression = {$false}}) + @($AllMiners | Select-Object URI, Path, @{name = "Searchable"; expression = {$Miner = $_; ($AllMiners | Where-Object {(Split-Path $_.Path -Leaf) -eq (Split-Path $Miner.Path -Leaf) -and $_.URI -ne $Miner.URI}).Count -eq 0}}) | Select-Object * -Unique) -FilePath .\Downloader.ps1
    }
    # Open firewall ports for all miners
    if (Get-Command "Get-MpPreference" -ErrorAction SilentlyContinue) {
        if ((Get-Command "Get-MpComputerStatus" -ErrorAction SilentlyContinue) -and (Get-MpComputerStatus -ErrorAction SilentlyContinue)) {
            if (Get-Command "Get-NetFirewallRule" -ErrorAction SilentlyContinue) {
                if ($MinerFirewalls -eq $null) {$MinerFirewalls = Get-NetFirewallApplicationFilter | Select-Object -ExpandProperty Program}
                if (@($AllMiners | Select-Object -ExpandProperty Path -Unique) | Compare-Object @($MinerFirewalls) | Where-Object SideIndicator -EQ "=>") {
                    Start-Process (@{desktop = "powershell"; core = "pwsh"}.$PSEdition) ("-Command Import-Module '$env:Windir\System32\WindowsPowerShell\v1.0\Modules\NetSecurity\NetSecurity.psd1'; ('$(@($AllMiners | Select-Object -ExpandProperty Path -Unique) | Compare-Object @($MinerFirewalls) | Where-Object SideIndicator -EQ '=>' | Select-Object -ExpandProperty InputObject | ConvertTo-Json -Compress)' | ConvertFrom-Json) | ForEach {New-NetFirewallRule -DisplayName 'SephMiner' -Program `$_}" -replace '"', '\"') -Verb runAs
                    $MinerFirewalls = $null
                }
            }
        }
    }

    #Update the active miners
    if ($Miners.Count -eq 0) {
        Write-Log -Level Warn "No miners available. "
        Start-Sleep $Config.Interval
        continue
    }

    $ActiveMiners | ForEach-Object {
        $_.Profit = 0
        $_.Profit_Comparison = 0
        $_.Profit_MarginOfError = 0
        $_.Profit_Bias = 0
        $_.Profit_Unbias = 0
        $_.Best = $false
        $_.Best_Comparison = $false
    }
    $Miners | ForEach-Object {
        $Miner = $_
        $ActiveMiner = $ActiveMiners | Where-Object {
            $_.Name -eq $Miner.Name -and 
            $_.Path -eq $Miner.Path -and 
            $_.Arguments -eq $Miner.Arguments -and 
            $_.Wrap -eq $Miner.Wrap -and 
            $_.API -eq $Miner.API -and 
            $_.Port -eq $Miner.Port -and 
            $_.CName -eq $Miner.CName -and 
            (Compare-Object $_.Algorithm ($Miner.HashRates | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) | Measure-Object).Count -eq 0
        }
        if ($ActiveMiner) {
            $ActiveMiner.Type = $Miner.Type
            $ActiveMiner.Index = $Miner.Index
            $ActiveMiner.Profit = $Miner.Profit
            $ActiveMiner.Profit_Comparison = $Miner.Profit_Comparison
            $ActiveMiner.Profit_MarginOfError = $Miner.Profit_MarginOfError
            $ActiveMiner.Profit_Bias = $Miner.Profit_Bias
            $ActiveMiner.Profit_Unbias = $Miner.Profit_Unbias
            $ActiveMiner.Speed = $Miner.HashRates.PSObject.Properties.Value #temp fix, must use 'PSObject.Properties' to preserve order
        }
        else {
            $ActiveMiners += New-Object $Miner.API -Property @{
                Name                 = $Miner.Name
                Path                 = $Miner.Path
                Arguments            = $Miner.Arguments
                Wrap                 = $Miner.Wrap
                API                  = $Miner.API
                Port                 = $Miner.Port
                Algorithm            = $Miner.HashRates.PSObject.Properties.Name #temp fix, must use 'PSObject.Properties' to preserve order
                Type                 = $Miner.Type
                Index                = $Miner.Index
                Profit               = $Miner.Profit
                Profit_Comparison    = $Miner.Profit_Comparison
                Profit_MarginOfError = $Miner.Profit_MarginOfError
                Profit_Bias          = $Miner.Profit_Bias
                Profit_Unbias        = $Miner.Profit_Unbias
                Speed                = $Miner.HashRates.PSObject.Properties.Value #temp fix, must use 'PSObject.Properties' to preserve order
                Speed_Live           = 0
                Best                 = $false
                Best_Comparison      = $false
                Process              = $null
                New                  = $false
                Active               = [TimeSpan]0
                Activated            = 0
                Status               = ""
                Benchmarked          = 0
                CName                = $Miner.CName
                Pool                 = $Miner.Pools.PSObject.Properties.Value.Name
                ExtendInterval       = $Miner.ExtendInterval
            }
        }
    }

    #Don't penalize active miners
    $ActiveMiners | Where-Object Status -EQ "Running" | ForEach-Object {$_.Profit_Bias = $_.Profit_Unbias}

    #Get most profitable miner combination i.e. AMD+NVIDIA+CPU
    $BestMiners = $ActiveMiners | Select-Object Type, Index -Unique | ForEach-Object {$Miner_GPU = $_; ($ActiveMiners | Where-Object {(Compare-Object $Miner_GPU.Type $_.Type | Measure-Object).Count -eq 0 -and (Compare-Object $Miner_GPU.Index $_.Index | Measure-Object).Count -eq 0} | Sort-Object -Descending {($_ | Where-Object Profit -EQ $null | Measure-Object).Count}, {($_ | Measure-Object Profit_Bias -Sum).Sum}, {($_ | Where-Object Profit -NE 0 | Measure-Object).Count}, {$_.Benchmarked}, {$_.ExtendInterval} | Select-Object -First 1)}
    $BestMiners_Comparison = $ActiveMiners | Select-Object Type, Index -Unique | ForEach-Object {$Miner_GPU = $_; ($ActiveMiners | Where-Object {(Compare-Object $Miner_GPU.Type $_.Type | Measure-Object).Count -eq 0 -and (Compare-Object $Miner_GPU.Index $_.Index | Measure-Object).Count -eq 0} | Sort-Object -Descending {($_ | Where-Object Profit -EQ $null | Measure-Object).Count}, {($_ | Measure-Object Profit_Comparison -Sum).Sum}, {($_ | Where-Object Profit -NE 0 | Measure-Object).Count}, {$_.Benchmarked}, {$_.ExtendInterval} | Select-Object -First 1)}
    $Miners_Type_Combos = @([PSCustomObject]@{Combination = @()}) + (Get-Combination ($ActiveMiners | Select-Object Type -Unique) | Where-Object {(Compare-Object ($_.Combination | Select-Object -ExpandProperty Type -Unique) ($_.Combination | Select-Object -ExpandProperty Type) | Measure-Object).Count -eq 0})
    $Miners_Index_Combos = @([PSCustomObject]@{Combination = @()}) + (Get-Combination ($ActiveMiners | Select-Object Index -Unique) | Where-Object {(Compare-Object ($_.Combination | Select-Object -ExpandProperty Index -Unique) ($_.Combination | Select-Object -ExpandProperty Index) | Measure-Object).Count -eq 0})
    $BestMiners_Combos = $Miners_Type_Combos | ForEach-Object {
        $Miner_Type_Combo = $_.Combination
        $Miners_Index_Combos | ForEach-Object {
            $Miner_Index_Combo = $_.Combination
            [PSCustomObject]@{
                Combination = $Miner_Type_Combo | ForEach-Object {
                    $Miner_Type_Count = $_.Type.Count
                    [Regex]$Miner_Type_Regex = "^(" + (($_.Type | ForEach-Object {[Regex]::Escape($_)}) -join "|") + ")$"
                    $Miner_Index_Combo | ForEach-Object {
                        $Miner_Index_Count = $_.Index.Count
                        [Regex]$Miner_Index_Regex = "^(" + (($_.Index | ForEach-Object {[Regex]::Escape($_)}) -join "|") + ")$"
                        $BestMiners | Where-Object {([Array]$_.Type -notmatch $Miner_Type_Regex).Count -eq 0 -and ([Array]$_.Index -notmatch $Miner_Index_Regex).Count -eq 0 -and ([Array]$_.Type -match $Miner_Type_Regex).Count -eq $Miner_Type_Count -and ([Array]$_.Index -match $Miner_Index_Regex).Count -eq $Miner_Index_Count}
                    }
                }
            }
        }
    }
    $BestMiners_Combos_Comparison = $Miners_Type_Combos | ForEach-Object {
        $Miner_Type_Combo = $_.Combination
        $Miners_Index_Combos | ForEach-Object {
            $Miner_Index_Combo = $_.Combination
            [PSCustomObject]@{
                Combination = $Miner_Type_Combo | ForEach-Object {
                    $Miner_Type_Count = $_.Type.Count
                    [Regex]$Miner_Type_Regex = "^(" + (($_.Type | ForEach-Object {[Regex]::Escape($_)}) -join "|") + ")$"
                    $Miner_Index_Combo | ForEach-Object {
                        $Miner_Index_Count = $_.Index.Count
                        [Regex]$Miner_Index_Regex = "^(" + (($_.Index | ForEach-Object {[Regex]::Escape($_)}) -join "|") + ")$"
                        $BestMiners_Comparison | Where-Object {([Array]$_.Type -notmatch $Miner_Type_Regex).Count -eq 0 -and ([Array]$_.Index -notmatch $Miner_Index_Regex).Count -eq 0 -and ([Array]$_.Type -match $Miner_Type_Regex).Count -eq $Miner_Type_Count -and ([Array]$_.Index -match $Miner_Index_Regex).Count -eq $Miner_Index_Count}
                    }
                }
            }
        }
    }
    $BestMiners_Combo = $BestMiners_Combos | Sort-Object -Descending {($_.Combination | Where-Object Profit -EQ $null | Measure-Object).Count}, {($_.Combination | Measure-Object Profit_Bias -Sum).Sum}, {($_.Combination | Where-Object Profit -NE 0 | Measure-Object).Count} | Select-Object -First 1 | Select-Object -ExpandProperty Combination
    $BestMiners_Combo_Comparison = $BestMiners_Combos_Comparison | Sort-Object -Descending {($_.Combination | Where-Object Profit -EQ $null | Measure-Object).Count}, {($_.Combination | Measure-Object Profit_Comparison -Sum).Sum}, {($_.Combination | Where-Object Profit -NE 0 | Measure-Object).Count} | Select-Object -First 1 | Select-Object -ExpandProperty Combination
    $BestMiners_Combo | ForEach-Object {$_.Best = $true}
    $BestMiners_Combo_Comparison | ForEach-Object {$_.Best_Comparison = $true}

    #Stop or start miners in the active list depending on if they are the most profitable
    $ActiveMiners | Where-Object {$_.GetActivateCount() -GT 0} | Where-Object Best -EQ $false | ForEach-Object {
        $Miner = $_

        if ($Miner.Process -eq $null -or $Miner.Process.HasExited) {
            if ($Miner.Status -eq "Running") {
                $Miner.Status = "Failed"
                if ($Miner.Process -eq $null) {
                    Write-Log -Level Warn "$($Miner.Type) miner $($Miner.Name) failed - process handle is missing"
                }
                if ($Miner.Process.HasExited) {
                    Write-Log -Level Warn "$($Miner.Type) miner $($Miner.Name) failed - process exited on it's own"
                }
            }
        }
        else {
            Write-Log "Closing $($Miner.Type) miner $($Miner.Name) [PID $($_.Process.Id)] because it is no longer the most profitable"
            $Miner.StopMining()
			
            #Revert custom miner variable
            $MinerProfile = ".\OC\Stop_"+$_.Name+".bat"
            if (Test-Path $MinerProfile) {
				Write-Host -F Yellow "Launching :" $MinerProfile
				Write-Log "Launching $($_.Name) : $MinerProfile"
				Start-Process -Wait $MinerProfile -WorkingDirectory ".\OC"
				Sleep 1
            }
        }
    }
    if ($ActiveMiners | ForEach-Object {$_.GetProcessNames()}) {Get-Process -Name @($ActiveMiners | ForEach-Object {$_.GetProcessNames()}) -ErrorAction Ignore | Select-Object -ExpandProperty ProcessName | Compare-Object @($ActiveMiners | Where-Object Best -EQ $true | Where-Object {$_.Status -EQ "Running"} | ForEach-Object {$_.GetProcessNames()}) | Where-Object SideIndicator -EQ "=>" | Select-Object -ExpandProperty InputObject | Select-Object -Unique | ForEach-Object {Stop-Process -Name $_ -Force -ErrorAction Ignore}}
    Start-Sleep $Config.Delay #Wait to prevent BSOD
    $ActiveMiners | Where-Object Best -EQ $true | ForEach-Object {
        if ($_.Process -eq $null -or $_.Process.HasExited -ne $false) {
			
			#Launch custom miner variable
			$MinerProfile = ".\OC\Start_"+$_.Name+".bat"
			if (Test-Path $MinerProfile) {
				Write-Host -F Yellow "Launching :" $MinerProfile
				Write-Log "Launching $($_.Name) : $MinerProfile"
				Start-Process -Wait $MinerProfile -WorkingDirectory ".\OC"
				Sleep 1
			}
			
			# Launch OC if exists
			if ($_.Type -ne "cpu"){
			$OCName = ".\OC\"+$_.Algorithm+"_"+$_.Type+".bat"
			$DefaultOCName = ".\OC\default_"+$_.Type+".bat"
			$Pill = ".\OC\Start_Pill.bat"
				if (Test-Path $Pill) {
					if ($_.Type -eq "nvidia" -and ($_.Algorithm -match "ethash.*" -or $_.Algorithm -match "cryptonight.*")) {
						Write-Host -F Yellow "Dosing with" $Pill
						Write-Log "Dosing with $Pill"
						Start-Process –WindowStyle Hidden $Pill -WorkingDirectory ".\OC"
						Sleep 1
					}
				}
				if (Test-Path $OCName) {
					Write-Host -F Yellow "Launching :" $OCName
					Write-Log "Launching $($_.Algorithm) $($_.Type) : $OCName"
					Start-Process -Wait $OCName -WorkingDirectory ".\OC"
					Sleep 1
				}
				else {
					if (Test-Path $DefaultOCName) {
						Write-Host -F Yellow "Launching :" $DefaultOCName
						Write-Log "Launching $($_.Algorithm) $($_.Type) : $DefaultOCName"
						Start-Process -Wait $DefaultOCName -WorkingDirectory  ".\OC"
						Sleep 1
					}
				}
		    }
	
            Write-Log "Starting $($_.Type) miner $($_.Name): '$($_.Path) $($_.Arguments)'"
            $DecayStart = $Timer
            $_.StartMining()
        }
    }

    #Get miners needing benchmarking
    $MinersNeedingBenchmark = @($Miners | Where-Object {$_.HashRates.PSObject.Properties.Value -contains $null})
	
    $Miners | Where-Object {$_.Profit -ge 1E-5 -or $_.Profit -eq $null} | Sort-Object -Property Type, @{Expression = {if ($MinersNeedingBenchmark.count -gt 0) {$_.HashRates.PSObject.Properties.Name}}}, @{Expression = {if ($MinersNeedingBenchmark.count -gt 0) {$_.Profit}}; Descending = $true}, @{Expression = {if ($MinersNeedingBenchmark.count -lt 1) {[double]$_.Profit_Bias}}; Descending = $true} | Format-Table -GroupBy Type (
        @{Label = "Miner [Fee]"; Expression = {"$($_.Name) [$(($_.MinerFee | Foreach-Object {$_.ToString("N2")}) -join '%/')%]"}},
        @{Label = "Algorithm"; Expression = {$_.HashRates.PSObject.Properties.Name}}, 
        @{Label = "Speed"; Expression = {$_.HashRates.PSObject.Properties.Value | ForEach-Object {if ($_ -ne $null) {"$($_ | ConvertTo-Hash)/s"}else {"Benchmarking"}}}; Align = 'right'}, 
        @{Label = "$($Config.Currency | Select-Object -Index 0)/Day"; Expression = {if ($_.Profit) {ConvertTo-LocalCurrency $($_.Profit) $($Rates.$($Config.Currency | Select-Object -Index 0)) -Offset 2} else {"Unknown"}}; Align = "right"},
        @{Label = "Accuracy"; Expression = {$_.Pools.PSObject.Properties.Value.MarginOfError | ForEach-Object {(1 - $_).ToString("P0")}}; Align = 'right'},
        @{Label = "BTC/H/Day"; Expression = {$_.Pools.PSObject.Properties.Value.Price | Select-Object -Index 0 | ConvertTo-Price}; Align = 'right'},
        @{Label = "Pool [Fee] [Variance]"; Expression = {$_.Pools.PSObject.Properties.Value | ForEach-Object {if ($_.CoinName) {"$($_.Name)-$($_.CoinName) [$('{0:N2}' -f $_.PoolFee)%] [$('{0:N2}' -f $_.Variance)]"}else {"$($_.Name) [$('{0:N2}' -f $_.PoolFee)%] [$('{0:N2}' -f $_.Variance)]"}}}}
    ) | Out-Host

    Write-Host "--------------------------------------------------------------------------------"
    Write-Host " This is a free project feel free to donate be much appreciated:"
    Write-Host " Thank you aaronsace for MultiPoolMiner"
    Write-Host " Default donation 24 minutes per 24 hour" -foregroundcolor "Yellow"
    Write-Host " Current donation = $($Config.Donate) mins" -foregroundcolor "Red"
    Write-Host " Close this immediately if you do not agree" -foregroundcolor "Red"
    Write-Host " Thank you for choosing SephMiner"
    Write-Host "--------------------------------------------------------------------------------"
    
    #Display benchmarking progres
    if ($MinersNeedingBenchmark.count -gt 0) {
        Write-Log -Level Warn "Benchmarking in progress: $($MinersNeedingBenchmark.count) miner$(if ($MinersNeedingBenchmark.count -gt 1){'s'}) left to benchmark."
    }
	
    #Display idle miners list
	$idleminers = $ActiveMiners | Where-Object {{$_.GetActivateCount() -GT 0} -and $_.Status -EQ "Idle"}
	if ($idleminers.count){Write-Host " Status : Idle "}
    $idleminers | Sort-Object -Descending Status, {if ($_.Process -eq $null) {[DateTime]0}else {$_.Process.StartTime}} | Select-Object -First (6) | Format-Table (
        @{Label = "Active"; Expression = {"{0:dd} Days {0:hh} Hours {0:mm} Minutes" -f $(if ($_.Process -eq $null) {$_.Active}else {if ($_.Process.ExitTime -gt $_.Process.StartTime) {($_.Active + ($_.Process.ExitTime - $_.Process.StartTime))}else {($_.Active + ((Get-Date) - $_.Process.StartTime))}})}}, 
        @{Label = "Launched"; Expression = {Switch ($_.GetActivateCount()) {0 {"Never"} 1 {"Once"} Default {"$_ Times"}}}}, 
        @{Label = "Type"; Expression = {$_.Type}},
        @{Label = "Miner"; Expression = {$_.Name}}, 
        @{Label = "Algorithm"; Expression = {$_.Algorithm}},
        @{Label = "Command"; Expression = {"$($_.Path.TrimStart((Convert-Path ".\"))) $($_.Arguments)"}}
    ) | Out-Host
	
    #Display failed miners list
	$failedminers = $ActiveMiners | Where-Object {{$_.GetActivateCount() -GT 0} -and $_.Status -EQ "Failed"}
	if ($failedminers.count){Write-Host " Status : Failed $($failedminers.Count)" -foregroundcolor "Red"}
    $failedminers | Sort-Object -Descending Status, {if ($_.Process -eq $null) {[DateTime]0}else {$_.Process.StartTime}} | Format-Table -Wrap ( 
        @{Label = "Active"; Expression = {"{0:dd} Days {0:hh} Hours {0:mm} Minutes" -f $(if ($_.Process -eq $null) {$_.Active}else {if ($_.Process.ExitTime -gt $_.Process.StartTime) {($_.Active + ($_.Process.ExitTime - $_.Process.StartTime))}else {($_.Active + ((Get-Date) - $_.Process.StartTime))}})}}, 
        @{Label = "Launched"; Expression = {Switch ($_.GetActivateCount()) {0 {"Never"} 1 {"Once"} Default {"$_ Times"}}}}, 
        @{Label = "Type"; Expression = {$_.Type}},
        @{Label = "Miner"; Expression = {$_.Name}},
        @{Label = "Algorithm"; Expression = {$_.Algorithm}},
        @{Label = "Command"; Expression = {"$($_.Path.TrimStart((Convert-Path ".\"))) $($_.Arguments)"}}
    ) | Out-Host

    #Display profit comparison
    if ($Downloader.State -eq "Running") {$Downloader | Wait-Job -Timeout 10 | Out-Null}
    if (($BestMiners_Combo | Where-Object Profit -EQ $null | Measure-Object).Count -eq 0 -and $Downloader.State -ne "Running") {
        $MinerComparisons = 
        [PSCustomObject]@{"Miner" = "SephMiner"}, 
        [PSCustomObject]@{"Miner" = $BestMiners_Combo_Comparison | ForEach-Object {"$($_.Name)-$($_.Algorithm -join '/')"}}

        $BestMiners_Combo_Stat = Set-Stat -Name "Profit" -Value ($BestMiners_Combo | Measure-Object Profit -Sum).Sum -Duration $StatSpan

        $MinerComparisons_Profit = $BestMiners_Combo_Stat.Week, ($BestMiners_Combo_Comparison | Measure-Object Profit_Comparison -Sum).Sum

        $MinerComparisons_MarginOfError = $BestMiners_Combo_Stat.Week_Fluctuation, ($BestMiners_Combo_Comparison | ForEach-Object {$_.Profit_MarginOfError * (& {if ($MinerComparisons_Profit[1]) {$_.Profit_Comparison / $MinerComparisons_Profit[1]}else {1}})} | Measure-Object -Sum).Sum

        $Config.Currency | ForEach-Object {
            $MinerComparisons[0] | Add-Member $_.ToUpper() ("{0:N5} $([Char]0x00B1){1:P0} ({2:N5}-{3:N5})" -f ($MinerComparisons_Profit[0] * $Rates.$_), $MinerComparisons_MarginOfError[0], (($MinerComparisons_Profit[0] * $Rates.$_) / (1 + $MinerComparisons_MarginOfError[0])), (($MinerComparisons_Profit[0] * $Rates.$_) * (1 + $MinerComparisons_MarginOfError[0])))
            $MinerComparisons[1] | Add-Member $_.ToUpper() ("{0:N5} $([Char]0x00B1){1:P0} ({2:N5}-{3:N5})" -f ($MinerComparisons_Profit[1] * $Rates.$_), $MinerComparisons_MarginOfError[1], (($MinerComparisons_Profit[1] * $Rates.$_) / (1 + $MinerComparisons_MarginOfError[1])), (($MinerComparisons_Profit[1] * $Rates.$_) * (1 + $MinerComparisons_MarginOfError[1])))
        }

        if ([Math]::Round(($MinerComparisons_Profit[0] - $MinerComparisons_Profit[1]) / $MinerComparisons_Profit[1], 2) -gt 0) {
            $MinerComparisons_Range = ($MinerComparisons_MarginOfError | Measure-Object -Average | Select-Object -ExpandProperty Average), (($MinerComparisons_Profit[0] - $MinerComparisons_Profit[1]) / $MinerComparisons_Profit[1]) | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
            Write-Host -BackgroundColor Yellow -ForegroundColor Black "SephMiner is between $([Math]::Round((((($MinerComparisons_Profit[0]-$MinerComparisons_Profit[1])/$MinerComparisons_Profit[1])-$MinerComparisons_Range)*100)))% and $([Math]::Round((((($MinerComparisons_Profit[0]-$MinerComparisons_Profit[1])/$MinerComparisons_Profit[1])+$MinerComparisons_Range)*100)))% more profitable than the fastest miner: "
        }

        $MinerComparisons | Out-Host
    }

    #Display pool balances, formatting it to show all the user specified currencies
    if ($Config.ShowPoolBalances) {
        Write-Host "Pool Balances: "
        $Columns = @()
        $ColumnFormat = [Array]@{Name = "Name"; Expression = "Name"}
        if ($Config.ShowPoolBalancesDetails) {
            $Columns += $BalancesData.Balances | Foreach-Object {$_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name} | Where-Object {$_ -like "Balance (*"} | Sort-Object -Unique
        }
        else {
            $ColumnFormat += @{Name = "Balance"; Expression = {$_.Total}}
        }
        $Columns += $BalancesData.Balances | Foreach-Object {$_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name} | Where-Object {$_ -like "Value in *"} | Sort-Object -Unique
        $ColumnFormat += $Columns | Foreach-Object {@{Name = "$_"; Expression = "$_"; Align = "right"}}
        $BalancesData.Balances | Format-Table -Wrap -Property $ColumnFormat
    }

    #Display exchange rates, get decimal places from $NewRates
    if (($Config.ShowPoolBalances) -and $Config.ShowPoolBalancesDetails -and $BalancesData.Rates) {
        Write-Host "Exchange rates:"
        $BalancesData.Rates.PSObject.Properties.Name | ForEach-Object {
            $BalanceCurrency = $_
            Write-Host "1 $BalanceCurrency = $(($BalancesData.Rates.$_.PSObject.Properties.Name| Where-Object {$_ -ne $BalanceCurrency} | Sort-Object | ForEach-Object {$Digits = ($($NewRates.$_).ToString().Split(".")[1]).length; "$_ " + ("{0:N$($Digits)}" -f [Float]$BalancesData.Rates.$BalanceCurrency.$_)}) -join " = ")"
        }
    }
    else {
        if ($Config.Currency | Where-Object {$_ -ne "BTC" -and $NewRates.$_}) {Write-Host "Exchange rates: 1 BTC = $(($Config.Currency | Where-Object {$_ -ne "BTC" -and $NewRates.$_} | ForEach-Object {$Digits = ($($NewRates.$_).ToString().Split(".")[1]).length; "$_ " + ("{0:N$($Digits)}" -f [Float]$NewRates.$_)}) -join " = ")"}
    }
	
	$RunningMiners = $ActiveMiners | Where-Object Status -EQ "Running"
	
    #Display active miners list
	Write-Host " Status : Running " -foregroundcolor "Yellow"
    $RunningMiners | Where-Object {$_.GetActivateCount() -GT 0} | Sort-Object -Descending Status, {if ($_.Process -eq $null) {[DateTime]0}else {$_.Process.StartTime}} | Format-Table -Wrap (
        @{Label = "Active"; Expression = {"{0:dd} Days {0:hh} Hours {0:mm} Minutes" -f $(if ($_.Process -eq $null) {$_.Active}else {if ($_.Process.ExitTime -gt $_.Process.StartTime) {($_.Active + ($_.Process.ExitTime - $_.Process.StartTime))}else {($_.Active + ((Get-Date) - $_.Process.StartTime))}})}}, 
        @{Label = "Launched"; Expression = {Switch ($_.GetActivateCount()) {0 {"Never"} 1 {"Once"} Default {"$_ Times"}}}}, 
        @{Label = "Command"; Expression = {"$($_.Path.TrimStart((Convert-Path ".\"))) $($_.Arguments)"}}
    ) | Out-Host
	
    #Reduce Memory
    Get-Job -State Completed | Remove-Job
    [GC]::Collect()

    #Benchmarking miners/algorithm with ExtendInterval
    $Multiplier = 0
    $RunningMiners | Where-Object {$_.Speed -eq $null} | ForEach-Object {
        if ($_.ExtendInterval -ge $Multiplier) {$Multiplier = $_.ExtendInterval}
    }
    
    #Multiply $Config.Interval and add it to $StatEnd, extend StatSpan
    if ($Multiplier -gt 0) {
        if ($Multiplier -gt 10) {$Multiplier = 10}
        $StatEnd = $StatEnd.AddSeconds($Config.Interval * $Multiplier)
        $StatSpan = New-TimeSpan $StatStart $StatEnd
        Write-Log "Benchmarking algorithm or miner that need increase interval time temporarily to $($Multiplier)x interval ($($Config.Interval * $($Multiplier)) seconds). "
    }

    #Do nothing for a few seconds as to not overload the APIs and display miner download status
    Write-Log "Start waiting before next run. "
    for ($i = $Strikes; $i -gt 0 -or $Timer -lt $StatEnd; $i--) {
        Start-Sleep 10
        $Timer = (Get-Date).ToUniversalTime()
    }
    Write-Log "Finish waiting before next run. "

    #Save current hash rates
    Write-Log "Saving hash rates. "
    $ActiveMiners | ForEach-Object {
        $Miner = $_
        $Miner.Speed_Live = [Double[]]@()

        if ($Miner.New) {$Miner.New = [Boolean]($Miner.Algorithm | Where-Object {-not (Get-Stat -Name "$($Miner.Name)_$($_)_HashRate")})}

        if ($Miner.New) {$Miner.Benchmarked++}
		
        $Miner_Data = [PSCustomObject]@{}
        $Miner_Data = $Miner.GetMinerData($Miner.Algorithm, ($Miner.New -and $Miner.Benchmarked -lt $Strikes))

        if ($Miner.Process -and -not $Miner.Process.HasExited) {
            $Miner.Speed_Live = $Miner_Data.HashRate.PSObject.Properties.Value

            $Miner.Algorithm | Where-Object {$Miner_Data.HashRate.$_} | ForEach-Object {
                $Stat = Set-Stat -Name "$($Miner.Name)_$($_)_HashRate" -Value $Miner_Data.HashRate.$_ -Duration $StatSpan -FaultDetection $true
                $Miner.New = $false
            }
        }

        #Benchmark timeout
        if ($Miner.Benchmarked -ge ($Strikes * $Strikes) -or ($Miner.Benchmarked -ge $Strikes -and $Miner.GetActivateCount() -ge $Strikes)) {
            $Miner.Algorithm | Where-Object {-not $Miner_HashRate.$_} | ForEach-Object {
                if ((Get-Stat -Name "$($Miner.Name)_$($_)_HashRate") -eq $null) {
                    $Stat = Set-Stat -Name "$($Miner.Name)_$($_)_HashRate" -Value 0 -Duration $StatSpan
                }
            }
        }
    }
    Write-Log "Starting next run. "
}

#Stop the log
Stop-Transcript
