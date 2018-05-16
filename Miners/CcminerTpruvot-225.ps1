using module ..\Include.psm1

$Path = ".\Bin\NVIDIA-TPruvot-225\ccminer-x64.exe"
$Uri = "https://github.com/tpruvot/ccminer/releases/download/2.2.5-tpruvot/ccminer-x64-2.2.5-cuda9.7z"

$Commands = [PSCustomObject]@{
    #"bitcore" = " -N 3" #Bitcore CcminerZEnemy-108 faster
    #"blake2s" = "" #Blake2s excavatornvidia2 better
    "bmw" = "" #bmw
    #"c11" = "" #C11 ccmineralexis78 better
    "deep" = "" #deep
    "dmd-gr" = "" #dmd-gr
    #"equihash" = "" #Equihash bminer better
    "fresh" = "" #fresh
    "fugue256" = "" #fugue256
    "heavy" = "" #heavy
    "hmq1725" = "" #HMQ1725
    "jha" = "" #JHA
    "keccak" = " -m 2" #Keccak
    #"keccakc" = "" #keccakc CcminerTpruvotcuda-9224 better
    "luffa" = "" #luffa
    "lyra2" = "" #lyra2
    "lyra2v2" = "" #Lyra2RE2
    #"lyra2z" = "" #Lyra2z
    "mjollnir" = "" #mjollnir
    #"neoscrypt" = "" #NeoScrypt palginnvidia better
    "penta" = "" #penta
    #"phi" = "" #phi CcminerTpruvotcuda9 better
    #"polytimos" = "" #polytimos ccminerpolytimos better
    "scrypt-jane" = "" #scrypt-jane
    "s3" = "" #s3
    #"sha256t" = "" #sha256t CcminerTpruvotcuda-9224 better
    "skein2" = "" #Skein2
    #"skunk" = "" #Skunk ccminerskunk better
    #"timetravel" = " -i 24.5" #Timetravel
    #"tribus" = "" #Tribus CcminerTpruvotcuda9 better
	#"x11evo" = "" #X11evo ccmineralexis78 better
    "x12" = "" #X12
    #"x16r" = " -N 3" #X16r
    #"x16s" = " -N 3" #X16s
    #"x17" = " -i 20" #X17 ccmineralexis78 better
    "whirlpool" = "" #whirlpool
    "wildkeccak" = "" #wildkeccak
    "zr5" = "" #zr5
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-a $_ -o $($Pools.(Get-Algorithm $_).Protocol)://$($Pools.(Get-Algorithm $_).Host):$($Pools.(Get-Algorithm $_).Port) -u $($Pools.(Get-Algorithm $_).User) -p $($Pools.(Get-Algorithm $_).Pass)$($Commands.$_) --submit-stale"
        HashRates = [PSCustomObject]@{(Get-Algorithm $_) = $Stats."$($Name)_$(Get-Algorithm $_)_HashRate".Week}
        API = "Ccminer"
        Port = 4068
        URI = $Uri
    }
}
