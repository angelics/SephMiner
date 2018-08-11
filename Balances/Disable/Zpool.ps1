using module ..\Include.psm1

param(
    $Config
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$PoolConfig = $Config.Pools.$Name

$Request = [PSCustomObject]@{}
$Request2 = [PSCustomObject]@{}

if($PoolConfig.BTC) {
    try {
        $Request = Invoke-RestMethod "http://zpool.ca/api/wallet?address=$($PoolConfig.BTC)" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    }
    catch {
        Write-Log -Level Warn "Pool Balance API ($Name) has failed. "
    }
}

if($PoolConfig.RVN) {
  try {
    $Request = Invoke-RestMethod "http://zpool.ca/api/wallet?address=$($PoolConfig.RVN)" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
	$Request2 = Invoke-RestMethod "https://min-api.cryptocompare.com/data/price?fsym=RVN&tsyms=BTC" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
	
  }
  catch {
    Write-Log -Level Warn "Pool Balance API ($Name) has failed. "
  }
}

if($PoolConfig.LTC) {
  try {
    $Request = Invoke-RestMethod "http://zpool.ca/api/wallet?address=$($PoolConfig.LTC)" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
	$Request2 = Invoke-RestMethod "https://min-api.cryptocompare.com/data/price?fsym=LTC&tsyms=BTC" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
	
  }
  catch {
    Write-Log -Level Warn "Pool Balance API ($Name) has failed. "
  }
}

if (($Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) {
    Write-Log -Level Warn "Pool Balance API ($Name) returned nothing. "
    return
}

[PSCustomObject]@{
    "currency" = $Request.currency
    "balance" = $Request.balance
    "pending" = $Request.unsold
    "total" = $Request.unpaid * $Request2.BTC
    'lastupdated' = (Get-Date).ToUniversalTime()
}