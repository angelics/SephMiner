using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "AMD"
if (-not $Devices.$Type) {return} # No AMD present in system

$Path = ".\Bin\NeoScrypt-Claymore\NeoScryptMiner.exe"
$Uri = "https://github.com/MultiPoolMiner/miner-binaries/releases/download/neoscryptminer/Claymore.s.NeoScrypt.AMD.GPU.Miner.v1.2.zip"
$Port = 13333
$MinerFeeInPercent = 2.5
$MinerFeeInPercentSSL = 2

$Commands = [PSCustomObject]@{
    "neoscrypt" = "" #NeoScrypt
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
        Arguments  = ("-r -1 -mport -$Port -pool $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -wal $($Pools.$Algorithm_Norm.User) -psw $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)")
        HashRates  = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API        = "Claymore"
        Port       = $Port
        URI        = $Uri
        MinerFee   = @($Fee)
    }
} 
