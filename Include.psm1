Set-Location (Split-Path $MyInvocation.MyCommand.Path)

Add-Type -Path .\OpenCL\*.cs

function Get-Balance {
     [CmdletBinding()]
     param($Config, $NewRates)
 
     $Data = [PSCustomObject]@{}
     
     $Balances = @(Get-ChildItem "Balances" -File | Where-Object {$Config.Pools.$($_.BaseName) -and ($Config.ExcludePoolName -inotcontains $_.BaseName -or $Config.ShowPoolBalancesExcludedPools)} | ForEach-Object {
         Get-ChildItemContent "Balances\$($_.Name)" -Parameters @{Config = $Config}
     } | Foreach-Object {$_.Content | Add-Member Name $_.Name -PassThru -Force} | Sort-Object Name)
 
     #Get exchgange rates for all payout currencies
     $CurrenciesWithBalances = @($Balances.currency | Sort-Object -Unique)
     try {
         $Rates = Invoke-RestMethod "https://min-api.cryptocompare.com/data/pricemulti?fsyms=$($CurrenciesWithBalances -join ",")&tsyms=$($Config.Currency -join ",")&extraParams=http://multipoolminer.io" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
     }
     catch {
         Write-Log -Level Warn "Pool API (CryptoCompare) has failed - cannot convert balances to other currencies. "
         Return $Balances
     }
 
     #Add total of totals
     $Totals = [PSCustomObject]@{
         Name  = "*Total*"
    }
    #Add Balance (in currency)
    $Rates.PSObject.Properties.Name | ForEach-Object {
        $Currency = $_
        $Currency = $_.ToUpper()
        $Balances | Foreach-Object {
            if ($NewRates.$Currency -ne $null) {$Digits = ($($NewRates.$Currency).ToString().Split(".")[1]).length}else {$Digits = 8}
            $_.Total = ("{0:N$($Digits)}" -f ([Float]$($_.Total)))
             if ($Currency -eq $_.Currency) {
                 $_ | Add-Member "Balance ($Currency)" $_.Total
             }
         }
         if (($Balances."Balance ($Currency)" | Measure-Object -Sum).sum) {$Totals | Add-Member "Balance ($Currency)" ("{0:N$($Digits)}" -f ([Float]$($Balances."Balance ($Currency)" | Measure-Object -Sum).sum))}
     }
    #Add converted values
    $Config.Currency | ForEach-Object {
        $Currency = $_
        $Currency = $_.ToUpper()
        #Get number of digits from $NewRates
        if ($NewRates.$Currency -ne $null) {$Digits = ($($NewRates.$Currency).ToString().Split(".")[1]).length}else {$Digits = 8}
        $Balances | Foreach-Object {
             $_ | Add-Member "Value in $Currency" $(if ($Rates.$($_.Currency).$Currency) {("{0:N$($Digits)}" -f ([Float]$_.Total * [Float]$Rates.$($_.Currency).$Currency))}else {"unknown"}) -Force
         }
         if (($Balances."Value in $Currency" | Measure-Object -Sum -ErrorAction Ignore).sum)  {$Totals | Add-Member "Value in $Currency" ("{0:N$($Digits)}" -f ([Float]$($Balances."Value in $Currency" | Measure-Object -Sum -ErrorAction Ignore).sum)) -Force}
     }
     $Balances += $Totals
     
     $Data | Add-Member Balances $Balances
     $Data | Add-Member Rates $Rates
 
     Return $Data
}

function Get-Devices {
    [CmdletBinding()]

    # returns a list of all OpenGL devices found.

    $Devices = [PSCustomObject]@{}

    [OpenCl.Platform]::GetPlatformIDs() | ForEach-Object { # Hardware platform
        [OpenCl.Device]::GetDeviceIDs($_, [OpenCl.DeviceType]::All) | ForEach-Object { # Device

            if ($_.Type -eq "Cpu") {
                $Type = "CPU"
            }
            else {
                Switch ($_.Vendor) {
                    "Advanced Micro Devices, Inc." {$Type = "AMD"}
                    "Intel(R) Corporation"         {$Type = "INTEL"}
                    "NVIDIA Corporation"           {$Type = "NVIDIA"}
                }
            }

            if (-not $Devices.$Type) {
                $Devices | Add-Member $Type @()
                $DeviceID = 0 # For each platform start counting DeviceIDs from 0
            }

            $Name_Norm = (Get-Culture).TextInfo.ToTitleCase(($_.Name)) -replace "[^A-Z0-9]"

            if ($Devices.$Type.Name_Norm -inotcontains $Name_Norm) {
                # New card model
                $Device = $_
                $Device | Add-Member Name_Norm $Name_Norm
                $Device | Add-Member DeviceIDs @()
                $Devices.$Type += $Device
            }
            $Devices.$Type | Where-Object {$_.Name_Norm -eq $Name_Norm} | ForEach-Object {$_.DeviceIDs += $DeviceID++} # Add DeviceID
        }
    }
    $Devices
}

