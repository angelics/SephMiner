using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

$DriverVersion = (Get-Devices).NVIDIA.Platform.Version -replace ".*CUDA ",""
$RequiredVersion = "9.2.00"
if ($DriverVersion -lt $RequiredVersion) {
    Write-Log -Level Warn "Miner ($($Name)) requires CUDA version $($RequiredVersion) or above (installed version is $($DriverVersion)). Please update your Nvidia drivers to 397.93 or newer. "
    return
}

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-TPruvot-23b1\ccminer-x64.exe"
$API  = "Ccminer"
$Uri  = "http://semitest.000webhostapp.com/binary/ccminer-2.3-B1.7z"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee  = 0

$Commands = [PSCustomObject[]]@(
    #[PSCustomObject]@{Algorithm = "allium"; Params = " -i 21"; Zpool = ""; ZergpoolCoins = ""} #allium NVIDIA-CryptoDredge-070
    #[PSCustomObject]@{Algorithm = "bitcore"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #bitcore CcminerZEnemy-112
    #[PSCustomObject]@{Algorithm = "blake2s"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #bitcore CcminerZEnemy-112
    [PSCustomObject]@{Algorithm = "bmw"; Params = ""} #bmw
    #[PSCustomObject]@{Algorithm = "c11"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #C11 NVIDIA-Alexis78-12b1
    [PSCustomObject]@{Algorithm = "deep"; Params = ""} #deep
    [PSCustomObject]@{Algorithm = "dmd-gr"; Params = ""} #dmd-gr
    [PSCustomObject]@{Algorithm = "fresh"; Params = ""} #fresh
    [PSCustomObject]@{Algorithm = "fugue256"; Params = ""} #fugue256
    [PSCustomObject]@{Algorithm = "heavy"; Params = ""} #heavy
    #[PSCustomObject]@{Algorithm = "hsr"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #hsr NVIDIA-CcminerAlexis78-12b1
    #[PSCustomObject]@{Algorithm = "hmq1725"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #hmq1725 NVIDIA-TRex-065
    [PSCustomObject]@{Algorithm = "jha"; Params = ""} #JHA
    #[PSCustomObject]@{Algorithm = "keccak"; Params = " -i 29"; Zpool = " -m 2"; ZergpoolCoins = " -m 2"; MiningPoolHubCoins = ""} #Keccak ExcavatorNvidia-144a
    #[PSCustomObject]@{Algorithm = "keccakc"; Params = " -i 29"; Zpool = ""; ZergpoolCoins = ""} #keccakc NVIDIA-Alexis78-12b1
    [PSCustomObject]@{Algorithm = "luffa"; Params = ""} #luffa
    [PSCustomObject]@{Algorithm = "lyra2"; Params = ""} #lyra2
    #[PSCustomObject]@{Algorithm = "lyra2v2"; Params = ""; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #Lyra2RE2
    #[PSCustomObject]@{Algorithm = "lyra2z"; Params = " -i 20"; Zpool = ""; ZergpoolCoins = ""} #Lyra2z CcminerOurMiner32-100
    #[PSCustomObject]@{Algorithm = "monero"; Params = ""; MiningPoolHubCoins = ""} #CryptoNightV7 NVIDIA-CryptoDredge-091
    [PSCustomObject]@{Algorithm = "mjollnir"; Params = ""} #mjollnir
    #[PSCustomObject]@{Algorithm = "neoscrypt"; Params = ""; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #NeoScrypt PalginNvidiaFork-45ee8fa
    [PSCustomObject]@{Algorithm = "penta"; Params = ""} #penta
    #[PSCustomObject]@{Algorithm = "phi"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #phi CcminerDumax-093
    #[PSCustomObject]@{Algorithm = "phi2"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #phi2 CcminerZEnemy-112
    #[PSCustomObject]@{Algorithm = "polytimos"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #polytimos NVIDIA-TRex-064
    [PSCustomObject]@{Algorithm = "scrypt-jane"; Params = ""} #scrypt-jane
    [PSCustomObject]@{Algorithm = "s3"; Params = ""} #s3
    #[PSCustomObject]@{Algorithm = "sha256t"; Params = " -i 29"; Zpool = ""; ZergpoolCoins = ""} #sha256t crash
    [PSCustomObject]@{Algorithm = "skein2"; Params = ""} #Skein2
    #[PSCustomObject]@{Algorithm = "skunk"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Skunk CcminerZEnemy-112
    #[PSCustomObject]@{Algorithm = "sonoa"; Params = ""} #sonoa NVIDIA-TRex-063
    [PSCustomObject]@{Algorithm = "stellite"; Params = ""} #stellite
    #[PSCustomObject]@{Algorithm = "timetravel"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Timetravel CcminerZEnemy-112
    #[PSCustomObject]@{Algorithm = "tribus"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Tribus CcminerZEnemy-112
    #[PSCustomObject]@{Algorithm = "x11evo"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #X11evo CcminerAlexis78-12
    [PSCustomObject]@{Algorithm = "x12"; Params = ""} #X12
    #[PSCustomObject]@{Algorithm = "x16r"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #X16r
    #[PSCustomObject]@{Algorithm = "x16s"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #X16s
    #[PSCustomObject]@{Algorithm = "x17"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #X17
    [PSCustomObject]@{Algorithm = "whirlpool"; Params = ""} #whirlpool
    [PSCustomObject]@{Algorithm = "wildkeccak"; Params = ""} #wildkeccak
    [PSCustomObject]@{Algorithm = "zr5"; Params = ""} #zr5
)

$CommonCommands = "" #eg. " -d 0,1,8,9"

$DeviceIDs = (Get-DeviceIDs -Config $Config -Devices $Devices -Type NVIDIA -DeviceTypeModel $($Devices.NVIDIA) -DeviceIdBase 10 -DeviceIdOffset 0)."$(if ($Type -EQ "NVIDIA"){"All"}else{$Type})"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Where-Object {$Pools.(Get-Algorithm $_.Algorithm).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_.Algorithm
	
    $StaticDiff = $_."$($Pools.$Algorithm_Norm.Name)"

    Switch ($Algorithm_Norm) {
        "allium"        {$ExtendInterval = 3}
        "CryptoNightV7" {$ExtendInterval = 3}
        "hmq1725"       {$ExtendInterval = 3}
        "Lyra2RE2"      {$ExtendInterval = 3}
        "phi"           {$ExtendInterval = 3}
        "phi2"          {$ExtendInterval = 3}
        "tribus"        {$ExtendInterval = 3}
        "X16R"          {$ExtendInterval = 4}
        "X16S"          {$ExtendInterval = 4}
        "X17"           {$ExtendInterval = 3}
        "Xevan"         {$ExtendInterval = 3}
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
        Arguments      = "-q -b $($Port) -a $($_.Algorithm) -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($StaticDiff)$($_.Params)$($CommonCommands) -N $($Average) --submit-stale -d $($DeviceIDs -join ',')"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = $API
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}
