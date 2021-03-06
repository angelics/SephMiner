﻿using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

$DriverVersion = (Get-Devices).NVIDIA.Platform.Version -replace ".*CUDA ",""
$RequiredVersion = "10.0.132"
if ($DriverVersion -lt $RequiredVersion) {
    Write-Log -Level Warn "Miner ($($Name)) requires CUDA version $($RequiredVersion) or above (installed version is $($DriverVersion)). Please update your Nvidia drivers to 397.93 or newer. "
    return
}

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-ZEnemy-122\z-enemy.exe"
$API  = "Ccminer"
$Uri  = "http://semitest.000webhostapp.com/binary/z-enemy.1-22-cuda10.0_x64.zip"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee  = 1

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{Algorithm = "aeriumx"; Params = ""; Zpool = ""} #aeriumx
    #[PSCustomObject]@{Algorithm = "bcd"; Params = ""; Zpool = "";} #bcd NVIDIA-TRex-070
    #[PSCustomObject]@{Algorithm = "bitcore"; Params = ""; Zpool = ""} #Bitcore NVIDIA-TRex-070
    [PSCustomObject]@{Algorithm = "c11"; Params = ""; Zpool = ""} #c11
    [PSCustomObject]@{Algorithm = "hex"; Params = ""; Zpool = ""} #HEX
    [PSCustomObject]@{Algorithm = "hsr"; Params = ""; Zpool = ""} #hsr
    #[PSCustomObject]@{Algorithm = "phi"; Params = ""; Zpool = ""} #Phi NVIDIA-TRex-070
    #[PSCustomObject]@{Algorithm = "phi2"; Params = ""; Zpool = ""} #Phi2 NVIDIA-CryptoDredge-092
    #[PSCustomObject]@{Algorithm = "poly"; Params = ""; Zpool = ""} #poly NVIDIA-TRex-070 
    [PSCustomObject]@{Algorithm = "vit"; Params = ""; Zpool = ""} #Vitalium
    [PSCustomObject]@{Algorithm = "renesis"; Params = ""} #renesis
    #[PSCustomObject]@{Algorithm = "skunk"; Params = ""; Zpool = ""} #skunk NVIDIA-TRex-070
    [PSCustomObject]@{Algorithm = "sonoa"; Params = ""} #sonoa
    [PSCustomObject]@{Algorithm = "timetravel"; Params = ""; Zpool = ""} #timetravel
    [PSCustomObject]@{Algorithm = "tribus"; Params = ""; Zpool = ""} #Tribus
    [PSCustomObject]@{Algorithm = "x16s"; Params = " -i 21"; Zpool = ""} #x16s
    [PSCustomObject]@{Algorithm = "x16r"; Params = " -i 21"; Zpool = ""} #x16r
    [PSCustomObject]@{Algorithm = "x17"; Params = ""; Zpool = ""} #x17
    [PSCustomObject]@{Algorithm = "xevan"; Params = ""; Zpool = ""} #xevan
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
        Arguments      = "-q -b $($Port) -a $($_.Algorithm) -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($StaticDiff)$($_.Params)$($CommonCommands) -N $($Average) -d $($DeviceIDs -join ',')"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = $API
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}