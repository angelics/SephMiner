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
$Path = ".\Bin\NVIDIA-ZEnemy-121\z-enemy.exe"
$API  = "Ccminer"
$Uri  = "http://semitest.000webhostapp.com/binary/z-enemy.1-21-cuda9.2_x32.zip"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee  = 1

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{Algorithm = "aeriumx"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #aeriumx
    [PSCustomObject]@{Algorithm = "bcd"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #bcd
    [PSCustomObject]@{Algorithm = "bitcore"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Bitcore
    [PSCustomObject]@{Algorithm = "c11"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #c11
    [PSCustomObject]@{Algorithm = "hex"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #HEX
    [PSCustomObject]@{Algorithm = "hsr"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #hsr
    #[PSCustomObject]@{Algorithm = "phi"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Phi NVIDIA-TRex-066
    #[PSCustomObject]@{Algorithm = "phi2"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Phi2 NVIDIA-CryptoDredge-091
    [PSCustomObject]@{Algorithm = "poly"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #poly
    [PSCustomObject]@{Algorithm = "vit"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Vitalium
    [PSCustomObject]@{Algorithm = "renesis"; Params = ""} #renesis
    #[PSCustomObject]@{Algorithm = "skunk"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #skunk NVIDIA-TRex-066
    #[PSCustomObject]@{Algorithm = "sonoa"; Params = ""} #sonoa NVIDIA-TRex-066
    [PSCustomObject]@{Algorithm = "timetravel"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #timetravel
    #[PSCustomObject]@{Algorithm = "tribus"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #Tribus NVIDIA-CryptoDredge-091
    [PSCustomObject]@{Algorithm = "x16s"; Params = " -i 21"; Zpool = ""; ZergpoolCoins = ""} #x16s
    [PSCustomObject]@{Algorithm = "x16r"; Params = " -i 21"; Zpool = ""; ZergpoolCoins = ""} #x16r
    #[PSCustomObject]@{Algorithm = "x17"; Params = ""; Zpool = ""; ZergpoolCoins = ""} #x17 NVIDIA-TRex-0610
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