using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "NVIDIA"
if (-not $Devices.$Type) {return} # No NVIDIA mining device present in system

$Path = ".\Bin\NVIDIA-TPruvot-23\ccminer-x64.exe"
$Uri = "https://github.com/tpruvot/ccminer/releases/download/2.3-tpruvot/ccminer-2.3-cuda9.7z"
$Fee = 0

$Commands = [PSCustomObject]@{
    "allium"     = " -i 20" #allium
    "bitcore"     = " -N 3" #bitcore
    #"blake2s"     = "" #Blake2s
    "bmw"         = "" #bmw
    "c11"         = " -N 3" #C11
    "deep"        = "" #deep
    "dmd-gr"      = "" #dmd-gr
    "fresh"       = "" #fresh
    "fugue256"    = "" #fugue256
    "graft"       = "" #graft
    "heavy"       = "" #heavy
    #"hsr"         = " -N 3" #hsr
    "hmq1725"     = " -N 3" #hmq1725
    "jha"         = "" #JHA
    #"keccak"      = " -m 2" #Keccak
    "keccakc"     = "" #keccakc
    "luffa"       = "" #luffa
    "lyra2"       = "" #lyra2
    #"lyra2v2"     = "" #Lyra2RE2
    #"lyra2z"      = "" #Lyra2z
    "monero"      = "" #monero
    "mjollnir"    = "" #mjollnir
    "neoscrypt"   = "" #NeoScrypt
    "penta"       = "" #penta
    "phi"         = " -N 1" #phi
    "phi2"         = "" #phi2
    "polytimos"   = "" #polytimos
    "scrypt-jane" = "" #scrypt-jane
    "s3"          = "" #s3
    "sha256t"     = "" #sha256t
    "skein2"      = "" #Skein2
    "skunk"       = " -N 3" #Skunk
    "sonoa"       = "" #sonoa
    "stellite"    = "" #stellite
    "timetravel"  = " -N 3" #Timetravel
    "tribus"      = " -N 1" #Tribus
	"x11evo"      = " -N 1" #X11evo
    "x12"         = "" #X12
    #"x16r"        = " -N 3" #X16r
    #"x16s"        = " -N 3" #X16s
    "x17"         = " -N 1" #X17
    "whirlpool"   = "" #whirlpool
    "wildkeccak"  = "" #wildkeccak
    "zr5"         = "" #zr5
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    Switch ($Algorithm_Norm) {
        "PHI2"  {$ExtendInterval = 2}
        "X16R"  {$ExtendInterval = 3}
        "X16S"  {$ExtendInterval = 3}
        default {$ExtendInterval = 0}
    }

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type           = $Type
        Path           = $Path
        Arguments      = "-a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_) --submit-stale"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = "Ccminer"
        Port           = 4068
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}
