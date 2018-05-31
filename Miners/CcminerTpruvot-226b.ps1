using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "NVIDIA"
if (-not $Devices.$Type) {return} # No NVIDIA mining device present in system

$Path = ".\Bin\NVIDIA-TPruvot-226b\ccminer-x64.exe"
$Uri = "https://1drv.ms/f/s!AoT9lvLcOWd_hXaynjg8RU-wpIbA"
$Fee = 0

$Commands = [PSCustomObject]@{
    #"allium"      = "" #Allium CcminerAllium-226
    #"bitcore"     = " -N 3" #Bitcore CcminerDelos-112
    #"blake2s"     = "" #Blake2s ExcavatorNvidia-144a
    "bmw"         = "" #bmw
    #"c11"         = "" #C11
    "deep"        = "" #deep
    "dmd-gr"      = "" #dmd-gr
    #"equihash"    = "" #Equihash
    "fresh"       = "" #fresh
    "fugue256"    = "" #fugue256
    "heavy"       = "" #heavy
    #"hmq1725"     = "" #HMQ1725 CcminerDelos-112
    "jha"         = "" #JHA
    #"keccak"      = " -m 2" #Keccak
    #"keccakc"     = "" #keccakc
    "luffa"       = "" #luffa
    "lyra2"       = "" #lyra2
    #"lyra2v2"     = "" #Lyra2RE2
    #"lyra2z"      = "" #Lyra2z CcminerNanashi-22r2
    "mjollnir"    = "" #mjollnir
    #"neoscrypt"   = "" #NeoScrypt
    "penta"       = "" #penta
    #"phi"         = "" #phi
    "polytimos"   = "" #polytimos
    "scrypt-jane" = "" #scrypt-jane
    "s3"          = "" #s3
    #"sha256t"     = "" #sha256t CcminerTpruvotcuda-9225
    "skein2"      = "" #Skein2
    #"skunk"       = "" #Skunk CcminerDelos-112
    "timetravel"  = "" #Timetravel
    #"tribus"      = "" #Tribus CcminerZEnemy-110s
	#"x11evo"      = "" #X11evo CcminerAlexis78-12
    "x12"         = "" #X12
    #"x16r"        = " -N 3" #X16r
    #"x16s"        = " -N 3" #X16s
    #"x17"         = " -i 20" #X17
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
