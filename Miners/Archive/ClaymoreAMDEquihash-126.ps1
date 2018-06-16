using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "AMD"
if (-not $Devices.$Type) {return} # No AMD present in system

$Path = ".\Bin\Equihash-Claymore-126\ZecMiner64.exe"
$Uri = "https://github.com/MultiPoolMiner/miner-binaries/releases/download/zecminer64/Claymore.s.ZCash.AMD.GPU.Miner.v12.6.-.Catalyst.15.12-17.x.zip"
$MinerFeeInPercent = 2.5
$MinerFeeInPercentSSL = 2
$Port = 13333

$Commands = [PSCustomObject]@{
    "equihash" = "" #Equihash
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
                
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_
    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week

    if ($Pools.$Algorithm_Norm.SSL) {
        $MinerFeeInPercent = $MinerFeeInPercentSSL
    }
    $Fee = @($MinerFeeInPercent)
    $HashRate = $HashRate * (1 - $MinerFeeInPercent / 100)

    [PSCustomObject]@{
        Type       = $Type
        Path       = $Path
        Arguments  = ("-r -1 -mport -$Port -zpool $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -zwal $($Pools.$Algorithm_Norm.User) -zpsw $($Pools.$Algorithm_Norm.Pass)$($Commands.$_) -allpools 1")
        HashRates  = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API        = "Claymore"
        Port       = $Port
        URI        = $Uri
        MinerFee   = @($Fee)
    }
} 
