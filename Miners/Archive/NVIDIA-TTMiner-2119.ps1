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

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-TTMiner-2119\TT-Miner.exe"
$API  = "Claymore"
$Uri  = "https://tradeproject.de/download/Miner/TT-Miner-2.1.19.zip"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee  = 1

if ($CUDAVersion -ge [System.Version]("10.1.105")) {
    $Commands = [PSCustomObject[]]@(
        [PSCustomObject]@{Algorithm = "ETHASH2gb-101"; Params = ""} #Ethash2GB algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "ETHASH3gb-101"; Params = ""} #Ethash3GB algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "ETHASH-101"; Params = ""} #Ethash algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "LYRA2V3-101"; Params = ""} #LYRA2V3 algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "MTP-101"; Params = ""} #MTP algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "MTPNICEHASH-101"; Params = ""} #MTP algo for CUDA 10.0; TempFix: NiceHash only
        [PSCustomObject]@{Algorithm = "MYRGR-101"; Params = ""} #Myriad-Groestl algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "UBQHASH-101"; Params = ""} #Ubqhash algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "PROGPOW2gb-101"; Params = ""} #ProgPoW2gb algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "PROGPOW3gb-101"; Params = ""} #ProgPoW3gb algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "PROGPOW-101"; Params = ""} #ProgPoW algo for CUDA 10.0
    )
}
elseif ($CUDAVersion -ge [System.Version]("10.0.130")) {
    $Commands = [PSCustomObject[]]@(
        [PSCustomObject]@{Algorithm = "ETHASH2gb-100"; Params = ""} #Ethash2GB algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "ETHASH3gb-100"; Params = ""} #Ethash3GB algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "ETHASH-100"; Params = ""} #Ethash algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "LYRA2V3-100"; Params = ""} #LYRA2V3 algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "MTP-100"; Params = ""} #MTP algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "MTPNICEHASH-100"; Params = ""} #MTP algo for CUDA 10.0; TempFix: NiceHash only
        [PSCustomObject]@{Algorithm = "MYRGR-100"; Params = ""} #Myriad-Groestl algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "UBQHASH-100"; Params = ""} #Ubqhash algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "PROGPOW2gb-100";Params = ""} #ProgPoW2gb algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "PROGPOW3gb-100"; Params = ""} #ProgPoW3gb algo for CUDA 10.0
        [PSCustomObject]@{Algorithm = "PROGPOW-100"; Params = ""} #ProgPoW algo for CUDA 10.0
    )
}
elseif ($CUDAVersion -ge [System.Version]("9.2.148")) {
    $Commands = [PSCustomObject[]]@(
        [PSCustomObject]@{Algorithm = "ETHASH2gb-92"; Params = ""} #Ethash2GB algo for CUDA 9.2
        [PSCustomObject]@{Algorithm = "ETHASH3gb-92"; Params = ""} #Ethash3GB algo for CUDA 9.2
        [PSCustomObject]@{Algorithm = "ETHASH-92"; Params = ""} #Ethash algo for CUDA 9.2
        [PSCustomObject]@{Algorithm = "LYRA2V3-92"; Params = ""} #LYRA2V3 algo for CUDA 9.2 NVIDIA-CryptoDredge-0180
        [PSCustomObject]@{Algorithm = "MTP-92"; Params = ""} #MTP algo for CUDA 9.2
        [PSCustomObject]@{Algorithm = "MTPNICEHASH-92"; Params = ""} #MTP algo for CUDA 9.2; TempFix: NiceHash only
        [PSCustomObject]@{Algorithm = "MYRGR-92"; Params = ""} #Myriad-Groestl algo for CUDA 9.2
        [PSCustomObject]@{Algorithm = "UBQHASH-92"; Params = ""} #Ubqhash algo for CUDA 9.2
        [PSCustomObject]@{Algorithm = "PROGPOW2gb-92"; Params = ""} #ProgPoW2gb algo for CUDA 9.2
        [PSCustomObject]@{Algorithm = "PROGPOW3gb-92"; Params = ""} #ProgPoW3gb algo for CUDA 9.2
        [PSCustomObject]@{Algorithm = "PROGPOW-92"; Params = ""} #ProgPoW algo for CUDA 9.2
    )
}

$CommonCommands = " -RH"

# Get array of IDs of all devices in device set, returned DeviceIDs are of base $DeviceIdBase representation starting from $DeviceIdOffset
$DeviceIDs = (Get-DeviceIDs -Config $Config -Devices $Devices -Type NVIDIA -DeviceTypeModel $($Devices.NVIDIA) -DeviceIdBase 10 -DeviceIdOffset 0)."$(if ($Type -EQ "NVIDIA"){"All"}else{$Type})"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | ForEach-Object {$Algorithm_Norm = Get-Algorithm ($_.Algorithm -split '-' | Select-Object -Index 0); $_} | Where-Object {$Pools.$Algorithm_Norm.Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm = $_.Algorithm -replace 'NiceHash'<#TempFix#> -replace "ETHASH(\dgb)", "ETHASH" -replace "PROGPOW(\dgb)", "PROGPOW"
	
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
	
    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)
	
    [PSCustomObject]@{
        Type           = $Type
        Path           = $Path
        Arguments      = ("--api-bind 127.0.0.1:$($Port) -A $Algorithm -P $($Pools.$Algorithm_Norm.User):$($Pools.$Algorithm_Norm.Pass)@$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port)$($_.Params)$($CommonCommands) --nvidia -PRS 25 -PRT 24 -d $($DeviceIDs -join ' ')" -replace "\s+", " ").trim()
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = $API
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}