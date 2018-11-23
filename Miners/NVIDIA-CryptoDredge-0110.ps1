﻿using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-CryptoDredge-0110\CryptoDredge.exe"
$API  = "Ccminer"
$Uri  = "https://github.com/technobyl/CryptoDredge/releases/download/v0.11.0/CryptoDredge_0.11.0_cuda_10.0_windows.zip"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee  = 1

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{Algorithm = "allium"; Params = ""; Zpool = ""} #Allium
    #[PSCustomObject]@{Algorithm = "bcd"; Params = ""; Zpool = ""} #bcd NVIDIA-TRex-080
    #[PSCustomObject]@{Algorithm = "bitcore"; Params = ""; Zpool = ""} #bitcore NVIDIA-TRex-080
    #[PSCustomObject]@{Algorithm = "c11"; Params = ""; Zpool = ""} #c11 NVIDIA-ZEnemy-122
    [PSCustomObject]@{Algorithm = "cnv8"; Params = ""; Zpool = ""} #cnv8
    [PSCustomObject]@{Algorithm = "cnheavy"; Params = ""; Zpool = ""} #cnheavy
    [PSCustomObject]@{Algorithm = "exosis"; Params = ""; Zpool = ""} #exosis
    [PSCustomObject]@{Algorithm = "hmq1725"; Params = ""; Zpool = ""} #hmq1725
    [PSCustomObject]@{Algorithm = "lbk3"; Params = ""; Zpool = ""} #lbk3
    [PSCustomObject]@{Algorithm = "lyra2v2"; Params = ""; Zpool = ""; MiningPoolHubCoins = ""} #Lyra2REv2
    [PSCustomObject]@{Algorithm = "lyra2z"; Params = ""; Zpool = ""} #Lyra2z
    [PSCustomObject]@{Algorithm = "neoscrypt"; Params = ""; Zpool = ""; MiningPoolHubCoins = ""} #NeoScrypt
    [PSCustomObject]@{Algorithm = "phi2"; Params = ""; Zpool = ""} #PHI2
    #[PSCustomObject]@{Algorithm = "phi1612"; Params = ""; Zpool = ""} #PHI1612 NVIDIA-TRex-073
    #[PSCustomObject]@{Algorithm = "polytimos"; Params = ""; Zpool = ""} #polytimos NVIDIA-TRex-073
    #[PSCustomObject]@{Algorithm = "skein"; Params = ""; Zpool = ""; MiningPoolHubCoins = ""} #Skein NVIDIA-Alexis78-12b1
    #[PSCustomObject]@{Algorithm = "skunkhash"; Params = ""; Zpool = ""} #Skunk NVIDIA-TRex-080
    #[PSCustomObject]@{Algorithm = "tribus"; Params = ""; Zpool = ""} #Tribus NVIDIA-ZEnemy-122
    [PSCustomObject]@{Algorithm = "x16r"; Params = ""; Zpool = ""} #x16r
    [PSCustomObject]@{Algorithm = "x16s"; Params = ""; Zpool = ""} #x16s
    [PSCustomObject]@{Algorithm = "x17"; Params = ""; Zpool = ""} #x17
    [PSCustomObject]@{Algorithm = "x22i"; Params = ""; Zpool = ""} #x22i
)

$CommonCommands = " --no-color"

$DeviceIDs = (Get-DeviceIDs -Config $Config -Devices $Devices -Type NVIDIA -DeviceTypeModel $($Devices.NVIDIA) -DeviceIdBase 10 -DeviceIdOffset 0)."$(if ($Type -EQ "NVIDIA"){"All"}else{$Type})"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Where-Object {$Pools.(Get-Algorithm $_.Algorithm).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_.Algorithm
	
    $StaticDiff = $_."$($Pools.$Algorithm_Norm.Name)"
	
    Switch ($Algorithm_Norm) {
        "allium"        {$ExtendInterval = 2}
        "CryptoNightV8" {$ExtendInterval = 2}
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