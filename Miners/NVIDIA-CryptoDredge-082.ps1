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
$Path = ".\Bin\NVIDIA-CryptoDredge-082\CryptoDredge.exe"
$API  = "Ccminer"
$Uri  = "http://semitest.000webhostapp.com/binary/CryptoDredge_0.8.2_win_x64.zip"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee  = 1

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{Algorithm = "allium"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Allium
    [PSCustomObject]@{Algorithm = "lyra2v2"; Params = ""; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #Lyra2REv2
    [PSCustomObject]@{Algorithm = "lyra2z"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Lyra2z
    [PSCustomObject]@{Algorithm = "neoscrypt"; Params = ""; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #NeoScrypt
    [PSCustomObject]@{Algorithm = "phi2"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #PHI2
    #[PSCustomObject]@{Algorithm = "phi1612"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #PHI1612 NVIDIA-TRex-051
    #[PSCustomObject]@{Algorithm = "skein"; Params = ""; Zpool = ""; ZergpoolCoins = ""; MiningPoolHubCoins = ""} #Skein NVIDIA-Alexis78-12b1
    [PSCustomObject]@{Algorithm = "skunkhash"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Skunk
    [PSCustomObject]@{Algorithm = "tribus"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Tribus
)

$CommonCommands = " --no-color"

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