﻿using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

# Miner requires CUDA 9.2 or higher
$CUDAVersion = ($Devices.NVIDIA.Platform.Version | Select-Object -Unique) -replace ".*CUDA ",""
$RequiredCUDAVersion = "9.2.00"
if ($CUDAVersion -and [System.Version]$CUDAVersion -lt [System.Version]$RequiredCUDAVersion) {
    Write-Log -Level Warn "Miner ($($Name)) requires CUDA version $($RequiredCUDAVersion) or above (installed version is $($CUDAVersion)). Please update your Nvidia drivers. "
    return
}

if ($CUDAVersion -lt [System.Version]("10.0.0")) {
    $Uri = "https://github.com/technobyl/CryptoDredge/releases/download/v0.18.0/CryptoDredge_0.18.0_cuda_9.2_windows.zip"
}
else {
    $Uri = "https://github.com/technobyl/CryptoDredge/releases/download/v0.18.0/CryptoDredge_0.18.0_cuda_10.0_windows.zip"
}

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-CryptoDredge-0180\CryptoDredge.exe"
$API  = "Ccminer"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee  = 1

$Commands = [PSCustomObject[]]@(
    #[PSCustomObject]@{Algorithm = "allium"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Allium NVIDIA-CryptoDredge-0160
    [PSCustomObject]@{Algorithm = "Argon2d"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Argon2d
    #[PSCustomObject]@{Algorithm = "bcd"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #bcd
    #[PSCustomObject]@{Algorithm = "bitcore"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #bitcore NVIDIA-TRex-092
    #[PSCustomObject]@{Algorithm = "cnv8"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #cnv8 NVIDIA-CryptoDredge-0160
    [PSCustomObject]@{Algorithm = "cnheavy"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #cnheavy
    [PSCustomObject]@{Algorithm = "Cuckaroo29"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Cuckaroo29
    [PSCustomObject]@{Algorithm = "CuckooCycle"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #aeternity
    [PSCustomObject]@{Algorithm = "dedal"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #dedal
    [PSCustomObject]@{Algorithm = "hmq1725"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #hmq1725
    [PSCustomObject]@{Algorithm = "Lyra2REv3"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Lyra2REv3
    [PSCustomObject]@{Algorithm = "lyra2vc0ban"; Params = ""; Zpool = ""; MiningPoolHubCoins = ""; ZergpoolCoins = ""} #Lyra2vc0banHash
    [PSCustomObject]@{Algorithm = "lyra2z"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Lyra2z
    [PSCustomObject]@{Algorithm = "Lyra2zz"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Lyra2zz
    [PSCustomObject]@{Algorithm = "mtp"; Params = ""; Zpool = ""; MiningPoolHubCoins = ""; ZergpoolCoins = ""; fee=2} #mtp ~ 5GB VRAM
    [PSCustomObject]@{Algorithm = "neoscrypt"; Params = ""; Zpool = ""; MiningPoolHubCoins = ""; ZergpoolCoins = ""} #NeoScrypt
    #[PSCustomObject]@{Algorithm = "phi2"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #PHI2 NVIDIA-CryptoDredge-0190
    #[PSCustomObject]@{Algorithm = "phi1612"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #PHI1612 NVIDIA-TRex-092
    [PSCustomObject]@{Algorithm = "pipe"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #pipe
    #[PSCustomObject]@{Algorithm = "skunkhash"; Params = ""; Zpool = ""} #Skunk error on zpool NVIDIA-TRex-092
    [PSCustomObject]@{Algorithm = "tribus"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Tribus
    [PSCustomObject]@{Algorithm = "x16r"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x16r
    #[PSCustomObject]@{Algorithm = "x16rt"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x16rt NVIDIA-TRex-092
    #[PSCustomObject]@{Algorithm = "x16s"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x16s NVIDIA-TRex-092
    #[PSCustomObject]@{Algorithm = "x17"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x17 NVIDIA-TRex-092
    [PSCustomObject]@{Algorithm = "x21s"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x21s
    #[PSCustomObject]@{Algorithm = "x22i"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x22i NVIDIA-TRex-092
)

$CommonCommands = " --no-color"

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
        "X16S"          {$ExtendInterval = 3}
        "X17"           {$ExtendInterval = 2}
        "Xevan"         {$ExtendInterval = 2}
        default         {$ExtendInterval = 0}
    }
	
    if ($_.fee){$Fee = $_.fee}
	
    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type           = $Type
        Path           = $Path
        Arguments      = "--api-type ccminer-tcp --api-bind 127.0.0.1:$($Port) -a $($_.Algorithm) -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($StaticDiff)$($_.Params)$($CommonCommands) -d $($DeviceIDs -join ',')"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = $API
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}