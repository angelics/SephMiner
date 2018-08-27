using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

$DriverVersion = (Get-Devices).NVIDIA.Platform.Version -replace ".*CUDA ",""
$RequiredVersion = "9.1.00"
if ($DriverVersion -lt $RequiredVersion) {
    Write-Log -Level Warn "Miner ($($Name)) requires CUDA version $($RequiredVersion) or above (installed version is $($DriverVersion)). Please update your Nvidia drivers to 390.77 or newer. "
    return
}

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-TRex-061\t-rex.exe"
$API  = "Ccminer"
$Uri  = "http://semitest.000webhostapp.com/binary/t-rex-0.5.7-win-cuda9.1.zip"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee  = 1

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{Algorithm = "bitcore"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #bitcore
    [PSCustomObject]@{Algorithm = "c11"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #c11
    [PSCustomObject]@{Algorithm = "hsr"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #hsr
    #[PSCustomObject]@{Algorithm = "lyra2z"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #lyra2z NVIDIA-CryptoDredge-080
    [PSCustomObject]@{Algorithm = "phi"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #phi
    [PSCustomObject]@{Algorithm = "renesis"; Params = ""} #renesis
    [PSCustomObject]@{Algorithm = "sonoa"; Params = ""} #sonoa
    [PSCustomObject]@{Algorithm = "tribus"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #tribus
    [PSCustomObject]@{Algorithm = "x16r"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x16r
    [PSCustomObject]@{Algorithm = "x16s"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x16s
    [PSCustomObject]@{Algorithm = "x17"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x17
)

$CommonCommands = " -N 60" #eg. " -d 0,1,8,9"

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
	
    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type           = $Type
        Path           = $Path
        Arguments      = "-b 127.0.0.1:$($Port) -a $($_.Algorithm) -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($StaticDiff)$($_.Params)$($CommonCommands) -d $($DeviceIDs -join ',')"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = $API
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}