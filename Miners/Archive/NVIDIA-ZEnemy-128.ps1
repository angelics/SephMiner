using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

# Miner requires CUDA 9.2.00 or higher
$CUDAVersion = ($Devices.NVIDIA.Platform.Version | Select-Object -Unique) -replace ".*CUDA ",""
$RequiredCUDAVersion = "9.2.00"
if ($CUDAVersion -and [System.Version]$CUDAVersion -lt [System.Version]$RequiredCUDAVersion) {
    Write-Log -Level Warn "Miner ($($Name)) requires CUDA version $($RequiredCUDAVersion) or above (installed version is $($CUDAVersion)). Please update your Nvidia drivers. "
    return
}

if ($CUDAVersion -lt [System.Version]("10.0.0")) {
    $Uri = "hhttps://github.com/MultiPoolMiner/miner-binaries/releases/download/Zenemy/z-enemy.1-28-cuda9.2.zip"
}
else {
    $Uri = "https://github.com/MultiPoolMiner/miner-binaries/releases/download/Zenemy/z-enemy.1-28-cuda10.0.zip"
}

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-ZEnemy-128\z-enemy.exe"
$API  = "Ccminer"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee  = 1

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{Algorithm = "aeriumx"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #aeriumx
    #[PSCustomObject]@{Algorithm = "bcd"; Params = ""; Zpool = "";} #bcd NVIDIA-TRex-089
    #[PSCustomObject]@{Algorithm = "bitcore"; Params = ""; Zpool = ""} #Bitcore NVIDIA-TRex-088
    [PSCustomObject]@{Algorithm = "hex"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #HEX
    [PSCustomObject]@{Algorithm = "hsr"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #hsr
    #[PSCustomObject]@{Algorithm = "phi"; Params = ""; Zpool = ""} #Phi NVIDIA-TRex-088
    #[PSCustomObject]@{Algorithm = "phi2"; Params = ""; Zpool = ""} #Phi2 NVIDIA-CryptoDredge-0140
    #[PSCustomObject]@{Algorithm = "poly"; Params = ""; Zpool = ""} #poly NVIDIA-TRex-088
    [PSCustomObject]@{Algorithm = "vit"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Vitalium
    #[PSCustomObject]@{Algorithm = "skunk"; Params = ""; Zpool = ""} #skunk NVIDIA-TRex-088
    #[PSCustomObject]@{Algorithm = "sonoa"; Params = ""} #sonoa NVIDIA-TRex-089
    #[PSCustomObject]@{Algorithm = "timetravel"; Params = ""; Zpool = ""} #timetravel NVIDIA-TRex-088
    #[PSCustomObject]@{Algorithm = "tribus"; Params = ""; Zpool = ""} #Tribus NVIDIA-TRex-089
    [PSCustomObject]@{Algorithm = "x16s"; Params = " -i 22"; Zpool = ""} #x16s
    [PSCustomObject]@{Algorithm = "x16r"; Params = " -i 22"; Zpool = ""} #x16r
    #[PSCustomObject]@{Algorithm = "x17"; Params = ""; Zpool = ""} #x17 NVIDIA-TRex-089
    [PSCustomObject]@{Algorithm = "xevan"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #xevan
)

$CommonCommands = "" #eg. " --cpu-affinity=0x3" core0,1

$DeviceIDs = (Get-DeviceIDs -Config $Config -Devices $Devices -Type NVIDIA -DeviceTypeModel $($Devices.NVIDIA) -DeviceIdBase 10 -DeviceIdOffset 0)."$(if ($Type -EQ "NVIDIA"){"All"}else{$Type})"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Where-Object {$Pools.(Get-Algorithm $_.Algorithm).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_.Algorithm

    $StaticDiff = $_."$($Pools.$Algorithm_Norm.Name)"
	
    Switch ($Algorithm_Norm) {
        "allium"        {$ExtendInterval = 2}
        "CryptoNightV7" {$ExtendInterval = 2}
        "dedal"         {$ExtendInterval = 3}
        "hmq1725"       {$ExtendInterval = 2}
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
        Arguments      = "-q -b $($Port) -a $($_.Algorithm) -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($StaticDiff)$($_.Params)$($CommonCommands) -N $($Average) --no-nvml -d $($DeviceIDs -join ',')"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = $API
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}