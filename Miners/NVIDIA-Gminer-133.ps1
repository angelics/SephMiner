using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-Gminer-133\miner.exe"
$API  = "Gminer"
$Uri  = "https://github.com/develsoftware/GMinerRelease/releases/download/1.33/gminer_1_33_minimal_windows64.zip"
$Port = Get-FreeTcpPort -DefaultPort 42000
$Fee  = 2
 
$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{Algorithm = "grin29"; Params = ""} #Cuckaroo29 ~ 5.6GB VRAM
    #[PSCustomObject]@{Algorithm = "grin31"; Params = ""} #Cuckatoo31 ~ 7.4GB VRAM
    #[PSCustomObject]@{Algorithm = "aeternity"; Params = ""} #Cuckoo29 ~ 5.6GB VRAM Aeternity
    [PSCustomObject]@{Algorithm = "Equihash-96_5"; Params = ""} #equihash965 ~0.75GB VRAM
    [PSCustomObject]@{Algorithm = "Equihash-144_5"; Params = ""} #Equihash1445 ~1.75GB VRAM
    [PSCustomObject]@{Algorithm = "Equihash-150_5"; Params = ""} #Equihash1505 ~2.9GB VRAM BEAM
    [PSCustomObject]@{Algorithm = "Equihash-192_7"; Params = ""} #Equihash1927 ~2.75GB VRAM
    [PSCustomObject]@{Algorithm = "Equihash-210_9"; Params = ""} #Equihash2109 ~1GB VRAM
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
        Arguments      = "--algo $Algorithm$Pers --api $($Port) --server $($Pools.$Algorithm_Norm.Host) --port $($Pools.$Algorithm_Norm.Port) --user $($Pools.$Algorithm_Norm.User) --pass $($Pools.$Algorithm_Norm.Pass)$($Commands.$_ | Select-Object -Index 1)$($CommonCommands) --pec 0 --devices $($DeviceIDs -join ' ')"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = $API
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}