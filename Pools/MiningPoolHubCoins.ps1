using module ..\Include.psm1

param(
    [alias("UserName")]
    [String]$User, 
    [alias("WorkerName")]
    [String]$Worker, 
    [TimeSpan]$StatSpan
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$MiningPoolHubCoins_Request = [PSCustomObject]@{}

#defines minimum memory required per coin, default is 4gb
$MinMem = [PSCustomObject]@{
    "Expanse"  = "2gb"
    "Soilcoin" = "2gb"
    "Ubiq"     = "2gb"
    "Musicoin" = "3gb"
}

try {
    $MiningPoolHubCoins_Request = Invoke-RestMethod "http://miningpoolhub.com/index.php?page=api&action=getminingandprofitsstatistics&$(Get-Date -Format "yyyy-MM-dd_HH-mm")" -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
}
catch {
    Write-Log -Level Warn "Pool API ($Name) has failed. "
    return
}

if (($MiningPoolHubCoins_Request.return | Measure-Object).Count -le 1) {
    Write-Log -Level Warn "Pool API ($Name) returned nothing. "
    return
}

$LocalVariance = ".\Variance\mphc.variance.txt"
try {
    $MiningPoolHubCoins_Variance = Invoke-RestMethod "https://semitest.000webhostapp.com/variance/mphc.variance.txt" -UseBasicParsing -TimeoutSec 15 -ErrorAction SilentlyContinue
    }
catch {
    Write-Log -Level Warn "Pool Variance ($Name) has failed. Mining using local variance in calcualtion."
	if (Test-Path $LocalVariance) {
		$MiningPoolHubCoins_Variance = Get-ChildItemContent $LocalVariance | Select-Object -ExpandProperty Content
	}
}

$MiningPoolHubCoins_Regions = "europe", "us-east", "asia"

$MiningPoolHubCoins_Request.return | Where-Object {$ExcludeCoin -inotcontains $_.coin_name -and ($Coin.count -eq 0 -or $Coin -icontains $_.coin_name) -and $_.pool_hash -gt 0} | Where-Object {$ExcludeAlgorithm -inotcontains (Get-Algorithm $_.algo)} |ForEach-Object {
    $MiningPoolHubCoins_Host = $_.host
    $MiningPoolHubCoins_Hosts = $_.host_list.split(";")
    $MiningPoolHubCoins_Port = $_.port
    $MiningPoolHubCoins_Algorithm = $_.algo
    $MiningPoolHubCoins_Algorithm_Norm = Get-Algorithm $MiningPoolHubCoins_Algorithm
    $MiningPoolHubCoins_Coin = (Get-Culture).TextInfo.ToTitleCase(($_.coin_name -replace "-", " " -replace "_", " ")) -replace " "
    $MiningPoolHubCoins_Fee = 0.9

    $Divisor = 1000000000

    $Variance = 1 - $MiningPoolHubCoins_Variance.$MiningPoolHubCoins_Coin
	
    if ($Variance -ne 0){$Variance -= 0.01}

    if($DisableExchange -contains $MiningPoolHubCoins_Coin){$Variance = 1}
	
	#if($MiningPoolHubCoins_Coin -eq "Ethereum") {$MiningPoolHubCoins_Fee = 0} #valid until 180630
    $MiningPoolHubCoins_Fees = 1-($MiningPoolHubCoins_Fee/100)
	
    $Stat = Set-Stat -Name "$($Name)_$($MiningPoolHubCoins_Coin)_Profit" -Value ([Double]$_.profit / $Divisor) -Duration $StatSpan -ChangeDetection $true
	
    $Stat.Live = $Stat.Live * $MiningPoolHubCoins_Fees * $Variance
    $Stat.Week = $Stat.Week * $MiningPoolHubCoins_Fees * $Variance
    $Stat.Week_Fluctuation = $Stat.Week_Fluctuation * $MiningPoolHubCoins_Fees * $Variance
	
    $MiningPoolHubCoins_Regions | ForEach-Object {
        $MiningPoolHubCoins_Region = $_
        $MiningPoolHubCoins_Region_Norm = Get-Region ($MiningPoolHubCoins_Region -replace "^us-east$", "us")

        if ($User) {
            if ($MiningPoolHubCoins_Algorithm_Norm -eq "EquihashBTG") {
                [PSCustomObject]@{
                    Algorithm     = $MiningPoolHubCoins_Algorithm_Norm
                    CoinName      = $MiningPoolHubCoins_Coin
                    Price         = $Stat.Live
                    StablePrice   = $Stat.Week
                    MarginOfError = $Stat.Week_Fluctuation
                    Protocol      = "stratum+tcp"
                    Host          = "$($MiningPoolHubCoins_Region).equihash-$($MiningPoolHubCoins_Host)"
                    Port          = $MiningPoolHubCoins_Port
                    User          = "$User.$Worker"
                    Pass          = "x"
                    Region        = $MiningPoolHubCoins_Region_Norm
                    SSL           = $false
                    Updated       = $Stat.Updated
                    PoolFee       = $MiningPoolHubCoins_Fee
                    Variance      = $Variance
                }
			}
			else {
                    [PSCustomObject]@{
                    Algorithm     = "$($MiningPoolHubCoins_Algorithm_Norm)$(if ($MiningPoolHubCoins_Algorithm_Norm -EQ "Ethash"){$MinMem.$MiningPoolHubCoins_Coin})"
                    CoinName      = $MiningPoolHubCoins_Coin
                    Price         = $Stat.Live
                    StablePrice   = $Stat.Week
                    MarginOfError = $Stat.Week_Fluctuation
                    Protocol      = "stratum+tcp"
                    Host          = $MiningPoolHubCoins_Hosts | Sort-Object -Descending {$_ -ilike "$MiningPoolHubCoins_Region*"} | Select-Object -First 1
                    Port          = $MiningPoolHubCoins_Port
                    User          = "$User.$Worker"
                    Pass          = "x"
                    Region        = $MiningPoolHubCoins_Region_Norm
                    SSL           = $false
                    Updated       = $Stat.Updated
                    PoolFee       = $MiningPoolHubCoins_Fee
                    Variance      = $Variance
                }
			}
            if ($MiningPoolHubCoins_Algorithm_Norm -eq "Equihash") {
                [PSCustomObject]@{
                    Algorithm     = $MiningPoolHubCoins_Algorithm_Norm
                    CoinName      = $MiningPoolHubCoins_Coin
                    Price         = $Stat.Live
                    StablePrice   = $Stat.Week
                    MarginOfError = $Stat.Week_Fluctuation
                    Protocol      = "stratum+ssl"
                    Host          = $MiningPoolHubCoins_Hosts | Sort-Object -Descending {$_ -ilike "$MiningPoolHubCoins_Region*"} | Select-Object -First 1
                    Port          = $MiningPoolHubCoins_Port
                    User          = "$User.$Worker"
                    Pass          = "x"
                    Region        = $MiningPoolHubCoins_Region_Norm
                    SSL           = $true
                    Updated       = $Stat.Updated
                    PoolFee       = $MiningPoolHubCoins_Fee
                    Variance      = $Variance
                }
            }
        }
    }
}