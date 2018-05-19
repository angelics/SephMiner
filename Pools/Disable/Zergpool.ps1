using module ..\Include.psm1

param(
    [alias("Wallet")]
    [String]$BTC, 
    [alias("WorkerName")]
    [String]$Worker, 
    [TimeSpan]$StatSpan
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Zergpool_Request = [PSCustomObject]@{}

try {
    $Zergpool_Request = Invoke-RestMethod "http://api.zergpool.com:8080/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    $ZpoolCoins_Request = Invoke-RestMethod "http://api.zergpool.com:8080/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
}
catch {
    Write-Log -Level Warn "Pool API ($Name) has failed. "
    return
}

if (($Zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) {
    Write-Log -Level Warn "Pool API ($Name) returned nothing. "
    return
}

try {
    $Zergpool_Variance = Invoke-RestMethod "https://semitest.000webhostapp.com/variance/zergpool.variance.txt" -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
}
catch {
    Write-Log -Level Warn "Pool Variance ($Name) has failed. Mining Without variance / fees in calcualtion."
}

$Zergpool_Regions = "us"
$Zergpool_Currencies = @("BTC","LTC","DASH") + ($ZpoolCoins_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name) | Select-Object -Unique | Where-Object {Get-Variable $_ -ValueOnly -ErrorAction SilentlyContinue}

$Zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object {$ExcludeAlgorithm -inotcontains (Get-Algorithm $Zergpool_Request.$_.name) -and $Zergpool_Request.$_.hashrate -gt 0} | ForEach-Object {
    $Zergpool_Host = "mine.zergpool.com"
    $Zergpool_Port = $Zergpool_Request.$_.port
    $Zergpool_Algorithm = $Zergpool_Request.$_.name
    $Zergpool_Algorithm_Norm = Get-Algorithm $Zergpool_Algorithm
    $Zergpool_Fee = $Zergpool_Request.$_.fees
    $Zergpool_Coin = ""

    $Divisor = 1000000

    switch ($ZergPool_Algorithm_Norm) {
        "equihash" {$Divisor /= 1000}
        "blake2s" {$Divisor *= 1000}
        "blakecoin" {$Divisor *= 1000}
        "keccak" {$Divisor *= 1000}
        "sha256t"{$Divisor *= 1000}
        "keccakc"{$Divisor *= 1000}
        "yescrypt"{$Divisor /= 1000}
        "yescryptr16"{$Divisor /= 1000}
    }
	
    $Zergpool_Fees = 1-($Zergpool_Fee/100)
	
    $Variance = 1 - $Zergpool_Variance."$Zergpool_Algorithm_Norm"
	
    if ($Variance -ne 0){$Variance -= 0.01}
	
    if($CREA -and $Zergpool_Algorithm_Norm -eq "Keccakc"){$Variance = 1}
    if($YTN -and $Zergpool_Algorithm_Norm -eq "yescryptr16"){$Variance = 1}
    if($PGN -and $Zergpool_Algorithm_Norm -eq "x16s"){$Variance = 1}
    if($HSR -and $Zergpool_Algorithm_Norm -eq "hsr"){$Variance = 1}
    if($BTX -and $Zergpool_Algorithm_Norm -eq "bitcore"){$Variance = 1}
    if($MAC -and $Zergpool_Algorithm_Norm -eq "timetravel"){$Variance = 1}
	
    if ((Get-Stat -Name "$($Name)_$($Zergpool_Algorithm_Norm)_Profit") -eq $null) {$Stat = Set-Stat -Name "$($Name)_$($Zergpool_Algorithm_Norm)_Profit" -Value ([Double]$Zergpool_Request.$_.estimate_last24h / $Divisor) -Duration (New-TimeSpan -Days 1)}
    else {$Stat = Set-Stat -Name "$($Name)_$($Zergpool_Algorithm_Norm)_Profit" -Value ([Double]$Zergpool_Request.$_.estimate_current / $Divisor) -Duration $StatSpan -ChangeDetection $true}

    $Stat.Live = $Stat.Live * $Zergpool_Fees * $Variance
    $Stat.Week = $Stat.Week * $Zergpool_Fees * $Variance
    $Stat.Week_Fluctuation = $Stat.Week_Fluctuation * $Zergpool_Fees * $Variance
	
    $Zergpool_Regions | ForEach-Object {
        $Zergpool_Region = $_
        $Zergpool_Region_Norm = Get-Region $Zergpool_Region

        $Zergpool_Currencies | ForEach-Object {
            [PSCustomObject]@{
                Algorithm     = $Zergpool_Algorithm_Norm
                Info          = $Zergpool_Coin
                Price         = $Stat.Live
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Week_Fluctuation
                Protocol      = "stratum+tcp"
                Host          = "$Zergpool_Algorithm.$Zergpool_Host"
                Port          = $Zergpool_Port
                User          = Get-Variable $_ -ValueOnly
                Pass          = "$Worker,c=$_"
                Region        = $Zergpool_Region_Norm
                SSL           = $false
                Updated       = $Stat.Updated
				PoolFee       = $Zergpool_Fee
				Variance      = $Variance
            }
        }
    }
}
