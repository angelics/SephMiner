using module ..\Include.psm1

$Path = ".\Bin\CPU-JayDDee\cpuminer-avx2-sha.exe"
$Uri = "https://github.com/JayDDee/cpuminer-opt/files/1753108/cpuminer-opt-3.8.3.1-windows.zip"

$Commands = [PSCustomObject]@{
    #"allium" = "" #Garlicoin
    #"anime" = "" #Animecoin
    #"argon2" = "" #
    "axiom" = "" #MemoHash
    #"bastion" = "" #
	"bitcore" = "" #Bitcore
    #"blake" = "" #SFR
    "blakecoin" = "" #Blakecoin
    "blake2s" = "" #Blake2s
    #"bmw" = "" #BMW 256
    "c11" = "" #C11
    #"cryptolight" = "" #Cryptonight-light
    #"cryptonight" = "" #CryptoNight fireice better
    #"deep" = "" #Deepcoin
    #"dmd-gr" = "" #Diamond-Groestl
    #"drop" = "" #Dropcoin
    #"fresh" = "" #Fresh
    "groestl" = "" #Groestl
    #"heavy" = "" #Heavy
    "hmq1725" = "" #HMQ1725
    "hodl" = "" #Hodlcoin
    #"jha" = "" #JHA
    "keccak" = "" #Keccak
    "keccakc" = "" #Creative
    #"luffa" = "" #Luffa
    "lyra2h" = "" #Hppcoin
    "lyra2re" = "" #lyra2
    "lyra2rev2" = "" #Vertcoin
    "lyra2z" = "" #Lyra2z
    #"lyra2z330" = "" #ZOI
    "m7m" = "" #Magi
    "myr-gr" = "" #MyriadGroestl
    "neoscrypt" = "" #NeoScrypt
    "nist5" = "" #Nist5
    #"pentablake" = "" #Pentablake
    "phi1612" = "" #phi
    #"pluck" = "" #Supcoin
    "polytimos" = "" #Ninja
    #"scrypt:N" = "" #scrypt(N, 1, 1)
    #"scryptjane:nf" = "" #
    #"sha256d" = "" #DoubleSHA-256
    #"sha256t" = "" #Onecoin
    #"shavite3" = "" #Shavite3
    "skein" = "" #Skein
    #"skein2" = "" #Woodcoin
    "skunk" = "" #Skunk
    "timetravel" = "" #Timetravel
    "tribus" = "" #Tribus
    "vanilla" = "" #BlakeVanilla
    "blake256r8vnl" = "" #VCash
    "veltor" = "" #Veltor
    #"whirlpool" = "" #
    "whirlpoolx" = "" #whirlpoolx
    "x11evo" = "" #X11evo
    "x11gost" = "" #Sib
    #"x12" = "" #Galaxie Cash
    #"x13sm3" = "" #hsr
    "x15" = "" #X15
    "x16r" = "" #Ravencoin
    "x17" = "" #x17
    "xevan" = "" #Bitsend
    "yescrypt" = "" #Globalboost-Y
    #"yescryptr8" = "" #BitZeny
    "yescryptr16" = "" #Yenten
    #"zr5" = "" #Ziftr
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {
    [PSCustomObject]@{
        Type = "CPU"
        Path = $Path
        Arguments = "-a $_ -o $($Pools.(Get-Algorithm $_).Protocol)://$($Pools.(Get-Algorithm $_).Host):$($Pools.(Get-Algorithm $_).Port) -u $($Pools.(Get-Algorithm $_).User) -p $($Pools.(Get-Algorithm $_).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm $_) = $Stats."$($Name)_$(Get-Algorithm $_)_HashRate".Week}
        API = "Ccminer"
        Port = 4048
        URI = $Uri
    }
}
