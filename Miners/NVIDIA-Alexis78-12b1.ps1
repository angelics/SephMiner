using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-Alexis78-12b1\ccminer.exe"
$API  = "Ccminer"
$Uri  = "https://semitest.000webhostapp.com/binary/ccminerAlexis78v1.2b1x32.7z"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee  = 0

$Commands = [PSCustomObject]@{
    #"blake2s"   = "" #Blake2s not profit
    "c11"       = " -i 21" #C11
    "hsr"       = "" #Hsr
    #"keccak"    = " -m 2 -i 29" #Keccak ExcavatorNvidia-144a
    "keccakc"   = " -i 29" #Keccakc
    "lyra2"     = "" #Lyra2
    "lyra2v2"   = "" #Lyra2RE2
    #"neoscrypt" = "" #NeoScrypt PalginNvidiaFork-45ee8fa
    "poly"      = "" #Poly
    "skein"     = "" #skein
    "skein2"    = "" #skein2
    "whirlcoin" = "" #WhirlCoin
    "whirlpool" = "" #Whirlpool
    "x11evo"    = " -i 21" #x11evo
    "x17"       = " -i 20" #X17
}

$CommonCommands = "" #eg. " -d 0,1,8,9"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    Switch ($Algorithm_Norm) {
        "allium"        {$ExtendInterval = 2}
        "CryptoNightV7" {$ExtendInterval = 2}
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
        Arguments      = "-q -b $($Port) -a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)$($CommonCommands) -N $($Average)"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = $API
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}
