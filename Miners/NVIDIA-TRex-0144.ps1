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
    $Uri = "https://github.com/trexminer/T-Rex/releases/download/0.14.4/t-rex-0.14.4-win-cuda9.2.zip"
}
else {
    $Uri = "https://github.com/trexminer/T-Rex/releases/download/0.14.4/t-rex-0.14.4-win-cuda10.0.zip"
}

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-TRex-0144\t-rex.exe"
$API  = "Ccminer"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee  = 1

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{Algorithm = "astralhash"; Params = ""; ZergpoolCoins = ""} #astralhash
    [PSCustomObject]@{Algorithm = "balloon"; Params = ""; ZergpoolCoins = ""} #balloon
    [PSCustomObject]@{Algorithm = "bcd"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #bcd
    [PSCustomObject]@{Algorithm = "bitcore"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #bitcore
    [PSCustomObject]@{Algorithm = "c11"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #c11
    [PSCustomObject]@{Algorithm = "dedal"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #dedal
    [PSCustomObject]@{Algorithm = "geek"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #geek
    [PSCustomObject]@{Algorithm = "honeycomb"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #honeycomb
    [PSCustomObject]@{Algorithm = "hsr"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #hsr
    [PSCustomObject]@{Algorithm = "hmq1725"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #hmq1725 NVIDIA-CryptoDredge-0180
    [PSCustomObject]@{Algorithm = "jeonghash"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #jeonghash
    [PSCustomObject]@{Algorithm = "lyra2z"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #lyra2z
    [PSCustomObject]@{Algorithm = "mtp"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #mtp
    [PSCustomObject]@{Algorithm = "padihash"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #padihash
    [PSCustomObject]@{Algorithm = "pawelhash"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #pawelhash
    [PSCustomObject]@{Algorithm = "polytimos"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #polytimos
    [PSCustomObject]@{Algorithm = "phi"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #phi
    [PSCustomObject]@{Algorithm = "renesis"; Params = ""; ZergpoolCoins = ""} #renesis
    [PSCustomObject]@{Algorithm = "skunk"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #skunk
    [PSCustomObject]@{Algorithm = "sha256t"; Params = ""; ZergpoolCoins = ""} #sha256t
    [PSCustomObject]@{Algorithm = "sha256q"; Params = ""; ZergpoolCoins = ""} #sha256q
    [PSCustomObject]@{Algorithm = "sonoa"; Params = ""; ZergpoolCoins = ""} #sonoa
    [PSCustomObject]@{Algorithm = "tensority"; Params = ""; ZergpoolCoins = ""} #tensority
    [PSCustomObject]@{Algorithm = "timetravel"; Params = ""; ZergpoolCoins = ""} #timetravel
    [PSCustomObject]@{Algorithm = "tribus"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #tribus
    [PSCustomObject]@{Algorithm = "x16r"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x16r
    [PSCustomObject]@{Algorithm = "x16rt"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x16rt
    [PSCustomObject]@{Algorithm = "x16rv2"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x16rv2
    [PSCustomObject]@{Algorithm = "x16s"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x16s
    [PSCustomObject]@{Algorithm = "x22i"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x22i
    [PSCustomObject]@{Algorithm = "x22s"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x22s
    [PSCustomObject]@{Algorithm = "x25x"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x25x
    [PSCustomObject]@{Algorithm = "x17"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x17
)

$CommonCommands = " -N 60 --no-watchdog" #eg. " -d 0,1,8,9"

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
        "x16rt"         {$ExtendInterval = 3}
        "x16rv2"        {$ExtendInterval = 3}
        "X16S"          {$ExtendInterval = 3}
        "X17"           {$ExtendInterval = 2}
        "Xevan"         {$ExtendInterval = 2}
        default         {$ExtendInterval = 0}
    }
	
    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type           = $Type
        Path           = $Path
        Arguments      = "-b 127.0.0.1:$($Port) --no-color --quiet -a $($_.Algorithm) -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($StaticDiff)$($_.Params)$($CommonCommands) --no-nvml -d $($DeviceIDs -join ',')"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = $API
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}