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

$Zergpool_Regions = "us"
$Zergpool_Currencies = @("BTC") + ($ZpoolCoins_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name) | Select-Object -Unique | Where-Object {Get-Variable $_ -ValueOnly -ErrorAction SilentlyContinue}

$Zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object {$Zergpool_Request.$_.hashrate -gt 0} |ForEach-Object {
    $Zergpool_Host = "mine.zergpool.com"
    $Zergpool_Port = $Zergpool_Request.$_.port
    $Zergpool_Algorithm = $Zergpool_Request.$_.name
    $Zergpool_Algorithm_Norm = Get-Algorithm $Zergpool_Algorithm
    $Zergpool_Coin = ""

    $Divisor = 1000000

    switch ($ZergPool_Algorithm_Norm) {
        "equihash" {$Divisor /= 1000}
        "blake2s" {$Divisor *= 1000}
        "blakecoin" {$Divisor *= 1000}
		"keccak" {$Divisor *= 1000}
    }

    if ((Get-Stat -Name "$($Name)_$($Zergpool_Algorithm_Norm)_Profit") -eq $null) {$Stat = Set-Stat -Name "$($Name)_$($Zergpool_Algorithm_Norm)_Profit" -Value ([Double]$Zergpool_Request.$_.estimate_last24h / $Divisor * (1-($Zergpool_Request.$_.fees/100))) -Duration (New-TimeSpan -Days 1)}
    else {$Stat = Set-Stat -Name "$($Name)_$($Zergpool_Algorithm_Norm)_Profit" -Value ([Double]$Zergpool_Request.$_.estimate_current / $Divisor * (1-($Zergpool_Request.$_.fees/100))) -Duration $StatSpan -ChangeDetection $true}

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
                Host          = "$Zergpool_Host"
                Port          = $Zergpool_Port
                User          = Get-Variable $_ -ValueOnly
                Pass          = "$Worker,c=$_"
                Region        = $Zergpool_Region_Norm
                SSL           = $false
                Updated       = $Stat.Updated
            }
        }
    }
}
