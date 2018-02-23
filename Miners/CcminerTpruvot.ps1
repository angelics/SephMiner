using module ..\Include.psm1

$Path = ".\Bin\NVIDIA-TPruvot\ccminer-x64.exe"
$Uri = "https://github.com/tpruvot/ccminer/releases/download/2.2.4-tpruvot/ccminer-x64-2.2.4-cuda9.7z"

$Commands = [PSCustomObject]@{
    "bitcore" = "" #Bitcore
    #"blake2s" = "" #Blake2s excavatornvidia2 better
    #"blakecoin" = "" #Blakecoin ccmineralexis78 better
    "bmw" = "" #bmw
    #"c11" = "" #C11 ccmineralexis78 better
    "cryptonight" = "" #CryptoNight
    "deep" = "" #deep
    "dmd-gr" = "" #dmd-gr
    #"equihash" = "" #Equihash bminer better
    "fresh" = "" #fresh
    "fugue256" = "" #fugue256
    #"groestl" = "" #Groestl ccminerklaust better
    "heavy" = "" #heavy
    "hmq1725" = "" #HMQ1725
    "jha" = "" #JHA
    #"keccak" = "" #Keccak ccminerpolytimos better
    "keccakc" = "" #keccakc
    "luffa" = "" #luffa
    "lyra2" = "" #lyra2
    #"lyra2v2" = "" #Lyra2RE2 excavatornvidia1 better
    #"lyra2z" = "" #Lyra2z
    "mjollnir" = "" #mjollnir
    #"myr-gr" = "" #MyriadGroestl ccminerklaust better.
    #"neoscrypt" = "" #NeoScrypt palginnvidia better
    #"nist5" = "" #Nist5 ccmineralexis78 better
    #"pascal" = "" #Pascal
    "penta" = "" #penta
    #"phi" = "" #phi CcminerTpruvotcuda9 better
    #"polytimos" = "" #polytimos ccminerpolytimos better
    "scrypt-jane" = "" #scrypt-jane
    "s3" = "" #s3
    "sha256t" = "" #sha256t
    #"sib" = "" #Sib ccminersib better
    #"skein" = "" #Skein  ccminerpolytimos better
    "skein2" = "" #Skein2
    #"skunk" = "" #Skunk ccminerskunk better
    #"timetravel" = "" #Timetravel CcminerTpruvotcuda9 better
    #"tribus" = "" #Tribus CcminerTpruvotcuda9 better
	#"x11evo" = "" #X11evo ccmineralexis78 better
    "x15" = "" #X15
    #"x17" = " -i 20" #X17 ccmineralexis78 better
    #"veltor" = "" #Veltor ccmineralexis78 better
    "vanilla" = "" #BlakeVanilla
    "whirlpool" = "" #whirlpool
    "wildkeccak" = "" #wildkeccak
    "zr5" = "" #zr5
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-a $_ -o $($Pools.(Get-Algorithm $_).Protocol)://$($Pools.(Get-Algorithm $_).Host):$($Pools.(Get-Algorithm $_).Port) -u $($Pools.(Get-Algorithm $_).User) -p $($Pools.(Get-Algorithm $_).Pass) --submit-stale$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm $_) = $Stats."$($Name)_$(Get-Algorithm $_)_HashRate".Week}
        API = "Ccminer"
        Port = 4068
        URI = $Uri
    }
}
