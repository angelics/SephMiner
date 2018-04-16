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

try {
    $MiningPoolHubCoins_Request = Invoke-RestMethod "http://miningpoolhub.com/index.php?page=api&action=getminingandprofitsstatistics&$(Get-Date -Format "yyyy-MM-dd_HH-mm")" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
}
catch {
    Write-Log -Level Warn "Pool API ($Name) has failed. "
    return
}

if (($MiningPoolHubCoins_Request.return | Measure-Object).Count -le 1) {
    Write-Log -Level Warn "Pool API ($Name) returned nothing. "
    return
}

$MiningPoolHubCoins_Regions = "europe", "us-east", "asia"

$MiningPoolHubCoins_Request.return | Where-Object {$ExcludeCoin -inotcontains $_.coin_name -and ($Coin.count -eq 0 -or $Coin -icontains $_.coin_name) -and $_.pool_hash -gt 0} | Where-Object {$ExcludeAlgorithm -inotcontains (Get-Algorithm $_.algo)} |ForEach-Object {
    $MiningPoolHubCoins_Host = $_.host
    $MiningPoolHubCoins_Hosts = $_.host_list.split(";")
    $MiningPoolHubCoins_Port = $_.port
    $MiningPoolHubCoins_Algorithm = $_.algo
    $MiningPoolHubCoins_Algorithm_Norm = Get-Algorithm $MiningPoolHubCoins_Algorithm
    $MiningPoolHubCoins_Coin = (Get-Culture).TextInfo.ToTitleCase(($_.coin_name -replace "-", " " -replace "_", " ")) -replace " "

    $Divisor = 1000000000
	
	$Variety = 0
	
    switch ($MiningPoolHubCoins_Coin) {
        "bitcoingold" {$Variety = 0.06}
        "feathercoin" {$Variety = 0.01}
        "Globalboosty" {$Variety = 0.14}
        "monacoin" {$Variety = 0.03}
        "monero" {$Variety = 0.01}
        "musicoin" {$Variety = 0.01}
        "MyriadcoinYescrypt" {$Variety = 0.03}
        "vertcoin" {$Variety = 0.05}
        "zcash" {$Variety = 0.01}
        "zclassic" {$Variety = 0.01}
        "zcoin" {$Variety = 0.05}
        "zencash" {$Variety = 0.05}
    }	

	$Stat = Set-Stat -Name "$($Name)_$($MiningPoolHubCoins_Coin)_Profit" -Value ([Double]$_.profit / $Divisor * (1-(0.9/100)) * (1-$Variety)) -Duration $StatSpan -ChangeDetection $true
	
    $MiningPoolHubCoins_Regions | ForEach-Object {
        $MiningPoolHubCoins_Region = $_
        $MiningPoolHubCoins_Region_Norm = Get-Region $MiningPoolHubCoins_Region

        if ($User) {
            if ($MiningPoolHubCoins_Algorithm_Norm -eq "CryptonightV7") {
                [PSCustomObject]@{
                    Algorithm     = $MiningPoolHubCoins_Algorithm_Norm
                    Info          = $MiningPoolHubCoins_Coin
                    Price         = $Stat.Live
                    StablePrice   = $Stat.Week
                    MarginOfError = $Stat.Week_Fluctuation
                    Protocol      = "stratum+tcp"
                    Host          = "$($MiningPoolHubCoins_Region).cryptonight-$($MiningPoolHubCoins_Host)"
                    Port          = $MiningPoolHubCoins_Port
                    User          = "$User.$Worker"
                    Pass          = "x"
                    Region        = $MiningPoolHubCoins_Region_Norm
                    SSL           = $false
                    Updated       = $Stat.Updated
                }
                [PSCustomObject]@{
                    Algorithm     = $MiningPoolHubCoins_Algorithm_Norm
                    Info          = $MiningPoolHubCoins_Coin
                    Price         = $Stat.Live
                    StablePrice   = $Stat.Week
                    MarginOfError = $Stat.Week_Fluctuation
                    Protocol      = "stratum+ssl"
                    Host          = "$($MiningPoolHubCoins_Region).cryptonight-$($MiningPoolHubCoins_Host)"
                    Port          = $MiningPoolHubCoins_Port
                    User          = "$User.$Worker"
                    Pass          = "x"
                    Region        = $MiningPoolHubCoins_Region_Norm
                    SSL           = $true
                    Updated       = $Stat.Updated
                }
            }
            else {
                [PSCustomObject]@{
                    Algorithm     = $MiningPoolHubCoins_Algorithm_Norm
                    Info          = $MiningPoolHubCoins_Coin
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
                }

                if ($MiningPoolHubCoins_Algorithm_Norm -eq "Ethash" -and $MiningPoolHubCoins_Coin -NotLike "*ethereum*") {
                    [PSCustomObject]@{
                        Algorithm     = "$($MiningPoolHubCoins_Algorithm_Norm)2gb"
                        Info          = $MiningPoolHubCoins_Coin
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
                    }
                }

                if ($MiningPoolHubCoins_Algorithm_Norm -eq "Equihash") {
                    [PSCustomObject]@{
                        Algorithm     = $MiningPoolHubCoins_Algorithm_Norm
                        Info          = $MiningPoolHubCoins_Coin
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
                    }
                }
            }
        }
    }
}
Sleep 0