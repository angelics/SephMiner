using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-Alexis78-12b1\ccminer.exe"
$API  = "Ccminer"
$Uri  = "https://semitest.000webhostapp.com/binary/ccminerAlexis78v1.2b1x32.7z"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee  = 0

$Commands = [PSCustomObject[]]@(
    #[PSCustomObject]@{Algorithm = "blake2s"; Params = ""; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #blake2s not profit
    [PSCustomObject]@{Algorithm = "c11"; Params = " -i 21"; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #c11
    #[PSCustomObject]@{Algorithm = "hsr"; Params = ""; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #Hsr NVIDIA-TRex-051
    #[PSCustomObject]@{Algorithm = "keccak"; Params = " -m 2 -i 29"; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #Keccak ExcavatorNvidia-144a
    [PSCustomObject]@{Algorithm = "keccakc"; Params = " -i 29"; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #keccakc
    [PSCustomObject]@{Algorithm = "lyra2"; Params = ""; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #lyra2
    #[PSCustomObject]@{Algorithm = "lyra2v2"; Params = ""; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #Lyra2RE2 NVIDIA-CryptoDredge-070
    #[PSCustomObject]@{Algorithm = "neoscrypt"; Params = ""; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #NeoScrypt PalginNvidiaFork-45ee8fa
    [PSCustomObject]@{Algorithm = "poly"; Params = ""; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #poly
    [PSCustomObject]@{Algorithm = "skein"; Params = ""; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #skein
    [PSCustomObject]@{Algorithm = "skein2"; Params = ""; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #skein2
    [PSCustomObject]@{Algorithm = "whirlcoin"; Params = ""; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #whirlcoin
    [PSCustomObject]@{Algorithm = "whirlpool"; Params = ""; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #whirlpool
    [PSCustomObject]@{Algorithm = "x11evo"; Params = " -i 21"; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #x11evo
    #[PSCustomObject]@{Algorithm = "x17"; Params = " -i 20"; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #X17 NVIDIA-TRex-051
)

$CommonCommands = "" #eg. " -d 0,1,8,9"

$DeviceIDs = (Get-DeviceIDs -Config $Config -Devices $Devices -Type NVIDIA -DeviceTypeModel $($Devices.NVIDIA) -DeviceIdBase 10 -DeviceIdOffset 0)."$(if ($Type -EQ "NVIDIA"){"All"}else{$Type})"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Where-Object {$Pools.(Get-Algorithm $_.Algorithm).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_.Algorithm
	
    $StaticDiff = $_."$($Pools.$Algorithm_Norm.Name)"
	
    Switch ($Algorithm_Norm) {
        "allium"        {$ExtendInterval = 2}
        "CryptoNightV7" {$ExtendInterval = 2}
        "Lyra2RE2"      {$ExtendInterval = 2}
        "phi"           {$ExtendInterval = 2}
        "phi2"          {$ExtendInterval = 2}
        "tribus"        {$ExtendInterval = 2}
        "X16R"          {$ExtendInterval = 3}
        "X16S"          {$ExtendInterval = 3}
        "X17"           {$ExtendInterval = 2}
        "Xevan"         {$ExtendInterval = 2}
        default         {$ExtendInterval = 0}
    }
	
    Switch ($Algorithm_Norm) {
        "Lyra2RE2" {$Average = 1}
        "lyra2z"   {$Average = 1}
        "phi"      {$Average = 1}
        "tribus"   {$Average = 1}
        "Xevan"    {$Average = 1}
        default    {$Average = 3}
    }

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type           = $Type
        Path           = $Path
        Arguments      = "-q -b $($Port) -a $($_.Algorithm) -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($StaticDiff)$($_.Params)$($CommonCommands) -N $($Average) -d $($DeviceIDs -join ',')"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = $API
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}
