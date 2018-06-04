using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "NVIDIA"
if (-not $Devices.$Type) {return} # No NVIDIA mining device present in system

$Path = ".\Bin\NVIDIA-TPruvot-225\ccminer-x64.exe"
$Uri = "https://github.com/tpruvot/ccminer/releases/download/2.2.5-tpruvot/ccminer-x64-2.2.5-cuda9.7z"
$Fee = 0

$Commands = [PSCustomObject]@{
    #"bitcore"     = " -N 3" #Bitcore CcminerZEnemy-110s
    #"blake2s"     = "" #Blake2s ExcavatorNvidia-144a
    "bmw"         = "" #bmw
    #"c11"         = "" #C11 CcminerAlexis78-12
    "deep"        = "" #deep
    "dmd-gr"      = "" #dmd-gr
    #"equihash"    = "" #Equihash bminer better
    "fresh"       = "" #fresh
    "fugue256"    = "" #fugue256
    "heavy"       = "" #heavy
    "hmq1725"     = " -N 3" #HMQ1725 CcminerDelos-112
    "jha"         = "" #JHA
    #"keccak"      = " -m 2" #Keccak
    #"keccakc"     = "" #keccakc CcminerTpruvotcuda-9225
    "luffa"       = "" #luffa
    "lyra2"       = "" #lyra2
    #"lyra2v2"     = "" #Lyra2RE2
    #"lyra2z"      = "" #Lyra2z
    "mjollnir"    = "" #mjollnir
    #"neoscrypt"   = "" #NeoScrypt PalginNvidiaFork-45ee8fa
    "penta"       = "" #penta
    #"phi"         = "" #phi CcminerTpruvotcuda-9225
    #"polytimos"   = "" #polytimos ccminerpolytimos better
    "scrypt-jane" = "" #scrypt-jane
    "s3"          = "" #s3
    #"sha256t"     = "" #sha256t CcminerTpruvotcuda-9225
    "skein2"      = "" #Skein2
    #"skunk"       = "" #Skunk ccminerskunk better
    #"timetravel"  = " -i 24.5" #Timetravel
    #"tribus"      = "" #Tribus CcminerTpruvotcuda-9225
	#"x11evo"      = "" #X11evo CcminerAlexis78-12
    "x12"         = "" #X12
    #"x16r"        = " -N 3" #X16r
    #"x16s"        = " -N 3" #X16s
    #"x17"         = " -i 20" #X17 CcminerAlexis78-12
    "whirlpool"   = "" #whirlpool
    "wildkeccak"  = "" #wildkeccak
    "zr5"         = "" #zr5
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type      = $Type
        Path      = $Path
        Arguments = "-a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_) --submit-stale"
        HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API       = "Ccminer"
        Port      = 4068
        URI       = $Uri
        MinerFee  = @($Fee)
    }
}
