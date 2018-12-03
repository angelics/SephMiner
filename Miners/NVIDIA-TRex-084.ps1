using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-TRex-084\t-rex.exe"
$API  = "Ccminer"
$Uri  = "https://github.com/trexminer/T-Rex/releases/download/0.8.4/t-rex-0.8.4-win-cuda10.0.zip"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee  = 1

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{Algorithm = "balloon"; Params = ""} #balloon
    [PSCustomObject]@{Algorithm = "bcd"; Params = ""; Zpool = ""} #bcd
    [PSCustomObject]@{Algorithm = "bitcore"; Params = ""; Zpool = ""} #bitcore
    #[PSCustomObject]@{Algorithm = "c11"; Params = ""; Zpool = ""} #c11 NVIDIA-ZEnemy-123
    [PSCustomObject]@{Algorithm = "dedal"; Params = ""; Zpool = ""} #dedal
    [PSCustomObject]@{Algorithm = "geek"; Params = ""; Zpool = ""} #geek
    [PSCustomObject]@{Algorithm = "hsr"; Params = ""; Zpool = ""} #hsr
    #[PSCustomObject]@{Algorithm = "hmq1725"; Params = ""; Zpool = ""} #hmq1725 NVIDIA-CryptoDredge-0130
    #[PSCustomObject]@{Algorithm = "lyra2z"; Params = ""; Zpool = ""} #lyra2z NVIDIA-CryptoDredge-095
    [PSCustomObject]@{Algorithm = "polytimos"; Params = ""; Zpool = ""} #polytimos
    [PSCustomObject]@{Algorithm = "phi"; Params = ""; Zpool = ""} #phi
    [PSCustomObject]@{Algorithm = "renesis"; Params = ""} #renesis
    #[PSCustomObject]@{Algorithm = "skunk"; Params = ""; Zpool = ""} #skunk NVIDIA-CryptoDredge-0130
    [PSCustomObject]@{Algorithm = "sha256t"; Params = ""} #sha256t
    [PSCustomObject]@{Algorithm = "sonoa"; Params = ""} #sonoa
    [PSCustomObject]@{Algorithm = "timetravel"; Params = ""} #timetravel
    #[PSCustomObject]@{Algorithm = "tribus"; Params = ""; Zpool = ""} #tribus NVIDIA-ZEnemy-123
    [PSCustomObject]@{Algorithm = "x16r"; Params = ""; Zpool = ""} #x16r
    [PSCustomObject]@{Algorithm = "x16s"; Params = ""; Zpool = ""} #x16s
    [PSCustomObject]@{Algorithm = "x22i"; Params = ""; Zpool = ""} #x22i
    [PSCustomObject]@{Algorithm = "x22s"; Params = ""; Zpool = ""} #x22s
    #[PSCustomObject]@{Algorithm = "x17"; Params = ""; Zpool = ""} #x17 NVIDIA-ZEnemy-123
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
        Arguments      = "-b 127.0.0.1:$($Port) --no-color --quiet -a $($_.Algorithm) -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($StaticDiff)$($_.Params)$($CommonCommands) -d $($DeviceIDs -join ',')"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = $API
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}