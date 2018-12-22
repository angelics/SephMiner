using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-KlausT-Yescrypt\ccminer.exe"
$API  = "Ccminer"
$Uri  = "https://github.com/nemosminer/ccminerKlausTyescrypt/releases/download/v10/ccminerKlausTyescryptv10.7z"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee  = 0

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{Algorithm = "yescrypt"; Params = " -i 12.5"; Zpool = ""; MiningPoolHubCoins = ""} #yescrypt
    [PSCustomObject]@{Algorithm = "yescryptR8"; Params = " -i 12.5"; Zpool = ""; MiningPoolHubCoins = ""} #yescryptR8
    [PSCustomObject]@{Algorithm = "yescryptR24"; Params = " -i 12.5"; Zpool = ""; MiningPoolHubCoins = ""} #yescryptR24
    [PSCustomObject]@{Algorithm = "yescryptR32"; Params = " -i 11"; Zpool = ""; MiningPoolHubCoins = ""} #WAVI
)

$CommonCommands = "" #eg. " -d 0,1,8,9"

$DeviceIDs = (Get-DeviceIDs -Config $Config -Devices $Devices -Type NVIDIA -DeviceTypeModel $($Devices.NVIDIA) -DeviceIdBase 10 -DeviceIdOffset 0)."$(if ($Type -EQ "NVIDIA"){"All"}else{$Type})"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Where-Object {$Pools.(Get-Algorithm $_.Algorithm).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_.Algorithm
	
    $StaticDiff = $_."$($Pools.$Algorithm_Norm.Name)"

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type      = $Type
        Path      = $Path
        Arguments = "-q -b $($Port) -a $($_.Algorithm) -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($StaticDiff)$($_.Params)$($CommonCommands) -d $($DeviceIDs -join ',')"
        HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API       = $API
        Port      = $Port
        URI       = $Uri
        MinerFee  = @($Fee)
    }
}
