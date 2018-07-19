using module ..\Include.psm1

param(
    [alias("Wallet")]
    [String]$BTC, 
    [alias("WorkerName")]
    [String]$Worker, 
    [TimeSpan]$StatSpan
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$PhiPhi_Request = [PSCustomObject]@{}

try {
    $PhiPhi_Request = Invoke-RestMethod "http://www.phi-phi-pool.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    $PhiPhiCoins_Request = Invoke-RestMethod "http://www.phi-phi-pool.com/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
}
catch {
    Write-Log -Level Warn "Pool API ($Name) has failed. "
    return
}

if ((($PhiPhi_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) -or (($PhiPhiCoins_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1)) {
    Write-Log -Level Warn "Pool API ($Name) returned nothing. "
    return
}

try {
    $PhiPhi_Variance = Invoke-RestMethod "https://semitest.000webhostapp.com/variance/phiphi.variance.txt" -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
}
catch {
    Write-Log -Level Warn "Pool Variance ($Name) has failed. Mining Without variance in calcualtion."
}

$PhiPhi_Regions = "us"
$PhiPhi_Currencies = @("BTC") + ($PhiPhiCoins_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name) | Select-Object -Unique | Where-Object {Get-Variable $_ -ValueOnly -ErrorAction SilentlyContinue}

$PhiPhi_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object {$ExcludeAlgorithm -inotcontains (Get-Algorithm $PhiPhi_Request.$_.name)} | Where-Object {$PhiPhi_Request.$_.hashrate -gt 0} | ForEach-Object {
    $PhiPhi_Host = "pool1.phi-phi-pool.com"
    $PhiPhi_Port = $PhiPhi_Request.$_.port
    $PhiPhi_Algorithm = $PhiPhi_Request.$_.name
    $PhiPhi_Algorithm_Norm = Get-Algorithm $PhiPhi_Algorithm
    $PhiPhi_Fee = $PhiPhi_Request.$_.fees
    $PhiPhi_Coin = ""
	
	if ($PhiPhi_Variance.$PhiPhi_Algorithm_Norm.variance2){$Variances = $PhiPhi_Variance.$PhiPhi_Algorithm_Norm.variance2} else {$Variances = $PhiPhi_Variance.$PhiPhi_Algorithm_Norm.variance}
	
    $Divisor = 1000000 * [Double]$PhiPhi_Request.$_.mbtc_mh_factor
	
    $PhiPhi_Fees = 1-($PhiPhi_Fee/100)

    $Variance = 1 - $Variances
	
	if($BTX -and $PhiPhi_Algorithm_Norm -eq "bitcore"){$Variance = 1}
	if($CREA -and $PhiPhi_Algorithm_Norm -eq "Keccakc"){$Variance = 1}
    if($YTN -and $PhiPhi_Algorithm_Norm -eq "yescryptR16"){$Variance = 1}
    if($AEX -and $PhiPhi_Algorithm_Norm -eq "aergo"){$Variance = 1}
    if($LUX -and $PhiPhi_Algorithm_Norm -eq "phi2"){$Variance = 1}
    if($PLUS -and $PhiPhi_Algorithm_Norm -eq "hmq1725"){$Variance = 1}
    if($MLM -and $PhiPhi_Algorithm_Norm -eq "x17"){$Variance = 1}
    if($COG -and $PhiPhi_Algorithm_Norm -eq "skunk"){$Variance = 1}

    if ((Get-Stat -Name "$($Name)_$($PhiPhi_Algorithm_Norm)_Profit") -eq $null) {$Stat = Set-Stat -Name "$($Name)_$($PhiPhi_Algorithm_Norm)_Profit" -Value ([Double]$PhiPhi_Request.$_.estimate_last24h / $Divisor) -Duration (New-TimeSpan -Days 1)}
    else {$Stat = Set-Stat -Name "$($Name)_$($PhiPhi_Algorithm_Norm)_Profit" -Value ([Double]$PhiPhi_Request.$_.estimate_current / $Divisor) -Duration $StatSpan -ChangeDetection $true}

    $Stat.Live = $Stat.Live * $PhiPhi_Fees * $Variance
    $Stat.Week = $Stat.Week * $PhiPhi_Fees * $Variance
    $Stat.Week_Fluctuation = $Stat.Week_Fluctuation * $PhiPhi_Fees * $Variance
	
    $PhiPhi_Regions | ForEach-Object {
        $PhiPhi_Region = $_
        $PhiPhi_Region_Norm = Get-Region $PhiPhi_Region

        $PhiPhi_Currencies | ForEach-Object {
            [PSCustomObject]@{
                Algorithm     = $PhiPhi_Algorithm_Norm
                CoinName      = $PhiPhi_Coin
                Price         = $Stat.Live
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Week_Fluctuation
                Protocol      = "stratum+tcp"
                Host          = "$PhiPhi_Algorithm.$PhiPhi_Host"
                Port          = $PhiPhi_Port
                User          = Get-Variable $_ -ValueOnly
                Pass          = "$Worker,c=$_"
                Region        = $PhiPhi_Region_Norm
                SSL           = $false
                Updated       = $Stat.Updated
                PoolFee       = $PhiPhi_Fee
                Variance      = $Variance
            }
        }
    }
}
