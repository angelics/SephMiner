using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)
$Type = "AMD"
if (-not $Devices.$Type) {return} # No AMD mining device present in system

$Path = ".\Bin\CryptoNight-Claymore-113\NsGpuCNMiner.exe"
$Uri = "https://mega.co.nz/#F!e4JVEAIJ!l1iF4z10fMyJzY5-LnyC2A"
$Port = 13333
$Fee = 0

$Commands = [PSCustomObject]@{
    "cryptonightV7"   = "" #CryptoNightV7
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
                
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_
    
    if ($Pools.$Algorithm_Norm) { # must have a valid pool to mine
	
    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week

    [PSCustomObject]@{
        Type      = $Type
        Path      = $Path
        Arguments = ("-r -1 -pow7 1 -mport -$Port -xpool $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -xwal $($Pools.$Algorithm_Norm.User) -xpsw $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)")
        HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API       = "Claymore"
        Port      = $Port
        URI       = $Uri
        MinerFee  = @($Fee)
    }
} 
