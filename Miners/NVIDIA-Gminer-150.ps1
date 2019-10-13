using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

# Miner requires CUDA 9.1 or higher
$CUDAVersion = ($Devices.NVIDIA.Platform.Version | Select-Object -Unique) -replace ".*CUDA ",""
$RequiredCUDAVersion = "9.1.00"
if ($CUDAVersion -and [System.Version]$CUDAVersion -lt [System.Version]$RequiredCUDAVersion) {
    Write-Log -Level Warn "Miner ($($Name)) requires CUDA version $($RequiredCUDAVersion) or above (installed version is $($CUDAVersion)). Please update your Nvidia drivers. "
    return
}

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-Gminer-150\miner.exe"
$API  = "Gminer"
$Uri  = "https://github.com/develsoftware/GMinerRelease/releases/download/1.50/gminer_1_50_windows64.zip"
$Port = Get-FreeTcpPort -DefaultPort 42000
$Fee  = 2
 
$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{Algorithm = "grin29"; Params = ""} #Cuckaroo29 ~ 4/6GB VRAM
    [PSCustomObject]@{Algorithm = "grin31"; Params = ""} #Cuckatoo31 ~ 7.4GB VRAM
    [PSCustomObject]@{Algorithm = "aeternity"; Params = ""} #Cuckoo29 ~ 4/6 VRAM Aeternity
    [PSCustomObject]@{Algorithm = "Equihash-96_5"; Params = ""} #equihash965 ~0.75GB VRAM NVIDIA-Gminer-136
    [PSCustomObject]@{Algorithm = "Equihash-125_4"; Params = ""} #Equihash1254 ~1GB VRAM
    [PSCustomObject]@{Algorithm = "Equihash-144_5"; Params = ""} #Equihash1445 ~1.75GB VRAM
    [PSCustomObject]@{Algorithm = "Equihash-150_5"; Params = ""} #Equihash1505 ~3GB VRAM BEAM
    [PSCustomObject]@{Algorithm = "Equihash-192_7"; Params = ""} #Equihash1927 ~3GB VRAM
    [PSCustomObject]@{Algorithm = "Equihash-210_9"; Params = ""} #Equihash2109 ~1GB VRAM
    [PSCustomObject]@{Algorithm = "swap"; Params = ""} #cuckaroo29s ~4/6GB VRAM
    [PSCustomObject]@{Algorithm = "vds"; Params = ""} #V-Dimension 1 VRAM
)

$CommonCommands = " --watchdog 0"

$DeviceIDs = (Get-DeviceIDs -Config $Config -Devices $Devices -Type NVIDIA -DeviceTypeModel $($Devices.NVIDIA) -DeviceIdBase 10 -DeviceIdOffset 0)."$(if ($Type -EQ "NVIDIA"){"All"}else{$Type})"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Where-Object {$Pools.(Get-Algorithm $_.Algorithm).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_.Algorithm
    $Algorithm = ($_.Algorithm) -replace "Equihash-"

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    if ($Algorithm_Norm -match "Equihash1445|Equihash1927|equihash965") {
        #define --pers for Equihash1445 & Equihash1927 & equihash965
        $Pers = " --pers auto"
    }
    else {$Pers = ""}
	
    [PSCustomObject]@{
        Type           = $Type
        Path           = $Path
        Arguments      = "--algo $Algorithm$Pers --api $($Port) --server $($Pools.$Algorithm_Norm.Host) --port $($Pools.$Algorithm_Norm.Port) --user $($Pools.$Algorithm_Norm.User) --pass $($Pools.$Algorithm_Norm.Pass)$($Commands.$_ | Select-Object -Index 1)$($CommonCommands) --pec 0 --opencl 0 --devices $($DeviceIDs -join ' ')"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = $API
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}