function Get-DeviceIDs {
    # Filters the DeviceIDs and returns only DeviceIDs for active miners
    # $DeviceIdBase: Returened  DeviceID numbers are of base $DeviceIdBase, e.g. HEX (16)
    # $DeviceIdOffset: Change default numbering start from 0 -> $DeviceIdOffset

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Devices,
        [Parameter(Mandatory = $true)]
        [String]$Type,
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [PSCustomObject]$DeviceTypeModel,
        [Parameter(Mandatory = $true)]
        [Int]$DeviceIdBase,
        [Parameter(Mandatory = $true)]
        [Int]$DeviceIdOffset
    )

    $DeviceIDs = [PSCustomObject]@{}
    $DeviceIDs | Add-Member "All" @() # array of all devices, ids will be in hex format
    $DeviceIDs | Add-Member "2gb" @() # array of all devices with more than 2MiB VRAM, ids will be in hex format
    $DeviceIDs | Add-Member "3gb" @() # array of all devices with more than 3MiB VRAM, ids will be in hex format
    $DeviceIDs | Add-Member "4gb" @() # array of all devices with more than 4MiB VRAM, ids will be in hex format
	$DeviceIDs | Add-Member "1050ti" @() # array of all 1050ti
    $DeviceIDs | Add-Member "10603gb" @() # array of all 1060
    $DeviceIDs | Add-Member "10606gb" @() # array of all 1060
    $DeviceIDs | Add-Member "1070" @() # array of all 1070
    $DeviceIDs | Add-Member "1070ti" @() # array of all 1070ti
    $DeviceIDs | Add-Member "1080" @() # array of all 1080
    $DeviceIDs | Add-Member "1080ti" @() # array of all 1080ti

    # Get DeviceIDs, filter out all disabled hw models and IDs
    if ($Config.MinerInstancePerCardModel) {
        # separate miner instance per hardware model
        if ($Config.Devices.$Type.IgnoreHWModel -inotcontains $DeviceTypeModel.Name_Norm -and $Config.Miners.$Name.IgnoreHWModel -inotcontains $DeviceTypeModel.Name_Norm) {
            $DeviceTypeModel.DeviceIDs | Where-Object {$Config.Devices.$Type.IgnoreDeviceID -notcontains $_ -and $Config.Miners.$Name.IgnoreDeviceID -notcontains $_} | ForEach-Object {
                $DeviceIDs."All" += [Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)
                if ($DeviceTypeModel.GlobalMemsize -ge 2000000000) {$DeviceIDs."2gb" += [Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
                if ($DeviceTypeModel.GlobalMemsize -ge 3000000000) {$DeviceIDs."3gb" += [Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
                if ($DeviceTypeModel.GlobalMemsize -ge 4000000000) {$DeviceIDs."4gb" += [Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
                if ($DeviceTypeModel.Name -match ".*1050 ti") {$DeviceIDs."1050ti" += [Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
                if ($DeviceTypeModel.Name -match ".*1060 3gb") {$DeviceIDs."10603gb" += [Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
                if ($DeviceTypeModel.Name -match ".*1060 6gb") {$DeviceIDs."10606gb" += [Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
                if ($DeviceTypeModel.Name -match ".*1070") {$DeviceIDs."1070" += [Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
                if ($DeviceTypeModel.Name -match ".*1070 ti") {$DeviceIDs."1070ti" += [Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
                if ($DeviceTypeModel.Name -match ".*1080") {$DeviceIDs."1080" += [Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
                if ($DeviceTypeModel.Name -match ".*1080 ti") {$DeviceIDs."1080ti" += [Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
            }
        }
    }
    else {
        # one miner instance per hw type
        $DeviceIDs."All" = @($Devices.$Type | Where-Object {$Config.Devices.$Type.IgnoreHWModel -inotcontains $_.Name_Norm -and $Config.Miners.$Name.IgnoreHWModel -inotcontains $_.Name_Norm}).DeviceIDs | Where-Object {$Config.Devices.$Type.IgnoreDeviceID -notcontains $_ -and $Config.Miners.$Name.IgnoreDeviceID -notcontains $_} | ForEach-Object {[Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
        $DeviceIDs."2gb" = @($Devices.$Type | Where-Object {$Config.Devices.$Type.IgnoreHWModel -inotcontains $_.Name_Norm -and $Config.Miners.$Name.IgnoreHWModel -inotcontains $_.Name_Norm} | Where-Object {$_.GlobalMemsize -gt 2000000000}).DeviceIDs | Where-Object {$Config.Devices.$Type.IgnoreDeviceID -notcontains $_ -and $Config.Miners.$Name.IgnoreDeviceID -notcontains $_} | ForEach-Object {[Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
        $DeviceIDs."3gb" = @($Devices.$Type | Where-Object {$Config.Devices.$Type.IgnoreHWModel -inotcontains $_.Name_Norm -and $Config.Miners.$Name.IgnoreHWModel -inotcontains $_.Name_Norm} | Where-Object {$_.GlobalMemsize -gt 3000000000}).DeviceIDs | Where-Object {$Config.Devices.$Type.IgnoreDeviceID -notcontains $_ -and $Config.Miners.$Name.IgnoreDeviceID -notcontains $_} | ForEach-Object {[Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
        $DeviceIDs."4gb" = @($Devices.$Type | Where-Object {$Config.Devices.$Type.IgnoreHWModel -inotcontains $_.Name_Norm -and $Config.Miners.$Name.IgnoreHWModel -inotcontains $_.Name_Norm} | Where-Object {$_.GlobalMemsize -gt 4000000000}).DeviceIDs | Where-Object {$Config.Devices.$Type.IgnoreDeviceID -notcontains $_ -and $Config.Miners.$Name.IgnoreDeviceID -notcontains $_} | ForEach-Object {[Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
        $DeviceIDs."1050ti" = @($Devices.$Type | Where-Object {$Config.Devices.$Type.IgnoreHWModel -inotcontains $_.Name_Norm -and $Config.Miners.$Name.IgnoreHWModel -inotcontains $_.Name_Norm} | Where-Object {$_.Name -match ".*1050 ti"}).DeviceIDs | Where-Object {$Config.Devices.$Type.IgnoreDeviceID -notcontains $_ -and $Config.Miners.$Name.IgnoreDeviceID -notcontains $_} | ForEach-Object {[Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
        $DeviceIDs."10603gb" = @($Devices.$Type | Where-Object {$Config.Devices.$Type.IgnoreHWModel -inotcontains $_.Name_Norm -and $Config.Miners.$Name.IgnoreHWModel -inotcontains $_.Name_Norm} | Where-Object {$_.Name -match ".*1060 3gb"}).DeviceIDs | Where-Object {$Config.Devices.$Type.IgnoreDeviceID -notcontains $_ -and $Config.Miners.$Name.IgnoreDeviceID -notcontains $_} | ForEach-Object {[Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
        $DeviceIDs."10606gb" = @($Devices.$Type | Where-Object {$Config.Devices.$Type.IgnoreHWModel -inotcontains $_.Name_Norm -and $Config.Miners.$Name.IgnoreHWModel -inotcontains $_.Name_Norm} | Where-Object {$_.Name -match ".*1060 6gb"}).DeviceIDs | Where-Object {$Config.Devices.$Type.IgnoreDeviceID -notcontains $_ -and $Config.Miners.$Name.IgnoreDeviceID -notcontains $_} | ForEach-Object {[Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
        $DeviceIDs."1070ti" = @($Devices.$Type | Where-Object {$Config.Devices.$Type.IgnoreHWModel -inotcontains $_.Name_Norm -and $Config.Miners.$Name.IgnoreHWModel -inotcontains $_.Name_Norm} | Where-Object {$_.Name -match ".*1070"}).DeviceIDs | Where-Object {$Config.Devices.$Type.IgnoreDeviceID -notcontains $_ -and $Config.Miners.$Name.IgnoreDeviceID -notcontains $_} | ForEach-Object {[Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
        $DeviceIDs."1070" = @($Devices.$Type | Where-Object {$Config.Devices.$Type.IgnoreHWModel -inotcontains $_.Name_Norm -and $Config.Miners.$Name.IgnoreHWModel -inotcontains $_.Name_Norm} | Where-Object {$_.Name -match ".*1070 ti"}).DeviceIDs | Where-Object {$Config.Devices.$Type.IgnoreDeviceID -notcontains $_ -and $Config.Miners.$Name.IgnoreDeviceID -notcontains $_} | ForEach-Object {[Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
        $DeviceIDs."1080" = @($Devices.$Type | Where-Object {$Config.Devices.$Type.IgnoreHWModel -inotcontains $_.Name_Norm -and $Config.Miners.$Name.IgnoreHWModel -inotcontains $_.Name_Norm} | Where-Object {$_.Name -match ".*1080"}).DeviceIDs | Where-Object {$Config.Devices.$Type.IgnoreDeviceID -notcontains $_ -and $Config.Miners.$Name.IgnoreDeviceID -notcontains $_} | ForEach-Object {[Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
        $DeviceIDs."1080ti" = @($Devices.$Type | Where-Object {$Config.Devices.$Type.IgnoreHWModel -inotcontains $_.Name_Norm -and $Config.Miners.$Name.IgnoreHWModel -inotcontains $_.Name_Norm} | Where-Object {$_.Name -match ".*1080 ti"}).DeviceIDs | Where-Object {$Config.Devices.$Type.IgnoreDeviceID -notcontains $_ -and $Config.Miners.$Name.IgnoreDeviceID -notcontains $_} | ForEach-Object {[Convert]::ToString(($_ + $DeviceIdOffset), $DeviceIdBase)}
    }
    $DeviceIDs
}

function Write-Log {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][Alias("LogContent")][string]$Message,
        [Parameter(Mandatory = $false)][ValidateSet("Error", "Warn", "Info", "Verbose", "Debug")][string]$Level = "Info"
    )

    Begin { }
    Process {
        # Inherit the same verbosity settings as the script importing this
        if (-not $PSBoundParameters.ContainsKey('InformationPreference')) { $InformationPreference = $PSCmdlet.GetVariableValue('InformationPreference') }
        if (-not $PSBoundParameters.ContainsKey('Verbose')) { $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference') }
        if (-not $PSBoundParameters.ContainsKey('Debug')) { $DebugPreference = $PSCmdlet.GetVariableValue('DebugPreference') }

        # Get mutex named MPMWriteLog. Mutexes are shared across all threads and processes.
        # This lets us ensure only one thread is trying to write to the file at a time.
        $mutex = New-Object System.Threading.Mutex($false, "MPMWriteLog")

        $filename = ".\Logs\SephMiner_$(Get-Date -Format "yyyy-MM-dd").txt"
        $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        if (-not (Test-Path "Stats")) {New-Item "Stats" -ItemType "directory" | Out-Null}

        switch ($Level) {
            'Error' {
                $LevelText = 'ERROR:'
                Write-Error -Message $Message
            }
            'Warn' {
                $LevelText = 'WARNING:'
                Write-Warning -Message $Message
            }
            'Info' {
                $LevelText = 'INFO:'
                Write-Information -MessageData $Message
            }
            'Verbose' {
                $LevelText = 'VERBOSE:'
                Write-Verbose -Message $Message
            }
            'Debug' {
                $LevelText = 'DEBUG:'
                Write-Debug -Message $Message
            }
        }

        # Attempt to aquire mutex, waiting up to 1 second if necessary.  If aquired, write to the log file and release mutex.  Otherwise, display an error.
        if ($mutex.WaitOne(1000)) {
            "$date $LevelText $Message" | Out-File -FilePath $filename -Append -Encoding utf8
            $mutex.ReleaseMutex()
        }
        else {
            Write-Error -Message "Log file is locked, unable to write message to $FileName."
        }
    }
    End {}
}

function Get-FreeTcpPort {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [Int]$DefaultPort
    )
    if ($DefaultPort){$StartPort = $DefaultPort} else {$StartPort = 4068}
    while (Get-NetTCPConnection -LocalPort $StartPort -EA SilentlyContinue) {$StartPort++}
    $StartPort
}

function Set-Stat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name, 
        [Parameter(Mandatory = $true)]
        [Double]$Value, 
        [Parameter(Mandatory = $false)]
        [DateTime]$Updated = (Get-Date).ToUniversalTime(), 
        [Parameter(Mandatory = $true)]
        [TimeSpan]$Duration, 
        [Parameter(Mandatory = $false)]
        [Bool]$FaultDetection = $false, 
        [Parameter(Mandatory = $false)]
        [Bool]$ChangeDetection = $false
    )

    $Updated = $Updated.ToUniversalTime()

    $Path = "Stats\$Name.txt"
    $SmallestValue = 1E-20

    $Stat = Get-Content $Path -ErrorAction SilentlyContinue
    
    try {
        $Stat = $Stat | ConvertFrom-Json -ErrorAction Stop
        $Stat = [PSCustomObject]@{
            Live = [Double]$Stat.Live
            Minute = [Double]$Stat.Minute
            Minute_Fluctuation = [Double]$Stat.Minute_Fluctuation
            Minute_5 = [Double]$Stat.Minute_5
            Minute_5_Fluctuation = [Double]$Stat.Minute_5_Fluctuation
            Minute_10 = [Double]$Stat.Minute_10
            Minute_10_Fluctuation = [Double]$Stat.Minute_10_Fluctuation
            Hour = [Double]$Stat.Hour
            Hour_Fluctuation = [Double]$Stat.Hour_Fluctuation
            Day = [Double]$Stat.Day
            Day_Fluctuation = [Double]$Stat.Day_Fluctuation
            Week = [Double]$Stat.Week
            Week_Fluctuation = [Double]$Stat.Week_Fluctuation
            Duration = [TimeSpan]$Stat.Duration
            Updated = [DateTime]$Stat.Updated
        }

        $ToleranceMin = $Value
        $ToleranceMax = $Value

        if ($FaultDetection) {
            $ToleranceMin = $Stat.Week * (1 - [Math]::Min([Math]::Max($Stat.Week_Fluctuation * 2, 0.1), 0.9))
            $ToleranceMax = $Stat.Week * (1 + [Math]::Min([Math]::Max($Stat.Week_Fluctuation * 2, 0.1), 0.9))
        }

        if ($ChangeDetection -and [Decimal]$Value -eq [Decimal]$Stat.Live) {$Updated = $Stat.updated}

        if ($Value -lt $ToleranceMin -or $Value -gt $ToleranceMax) {
            Write-Log -Level Warn "Stat file ($Name) was not updated because the value ($([Decimal]$Value)) is outside fault tolerance ($([Int]$ToleranceMin) to $([Int]$ToleranceMax)). "
        }
        else {
            $Span_Minute = [Math]::Min($Duration.TotalMinutes / [Math]::Min($Stat.Duration.TotalMinutes, 1), 1)
            $Span_Minute_5 = [Math]::Min(($Duration.TotalMinutes / 5) / [Math]::Min(($Stat.Duration.TotalMinutes / 5), 1), 1)
            $Span_Minute_10 = [Math]::Min(($Duration.TotalMinutes / 10) / [Math]::Min(($Stat.Duration.TotalMinutes / 10), 1), 1)
            $Span_Hour = [Math]::Min($Duration.TotalHours / [Math]::Min($Stat.Duration.TotalHours, 1), 1)
            $Span_Day = [Math]::Min($Duration.TotalDays / [Math]::Min($Stat.Duration.TotalDays, 1), 1)
            $Span_Week = [Math]::Min(($Duration.TotalDays / 7) / [Math]::Min(($Stat.Duration.TotalDays / 7), 1), 1)

            $Stat = [PSCustomObject]@{
                Live = $Value
                Minute = ((1 - $Span_Minute) * $Stat.Minute) + ($Span_Minute * $Value)
                Minute_Fluctuation = ((1 - $Span_Minute) * $Stat.Minute_Fluctuation) + 
                ($Span_Minute * ([Math]::Abs($Value - $Stat.Minute) / [Math]::Max([Math]::Abs($Stat.Minute), $SmallestValue)))
                Minute_5 = ((1 - $Span_Minute_5) * $Stat.Minute_5) + ($Span_Minute_5 * $Value)
                Minute_5_Fluctuation = ((1 - $Span_Minute_5) * $Stat.Minute_5_Fluctuation) + 
                ($Span_Minute_5 * ([Math]::Abs($Value - $Stat.Minute_5) / [Math]::Max([Math]::Abs($Stat.Minute_5), $SmallestValue)))
                Minute_10 = ((1 - $Span_Minute_10) * $Stat.Minute_10) + ($Span_Minute_10 * $Value)
                Minute_10_Fluctuation = ((1 - $Span_Minute_10) * $Stat.Minute_10_Fluctuation) + 
                ($Span_Minute_10 * ([Math]::Abs($Value - $Stat.Minute_10) / [Math]::Max([Math]::Abs($Stat.Minute_10), $SmallestValue)))
                Hour = ((1 - $Span_Hour) * $Stat.Hour) + ($Span_Hour * $Value)
                Hour_Fluctuation = ((1 - $Span_Hour) * $Stat.Hour_Fluctuation) + 
                ($Span_Hour * ([Math]::Abs($Value - $Stat.Hour) / [Math]::Max([Math]::Abs($Stat.Hour), $SmallestValue)))
                Day = ((1 - $Span_Day) * $Stat.Day) + ($Span_Day * $Value)
                Day_Fluctuation = ((1 - $Span_Day) * $Stat.Day_Fluctuation) + 
                ($Span_Day * ([Math]::Abs($Value - $Stat.Day) / [Math]::Max([Math]::Abs($Stat.Day), $SmallestValue)))
                Week = ((1 - $Span_Week) * $Stat.Week) + ($Span_Week * $Value)
                Week_Fluctuation = ((1 - $Span_Week) * $Stat.Week_Fluctuation) + 
                ($Span_Week * ([Math]::Abs($Value - $Stat.Week) / [Math]::Max([Math]::Abs($Stat.Week), $SmallestValue)))
                Duration = $Stat.Duration + $Duration
                Updated = $Updated
            }
        }
    }
    catch {
        if (Test-Path $Path) {Write-Log -Level Warn "Stat file ($Name) is corrupt and will be reset. "}

        $Stat = [PSCustomObject]@{
            Live = $Value
            Minute = $Value
            Minute_Fluctuation = 0
            Minute_5 = $Value
            Minute_5_Fluctuation = 0
            Minute_10 = $Value
            Minute_10_Fluctuation = 0
            Hour = $Value
            Hour_Fluctuation = 0
            Day = $Value
            Day_Fluctuation = 0
            Week = $Value
            Week_Fluctuation = 0
            Duration = $Duration
            Updated = $Updated
        }
    }

    if (-not (Test-Path "Stats")) {New-Item "Stats" -ItemType "directory" | Out-Null}
    [PSCustomObject]@{
        Live = [Decimal]$Stat.Live
        Minute = [Decimal]$Stat.Minute
        Minute_Fluctuation = [Double]$Stat.Minute_Fluctuation
        Minute_5 = [Decimal]$Stat.Minute_5
        Minute_5_Fluctuation = [Double]$Stat.Minute_5_Fluctuation
        Minute_10 = [Decimal]$Stat.Minute_10
        Minute_10_Fluctuation = [Double]$Stat.Minute_10_Fluctuation
        Hour = [Decimal]$Stat.Hour
        Hour_Fluctuation = [Double]$Stat.Hour_Fluctuation
        Day = [Decimal]$Stat.Day
        Day_Fluctuation = [Double]$Stat.Day_Fluctuation
        Week = [Decimal]$Stat.Week
        Week_Fluctuation = [Double]$Stat.Week_Fluctuation
        Duration = [String]$Stat.Duration
        Updated = [DateTime]$Stat.Updated
    } | ConvertTo-Json | Set-Content $Path

    $Stat
}

function Get-Stat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [String]$Name
    )

    if (-not (Test-Path "Stats")) {New-Item "Stats" -ItemType "directory" | Out-Null}

    if ($Name) {
        # Return single requested stat
        Get-ChildItem "Stats" -File | Where-Object BaseName -EQ $Name | Get-Content | ConvertFrom-Json
    }
    else {
        # Return all stats
        $Stats = [PSCustomObject]@{}
        Get-ChildItem "Stats" | ForEach-Object {
            $BaseName = $_.BaseName
            $FullName = $_.FullName
            try {
                $_ | Get-Content -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop | ForEach-Object {
                    $Stats | Add-Member $BaseName $_
                }
            }
            catch {
                #Remove broken stat file
                Write-Log -Level Warn "Stat file ($BaseName) is corrupt and will be removed. "
                Remove-Item -Path $FullName -Force -Confirm:$false
            }
        }
        Return $Stats
    }
}

function Get-ChildItemContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Path, 
        [Parameter(Mandatory = $false)]
        [Hashtable]$Parameters = @{}
    )

    function Invoke-ExpressionRecursive ($Expression) {
        if ($Expression -is [String]) {
            if ($Expression -match '(\$|")') {
                try {$Expression = Invoke-Expression $Expression}
                catch {$Expression = Invoke-Expression "`"$Expression`""}
            }
        }
        elseif ($Expression -is [PSCustomObject]) {
            $Expression | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                $Expression.$_ = Invoke-ExpressionRecursive $Expression.$_
            }
        }
        return $Expression
    }

    Get-ChildItem $Path -File -ErrorAction SilentlyContinue | ForEach-Object {
        $Name = $_.BaseName
        $Content = @()
        if ($_.Extension -eq ".ps1") {
            $Content = & {
                $Parameters.Keys | ForEach-Object {Set-Variable $_ $Parameters.$_}
                & $_.FullName @Parameters
            }
        }
        else {
            $Content = & {
                $Parameters.Keys | ForEach-Object {Set-Variable $_ $Parameters.$_}
                try {
                    ($_ | Get-Content | ConvertFrom-Json) | ForEach-Object {Invoke-ExpressionRecursive $_}
                }
                catch [ArgumentException] {
                    $null
                }
            }
            if ($Content -eq $null) {$Content = $_ | Get-Content}
        }
        $Content | ForEach-Object {
            if ($_.Name) {
                [PSCustomObject]@{Name = $_.Name; Content = $_}
            }
            else {
                [PSCustomObject]@{Name = $Name; Content = $_}
            }
        }
    }
}

function Get-ChildItemContentParallel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Path,
        [Parameter(Mandatory = $false)]
        [Hashtable]$Parameters = @{}
    )
    $ScriptDir = (Get-Location).Path

    # Determine how many threads to use based on how many cores the system has, but force it to be between 2 and 8.
    $Threads = 2 # Default
    $Threads = ((Get-CimInstance win32_processor).NumberOfLogicalProcessors | Measure-Object -Sum).Sum 
    if ($Threads -lt 2) {$Threads = 2}
    if ($Threads -gt 8) {$Threads = 8}

    # Create a runspace pool with up to $Threads threads
    $RunspaceCollection = @()
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1,$Threads)
    $RunspacePool.Open()

    # Setup code block to process each file - Include.psm1 has to be imported into each runspace
    $ProcessItem = {
        Param($ScriptDir, $File, $Parameters)
        Set-Location $ScriptDir

        function Invoke-ExpressionRecursive ($Expression) {
            if ($Expression -is [String]) {
                if ($Expression -match '(\$|")') {
                    try {$Expression = Invoke-Expression $Expression}
                    catch {$Expression = Invoke-Expression "`"$Expression`""}
                }
            }
            elseif ($Expression -is [PSCustomObject]) {
                $Expression | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                    $Expression.$_ = Invoke-ExpressionRecursive $Expression.$_
                }
            }
            return $Expression
        }

        $Name = $File.BaseName
        $Content = @()
        if ($File.Extension -eq ".ps1") {
            $Content = & {
                $Parameters.Keys | ForEach-Object {Set-Variable $_ $Parameters.$_}
                & $File.FullName @Parameters
            }
        }
        else {
            $Content = & {
                $Parameters.Keys | ForEach-Object {Set-Variable $_ $Parameters.$_}
                try {
                    ($File | Get-Content | ConvertFrom-Json) | ForEach-Object {Invoke-ExpressionRecursive $_}
                }
                catch [ArgumentException] {
                    $null
                }
            }
            if ($Content -eq $null) {$Content = $File | Get-Content}
        }
        $Content | ForEach-Object {
            if ($_.Name) {
                [PSCustomObject]@{Name = $_.Name; Content = $_}
            }
            else {
                [PSCustomObject]@{Name = $Name; Content = $_}
            }
        }
    }

    # Get each requested file and process it in a runspace
    Get-ChildItem $Path -File -ErrorAction SilentlyContinue | ForEach-Object {
        $Powershell = [powershell]::Create().AddScript($ProcessItem, $true).AddArgument($ScriptDir).AddArgument($_).AddArgument($Parameters)
        $Powershell.RunspacePool = $RunSpacePool

        # Add to the collection of runspaces
        [Collections.ArrayList]$RunspaceCollection += New-Object -TypeName PSObject -Property @{
            Runspace = $PowerShell.BeginInvoke()
            Powershell = $Powershell
        }
    }

    # Wait for all runspaces to finish running and get their data
    while ($RunspaceCollection) {
        ForEach($Runspace in $RunspaceCollection.ToArray()) {
            if ($Runspace.Runspace.IsCompleted) {
                # End the runspace and get the returned objects
                $Runspace.PowerShell.EndInvoke($Runspace.Runspace)
                # Cleanup the runspace
                $Runspace.PowerShell.Dispose()
                $RunspaceCollection.Remove($Runspace)
            }
        }
    }
    # Cleanup runspaces
    $RunspacePool.Close()
    $RunspacePool.Dispose()
    Remove-Variable RunspacePool
    Remove-Variable RunspaceCollection
}

filter ConvertTo-Hash { 
    [CmdletBinding()]
    $Hash = $_
    switch ([math]::truncate([math]::log($Hash, [Math]::Pow(1000, 1)))) {
        "-Infinity" {"0  H"}
        0 {"{0:n2}  H" -f ($Hash / [Math]::Pow(1000, 0))}
        1 {"{0:n2} KH" -f ($Hash / [Math]::Pow(1000, 1))}
        2 {"{0:n2} MH" -f ($Hash / [Math]::Pow(1000, 2))}
        3 {"{0:n2} GH" -f ($Hash / [Math]::Pow(1000, 3))}
        4 {"{0:n2} TH" -f ($Hash / [Math]::Pow(1000, 4))}
        Default {"{0:n2} PH" -f ($Hash / [Math]::Pow(1000, 5))}
    }
}

filter ConvertTo-Price { 
    [CmdletBinding()]
    $Price = $_
    switch ([math]::truncate([math]::log($Price, [Math]::Pow(1000, 1)))) {
        -2 {"{0:n8} KH/Day" -f ($Price * [Math]::Pow(1000, 1))}
        -3 {"{0:n8} MH/Day" -f ($Price * [Math]::Pow(1000, 2))}
        -4 {"{0:n8} GH/Day" -f ($Price * [Math]::Pow(1000, 2))}
    }
}

function ConvertTo-LocalCurrency { 
    [CmdletBinding()]
    # To get same numbering scheme regardless of value BTC value (size) to determine formatting
    # Use $Offset to add/remove decimal places

    param(
        [Parameter(Mandatory = $true)]
        [Double]$Value,
        [Parameter(Mandatory = $true)]
        [Double]$BTCRate,
        [Parameter(Mandatory = $false)]
        [Int]$Offset        
    )

    $Digits = ([math]::truncate(10 - $Offset - [math]::log($BTCRate, 10)))
    if ($Digits -lt 0) {$Digits = 0}
    if ($Digits -gt 10) {$Digits = 10}
    
    ($Value * $BTCRate).ToString("N$($Digits)")
}

function Get-Combination {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Array]$Value, 
        [Parameter(Mandatory = $false)]
        [Int]$SizeMax = $Value.Count, 
        [Parameter(Mandatory = $false)]
        [Int]$SizeMin = 1
    )

    $Combination = [PSCustomObject]@{}

    for ($i = 0; $i -lt $Value.Count; $i++) {
        $Combination | Add-Member @{[Math]::Pow(2, $i) = $Value[$i]}
    }

    $Combination_Keys = $Combination | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

    for ($i = $SizeMin; $i -le $SizeMax; $i++) {
        $x = [Math]::Pow(2, $i) - 1

        while ($x -le [Math]::Pow(2, $Value.Count) - 1) {
            [PSCustomObject]@{Combination = $Combination_Keys | Where-Object {$_ -band $x} | ForEach-Object {$Combination.$_}}
            $smallest = ($x -band - $x)
            $ripple = $x + $smallest
            $new_smallest = ($ripple -band - $ripple)
            $ones = (($new_smallest / $smallest) -shr 1) - 1
            $x = $ripple -bor $ones
        }
    }
}

function Start-SubProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$FilePath, 
        [Parameter(Mandatory = $false)]
        [String]$ArgumentList = "", 
        [Parameter(Mandatory = $false)]
        [String]$WorkingDirectory = "", 
        [ValidateRange(-2, 3)]
        [Parameter(Mandatory = $false)]
        [Int]$Priority = 0
    )

    $PriorityNames = [PSCustomObject]@{-2 = "Idle"; -1 = "BelowNormal"; 0 = "Normal"; 1 = "AboveNormal"; 2 = "High"; 3 = "RealTime"}

    $Job = Start-Job -ArgumentList $PID, $FilePath, $ArgumentList, $WorkingDirectory {
        param($ControllerProcessID, $FilePath, $ArgumentList, $WorkingDirectory)

        $ControllerProcess = Get-Process -Id $ControllerProcessID
        if ($ControllerProcess -eq $null) {return}

        $ProcessParam = @{}
        $ProcessParam.Add("FilePath", $FilePath)
        #maximized, minimized, normal
        $ProcessParam.Add("WindowStyle", 'Normal')
        if ($ArgumentList -ne "") {$ProcessParam.Add("ArgumentList", $ArgumentList)}
        if ($WorkingDirectory -ne "") {$ProcessParam.Add("WorkingDirectory", $WorkingDirectory)}
        $Process = Start-Process @ProcessParam -PassThru
        if ($Process -eq $null) {
            [PSCustomObject]@{ProcessId = $null}
            return        
        }

        [PSCustomObject]@{ProcessId = $Process.Id; ProcessHandle = $Process.Handle}

        $ControllerProcess.Handle | Out-Null
        $Process.Handle | Out-Null

        do {if ($ControllerProcess.WaitForExit(1000)) {$Process.CloseMainWindow() | Out-Null}}
        while ($Process.HasExited -eq $false)
    }

    do {Start-Sleep 1; $JobOutput = Receive-Job $Job}
    while ($JobOutput -eq $null)
	
    if ($this.CName -ne $null) {
        $ProcessId = (get-ciminstance win32_process | ? parentprocessid -eq $JobOutput.ProcessId | ? name -eq $this.CName | select-object -expandproperty processid)
        $Process = Get-Process | Where-Object Id -EQ $ProcessId
        }
        else {
        $Process = Get-Process | Where-Object Id -EQ $JobOutput.ProcessId
        }
    $Process.Handle | Out-Null
    $Process

    if ($Process) {$Process.PriorityClass = $PriorityNames.$Priority}
}

function Expand-WebRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Uri, 
        [Parameter(Mandatory = $false)]
        [String]$Path = ""
    )

    # Set current path used by .net methods to the same as the script's path
    [Environment]::CurrentDirectory = $ExecutionContext.SessionState.Path.CurrentFileSystemLocation

    if (-not $Path) {$Path = Join-Path ".\Downloads" ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName}
    if (-not (Test-Path ".\Downloads")) {New-Item "Downloads" -ItemType "directory" | Out-Null}
    $FileName = Join-Path ".\Downloads" (Split-Path $Uri -Leaf)

    if (Test-Path $FileName) {Remove-Item $FileName}
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest $Uri -OutFile $FileName -UseBasicParsing

    if (".msi", ".exe" -contains ([IO.FileInfo](Split-Path $Uri -Leaf)).Extension) {
        Start-Process $FileName "-qb" -Wait
    }
    else {
        $Path_Old = (Join-Path (Split-Path $Path) ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName)
        $Path_New = (Join-Path (Split-Path $Path) (Split-Path $Path -Leaf))

        if (Test-Path $Path_Old) {Remove-Item $Path_Old -Recurse -Force}
        Start-Process "7z" "x `"$([IO.Path]::GetFullPath($FileName))`" -o`"$([IO.Path]::GetFullPath($Path_Old))`" -y -spe" -Wait

        if (Test-Path $Path_New) {Remove-Item $Path_New -Recurse -Force}
        if (Get-ChildItem $Path_Old | Where-Object PSIsContainer -EQ $false) {
            Rename-Item $Path_Old (Split-Path $Path -Leaf)
        }
        else {
            Get-ChildItem $Path_Old | Where-Object PSIsContainer -EQ $true | ForEach-Object {Move-Item (Join-Path $Path_Old $_) $Path_New}
            Remove-Item $Path_Old
        }
    }
}

function Invoke-TcpRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Server = "localhost", 
        [Parameter(Mandatory = $true)]
        [String]$Port, 
        [Parameter(Mandatory = $true)]
        [String]$Request, 
        [Parameter(Mandatory = $true)]
        [Int]$Timeout = 10 #seconds
    )

    try {
        $Client = New-Object System.Net.Sockets.TcpClient $Server, $Port
        $Stream = $Client.GetStream()
        $Writer = New-Object System.IO.StreamWriter $Stream
        $Reader = New-Object System.IO.StreamReader $Stream
        $client.SendTimeout = $Timeout * 1000
        $client.ReceiveTimeout = $Timeout * 1000
        $Writer.AutoFlush = $true

        $Writer.WriteLine($Request)
        $Response = $Reader.ReadLine()
    }
    finally {
        if ($Reader) {$Reader.Close()}
        if ($Writer) {$Writer.Close()}
        if ($Stream) {$Stream.Close()}
        if ($Client) {$Client.Close()}
    }

    $Response
}

function Get-Algorithm {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [String]$Algorithm = ""
    )

    if (-not (Test-Path Variable:Script:Algorithms)) {
        $Script:Algorithms = Get-Content "Algorithms.txt" | ConvertFrom-Json
    }

    $Algorithm = (Get-Culture).TextInfo.ToTitleCase(($Algorithm -replace "-", " " -replace "_", " ")) -replace " "

    if ($Script:Algorithms.$Algorithm) {$Script:Algorithms.$Algorithm}
    else {$Algorithm}
}

function Get-Region {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [String]$Region = ""
    )

    if (-not (Test-Path Variable:Script:Regions)) {
        $Script:Regions = Get-Content "Regions.txt" | ConvertFrom-Json
    }

    $Region = (Get-Culture).TextInfo.ToTitleCase(($Region -replace "-", " " -replace "_", " ")) -replace " "

    if ($Script:Regions.$Region) {$Script:Regions.$Region}
    else {$Region}
}

class Miner {
    $Name
    $Path
    $Arguments
    $Wrap
    $API
    $Port
    $Algorithm
    $Type
    $Index
    $Profit
    $Profit_Comparison
    $Profit_MarginOfError
    $Profit_Bias
    $Profit_Unbias
    $Speed
    $Speed_Live
    $Best
    $Best_Comparison
    $Process
    $New
    $Active
    [Int]$Activated = 0
    $Status
    $Benchmarked
    $CName
    $Pool
    $ExtendInterval

    [String[]]GetProcessNames() {
        return @(([IO.FileInfo]($this.Path | Split-Path -Leaf -ErrorAction Ignore)).BaseName)
    }
	
    StartMining() {
        $this.New = $true
        $this.Activated++
        if ($this.Process -ne $null) {
		$this.Active += $this.Process.ExitTime - $this.Process.StartTime
		}
        $this.Process = Start-SubProcess -FilePath $this.Path -ArgumentList $this.Arguments -WorkingDirectory (Split-Path $this.Path) -Priority ($this.Type | ForEach-Object {if ($this -eq "CPU") {-2}else {-1}} | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)
        if ($this.Process -eq $null) {$this.Status = "Failed"}
        else {$this.Status = "Running"}
    }

    StopMining() {
        $this.Process.CloseMainWindow() | Out-Null
        $this.Status = "Idle"
    }
	
    [Int]GetActivateCount() {
        return $this.Activated
    }

    [DateTime]GetActiveLast() {
        if ($this.Process.PSBeginTime -and $this.Process.PSEndTime) {
            return $this.Process.PSEndTime
        }
        elseif ($this.Process.PSBeginTime) {
            return Get-Date
        }
        else {
            return [DateTime]::MinValue
        }
    }

    [PSCustomObject]GetMinerData ([Bool]$Safe = $false) {
        $Lines = @()

        if ($this.Process.HasMoreData) {
            $this.Process | Receive-Job | ForEach-Object {
                $Line = $_ -replace "`n|`r", ""
                if ($Line -replace "\x1B\[[0-?]*[ -/]*[@-~]", "") {$Lines += $Line}
            }
        }

        return [PSCustomObject]@{
            Lines = $Lines
        }
    }
}
