using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-TPruvot-23\ccminer-x64.exe"
$Uri = "https://github.com/tpruvot/ccminer/releases/download/2.3-tpruvot/ccminer-2.3-cuda9.7z"
$Port = 4068
$Fee = 0

$Commands = [PSCustomObject]@{
    "allium"     = " -i 21" #allium
    #"bitcore"     = "" #bitcore CcminerZEnemy-111v3
    #"blake2s"     = "" #Blake2s
    "bmw"         = "" #bmw
    #"c11"         = "" #C11 CcminerZEnemy-111v3
    "deep"        = "" #deep
    "dmd-gr"      = "" #dmd-gr
    "fresh"       = "" #fresh
    "fugue256"    = "" #fugue256
    "graft"       = "" #graft
    "heavy"       = "" #heavy
    "hsr"         = "" #hsr
    #"hmq1725"     = " -N 3" #hmq1725 crash
    "jha"         = "" #JHA
    #"keccak"      = " -i 29 -m 2" #Keccak ExcavatorNvidia-144a
    "keccakc"     = " -i 29" #keccakc
    "luffa"       = "" #luffa
    "lyra2"       = "" #lyra2
    #"lyra2v2"     = "" #Lyra2RE2
    #"lyra2z"      = " -i 20" #Lyra2z CcminerOurMiner32-100
    "monero"      = "" #monero
    "mjollnir"    = "" #mjollnir
    #"neoscrypt"   = "" #NeoScrypt PalginNvidiaFork-45ee8fa
    "penta"       = "" #penta
    #"phi"         = "" #phi CcminerZEnemy-111v3
    "phi2"         = "" #phi2
    "polytimos"   = "" #polytimos
    "scrypt-jane" = "" #scrypt-jane
    "s3"          = "" #s3
    #"sha256t"     = " -i 29 -r 0 " #sha256t crash
    "skein2"      = "" #Skein2
    #"skunk"       = "" #Skunk CcminerZEnemy-111v3
    "sonoa"       = "" #sonoa
    "stellite"    = "" #stellite
    #"timetravel"  = "" #Timetravel CcminerZEnemy-111v3
    #"tribus"      = "" #Tribus CcminerZEnemy-111v3
	#"x11evo"      = "" #X11evo CcminerAlexis78-12
    "x12"         = "" #X12
    #"x16r"        = "" #X16r
    #"x16s"        = "" #X16s
    #"x17"         = "" #X17 CcminerZEnemy-111v3
    "whirlpool"   = "" #whirlpool
    "wildkeccak"  = "" #wildkeccak
    "zr5"         = "" #zr5
}

$CommonCommands = "" #eg. " -d 0,1,8,9"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    Switch ($Algorithm_Norm) {
        "allium"        {$ExtendInterval = 2}
        "CryptoNightV7" {$ExtendInterval = 2}
        "Lyra2RE2"      {$ExtendInterval = 2}
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
        Arguments      = "-q -b $($Port) -a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)$($CommonCommands) -N $($Average) --submit-stale"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = "Ccminer"
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}
