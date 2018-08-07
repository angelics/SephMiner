using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "CPU"
$Path = ".\Bin\CPU-JayDDee-3881\cpuminer-avx2.exe"
$API  = "Ccminer"
$Uri  = "https://github.com/JayDDee/cpuminer-opt/files/1996977/cpuminer-opt-3.8.8.1-windows.zip"
$Port = Get-FreeTcpPort -DefaultPort 4048
$Fee  = 0

$Commands = [PSCustomObject]@{
    "allium"        = "" #Garlicoin
    #"anime"         = "" #Animecoin
    #"argon2"        = "" #
    #"argon2d250"    = "" #CRDS
    #"argon2d500"    = "" #DYN
    #"argon2d4096"   = "" #UIS
    "axiom"         = "" #MemoHash
    #"bastion"       = "" #
	#"bitcore"       = "" #Bitcore not profitable
    #"blake2s"       = "" #Blake2s not profitable
    #"bmw"           = "" #BMW 256
    #"c11"           = "" #C11 not profitable
    #"cryptonightv7" = "" #CryptoNightV7 CPU-JCE64-031a
    #"deep"          = "" #Deepcoin
    #"dmd-gr"        = "" #DiamondGroestl
    #"drop"          = "" #Dropcoin
    #"fresh"         = "" #Fresh
    #"heavy"         = "" #Heavy
    #"hmq1725"       = "" #HMQ1725 not profitable
    #"hodl"          = "" #Hodlcoin
    "jha"           = "" #JHA
    #"keccak"        = "" #Keccak not profitable
    #"keccakc"       = "" #Creative not profitable
    #"luffa"         = "" #Luffa
    "lyra2h"        = "" #Hppcoin
    #"lyra2re"       = "" #lyra2 not profitable
    #"lyra2rev2"     = "" #Vertcoin not profitable
    "lyra2z"        = "" #Lyra2z
    #"lyra2z330"     = "" #ZOI
    #"m7m"           = "" #Magi
    #"neoscrypt"     = "" #NeoScrypt crash
    #"pentablake"    = "" #Pentablake
    #"phi1612"       = "" #phi not profitable
    #"pluck"         = "" #Supcoin
    "polytimos"     = "" #Ninja
    #"scrypt:N"      = "" #scrypt(N, 1, 1)
    #"scryptjane:nf" = "" #
    #"sha256d"       = "" #DoubleSHA256
    #"sha256t"       = "" #sha256t not profitable
    #"shavite3"      = "" #Shavite3
    #"skein"         = "" #skein not profitable
    #"skein2"        = "" #Woodcoin
    #"skunk"         = "" #Skunk not profitable
    #"timetravel"    = "" #Timetravel not profitable
    #"tribus"        = "" #Tribus not profitable
    #"whirlpool"     = "" #
    "whirlpoolx"    = "" #whirlpoolx
    #"x11evo"        = "" #X11evo not profitable
    "x12"           = "" #GCH
    #"x13sm3"        = "" #hsr not profitable
    #"x16r"          = "" #x16r not profitable
    #"x16s"          = "" #x16s not profitable
    #"x17"           = "" #x17 not profitable
    #"xevan"         = "" #Bitsend not profitable
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

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type           = $Type
        Path           = $Path
        Arguments      = "-q -b $($Port) -a $_ --cpu-affinity AAAA -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)$($CommonCommands)"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = $API
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}