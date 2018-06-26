using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Path = ".\Bin\CPU-JayDDee-3881\cpuminer-aes-sse42.exe"
$Uri = "https://github.com/JayDDee/cpuminer-opt/files/1996977/cpuminer-opt-3.8.8.1-windows.zip"
$Fee = 0

$Commands = [PSCustomObject]@{
    "allium"        = "" #Garlicoin
    #"anime"         = "" #Animecoin
    #"argon2"        = "" #
    #"argon2d250"    = "" #CRDS
    #"argon2d500"    = "" #DYN
    #"argon2d4096"   = "" #UIS
    "axiom"         = "" #MemoHash
    #"bastion"       = "" #
	"bitcore"       = "" #Bitcore
    "blake2s"       = "" #Blake2s
    #"bmw"           = "" #BMW 256
    "c11"           = "" #C11
    "cryptonightv7" = "" #CryptoNightV7
    #"deep"          = "" #Deepcoin
    #"dmd-gr"        = "" #DiamondGroestl
    #"drop"          = "" #Dropcoin
    #"fresh"         = "" #Fresh
    #"heavy"         = "" #Heavy
    "hmq1725"       = "" #HMQ1725
    "hodl"          = "" #Hodlcoin
    "jha"           = "" #JHA
    "keccak"        = "" #Keccak
    "keccakc"       = "" #Creative
    #"luffa"         = "" #Luffa
    "lyra2h"        = "" #Hppcoin
    "lyra2re"       = "" #lyra2
    "lyra2rev2"     = "" #Vertcoin
    "lyra2z"        = "" #Lyra2z
    #"lyra2z330"     = "" #ZOI
    "m7m"           = "" #Magi
    "neoscrypt"     = "" #NeoScrypt
    #"pentablake"    = "" #Pentablake
    "phi1612"       = "" #phi
    #"pluck"         = "" #Supcoin
    "polytimos"     = "" #Ninja
    #"scrypt:N"      = "" #scrypt(N, 1, 1)
    #"scryptjane:nf" = "" #
    #"sha256d"       = "" #DoubleSHA256
    "sha256t"       = "" #sha256t
    #"shavite3"      = "" #Shavite3
    "skein"         = "" #skein
    #"skein2"        = "" #Woodcoin
    "skunk"         = "" #Skunk
    "timetravel"    = "" #Timetravel
    "tribus"        = "" #Tribus
    #"whirlpool"     = "" #
    "whirlpoolx"    = "" #whirlpoolx
    "x11evo"        = "" #X11evo
    "x12"           = "" #GCH
    "x13sm3"        = "" #hsr
    "x16r"          = "" #x16r
    "x16s"          = "" #x16s
    "x17"           = "" #x17
    "xevan"         = "" #Bitsend
    "yescrypt"      = "" #GlobalboostY
    #"yescryptr8"    = "" #BitZeny
    "yescryptr16"   = "" #Yenten
    "yescryptr32"   = "" #WAVI
    #"zr5"           = "" #Ziftr
}

$CommonCommands = "" #eg. " --threads=6"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    Switch ($Algorithm_Norm) {
        "X16R"  {$ExtendInterval = 3}
        "X16S"  {$ExtendInterval = 3}
        default {$ExtendInterval = 3}
    }

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type           = "CPU"
        Path           = $Path
        Arguments      = "-a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)$($CommonCommands)"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = "Ccminer"
        Port           = 4068
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}