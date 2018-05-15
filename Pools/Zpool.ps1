using module ..\Include.psm1

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
    $Zpool_Request = Invoke-RestMethod "http://www.zpool.ca/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    $ZpoolCoins_Request = Invoke-RestMethod "http://www.zpool.ca/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
}
catch {
    Write-Log -Level Warn "Pool API ($Name) has failed. "
    return
}

if ((($Zpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) -or (($ZpoolCoins_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1)) {
    Write-Log -Level Warn "Pool API ($Name) returned nothing. "
    return
}

try {
    $Zpool_Variance = Invoke-RestMethod "https://semitest.000webhostapp.com/variance/zpool.variance.txt" -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
}
catch {
    Write-Log -Level Warn "Pool Variance ($Name) has failed. Mining Without variance / fees in calcualtion."
}

$Zpool_Regions = "us"
$Zpool_Currencies = @("BTC") + ($ZpoolCoins_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name) | Select-Object -Unique | Where-Object {Get-Variable $_ -ValueOnly -ErrorAction SilentlyContinue}

$Zpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object {$ExcludeAlgorithm -inotcontains (Get-Algorithm $Zpool_Request.$_.name)} | Where-Object {$Zpool_Request.$_.hashrate -gt 0} | ForEach-Object {
    $Zpool_Host = "mine.zpool.ca"
    $Zpool_Port = $Zpool_Request.$_.port
    $Zpool_Algorithm = $Zpool_Request.$_.name
    $Zpool_Algorithm_Norm = Get-Algorithm $Zpool_Algorithm
    $Zpool_Fee = $Zpool_Request.$_.fees
    $Zpool_Coin = ""

    $Divisor = 1000000

    switch ($Zpool_Algorithm_Norm) {
        "equihash" {$Divisor /= 1000}
        "blake2s" {$Divisor *= 1000}
        "blakecoin" {$Divisor *= 1000}
        "keccak" {$Divisor *= 1000}
        "keccakc" {$Divisor *= 1000}
        "sha256t" {$Divisor *= 1000}
    }	
	
    $Zpool_Fees = 1-($Zpool_Fee/100)
	
    $Variance = 1

    $Variance = 1 - $Zpool_Variance."$Zpool_Algorithm_Norm"
	
    if ($Variance -ne 0){$Variance -= 0.01}
	
    if($CREA -and $Zpool_Algorithm_Norm -eq "Keccakc"){$Variance = 1}
    if($OC -and $Zpool_Algorithm_Norm -eq "sha256t"){$Variance = 1}
    if($MAX -and $Zpool_Algorithm_Norm -eq "Keccak"){$Variance = 1}
    if($XZC -and $Zpool_Algorithm_Norm -eq "lyra2z"){$Variance = 1}
    if($BSD -and $Zpool_Algorithm_Norm -eq "xevan"){$Variance = 1}
    if($HSR -and $Zpool_Algorithm_Norm -eq "hsr"){$Variance = 1}
    if($XRE -and $Zpool_Algorithm_Norm -eq "x11evo"){$Variance = 1}
    if($BTX -and $Zpool_Algorithm_Norm -eq "bitcore"){$Variance = 1}
    if($MAC -and $Zpool_Algorithm_Norm -eq "timetravel"){$Variance = 1}
    if($YTN -and $Zpool_Algorithm_Norm -eq "yescryptR16"){$Variance = 1}

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
                Info          = $Zpool_Coin
                Price         = $Stat.Live
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Week_Fluctuation
                Protocol      = "stratum+tcp"
                Host          = "$Zpool_Algorithm.$Zpool_Host"
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
