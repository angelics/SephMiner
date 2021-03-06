﻿using module ..\Include.psm1

param(
    [alias("Wallet")]
    [String]$BTC, 
    [alias("WorkerName")]
    [String]$Worker, 
    [TimeSpan]$StatSpan
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Zpool_Request = [PSCustomObject]@{}

try {
    $Zpool_Request = Invoke-RestMethod "http://www.zpool.ca/api/status" -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
    $ZpoolCoins_Request = Invoke-RestMethod "http://www.zpool.ca/api/currencies" -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
}
catch {
    Write-Log -Level Warn "Pool API ($Name) has failed. "
    return
}

if ((($Zpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) -or (($ZpoolCoins_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1)) {
    Write-Log -Level Warn "Pool API ($Name) returned nothing. "
    return
}

$LocalVariance = ".\Variance\zpool.variance.txt"
try {
    Invoke-RestMethod "https://semitest.000webhostapp.com/variance/zpool.variance.txt" -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue -Outfile $LocalVariance
    }
catch {
	Write-Log -Level Warn "Pool Variance ($Name) has failed. Mining using local variance in calcualtion."
}

if (Test-Path $LocalVariance) {
	$Zpool_Variance = Get-ChildItemContent $LocalVariance | Select-Object -ExpandProperty Content
}
else {
	Write-Log -Level Warn "Pool Variance ($Name) has failed. No variance in calcualtion."
}

$Zpool_Regions = "na", "eu", "sea", "jp"
$Zpool_Currencies = @("BTC") + ($ZpoolCoins_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name) | Select-Object -Unique | Where-Object {Get-Variable $_ -ValueOnly -ErrorAction SilentlyContinue}

$Zpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object {$ExcludeAlgorithm -inotcontains (Get-Algorithm $Zpool_Request.$_.name)} | Where-Object {$Zpool_Request.$_.hashrate -gt 0} | ForEach-Object {
    $Zpool_Host = "mine.zpool.ca"
    $Zpool_Port = $Zpool_Request.$_.port
    $Zpool_Algorithm = $Zpool_Request.$_.name
    $Zpool_Algorithm_Norm = Get-Algorithm $Zpool_Algorithm
    $Zpool_Fee = $Zpool_Request.$_.fees
    $Zpool_Coin = ""
	
	if ($Zpool_Variance.$Zpool_Algorithm_Norm.variance2){$Variances = $Zpool_Variance.$Zpool_Algorithm_Norm.variance2} else {$Variances = $Zpool_Variance.$Zpool_Algorithm_Norm.variance}
	
    $Divisor = 1000000 * [Double]$Zpool_Request.$_.mbtc_mh_factor
	
    $Zpool_Fees = 1-($Zpool_Fee/100)

    $Variance = 1 - $Variances
	
    if($CREA -and $Zpool_Algorithm_Norm -eq "Keccakc"){$Variance = 1}
    if($MAX -and $Zpool_Algorithm_Norm -eq "Keccak"){$Variance = 1}
    if($XRE -and $Zpool_Algorithm_Norm -eq "x11evo"){$Variance = 1}
    if($BTX -and $Zpool_Algorithm_Norm -eq "bitcore"){$Variance = 1}
    if($MAC -and $Zpool_Algorithm_Norm -eq "timetravel"){$Variance = 1}
    if($YTN -and $Zpool_Algorithm_Norm -eq "yescryptR16"){$Variance = 1}
    if($GRLC -and $Zpool_Algorithm_Norm -eq "allium"){$Variance = 1}
    if($XMG -and $Zpool_Algorithm_Norm -eq "m7m"){$Variance = 1}

    if ((Get-Stat -Name "$($Name)_$($Zpool_Algorithm_Norm)_Profit") -eq $null) {$Stat = Set-Stat -Name "$($Name)_$($Zpool_Algorithm_Norm)_Profit" -Value ([Double]$Zpool_Request.$_.estimate_last24h / $Divisor) -Duration (New-TimeSpan -Days 1)}
    else {$Stat = Set-Stat -Name "$($Name)_$($Zpool_Algorithm_Norm)_Profit" -Value ([Double]$Zpool_Request.$_.estimate_current / $Divisor) -Duration $StatSpan -ChangeDetection $true}

    $Stat.Live = $Stat.Live * $Zpool_Fees * $Variance
    $Stat.Week = $Stat.Week * $Zpool_Fees * $Variance
    $Stat.Week_Fluctuation = $Stat.Week_Fluctuation * $Zpool_Fees * $Variance
	
    $Zpool_Regions | ForEach-Object {
        $Zpool_Region = $_
        $Zpool_Region_Norm = Get-Region $Zpool_Region

        $Zpool_Currencies | ForEach-Object {
            [PSCustomObject]@{
                Algorithm     = $Zpool_Algorithm_Norm
                CoinName      = $Zpool_Coin
                Price         = $Stat.Live
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Week_Fluctuation
                Protocol      = "stratum+tcp"
                Host          = "$Zpool_Algorithm.$Zpool_Region.$Zpool_Host"
                Port          = $Zpool_Port
                User          = Get-Variable $_ -ValueOnly
                Pass          = "$Worker,c=$_"
                Region        = $Zpool_Region_Norm
                SSL           = $false
                Updated       = $Stat.Updated
                PoolFee       = $Zpool_Fee
                Variance      = $Variance
            }
        }
    }
}
