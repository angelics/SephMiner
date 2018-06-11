using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "NVIDIA"
if (-not $Devices.$Type) {return} # No NVIDIA mining device present in system

$Path = ".\Bin\NVIDIA-TPruvot-226\ccminer-x64.exe"
$Uri = "https://github.com/tpruvot/ccminer/releases/download/2.2.6-tpruvot/ccminer-x64-2.2.6-phi2-cuda9.7z"
$Fee = 0

$Commands = [PSCustomObject]@{
    "allium"     = "" #allium
    "bitcore"     = " -N 3"
    #"blake2s"     = "" #Blake2s
    "bmw"         = "" #bmw
    "c11"         = "" #C11
    "deep"        = "" #deep
    "dmd-gr"      = "" #dmd-gr
    #"equihash"    = "" #Equihash
    "fresh"       = "" #fresh
    "fugue256"    = "" #fugue256
    "heavy"       = "" #heavy
    #"hmq1725"     = " -N 3" #hmq1725 crash
    "jha"         = "" #JHA
    #"keccak"      = " -m 2" #Keccak
    "keccakc"     = "" #keccakc
    "luffa"       = "" #luffa
    "lyra2"       = "" #lyra2
    #"lyra2v2"     = "" #Lyra2RE2
    #"lyra2z"      = "" #Lyra2z
    "mjollnir"    = "" #mjollnir
    "neoscrypt"   = "" #NeoScrypt
    "penta"       = "" #penta
    "phi"         = "" #phi
    "phi2"         = "" #phi2
    "polytimos"   = "" #polytimos
    "scrypt-jane" = "" #scrypt-jane
    "s3"          = "" #s3
    "sha256t"     = "" #sha256t
    "skein2"      = "" #Skein2
    "skunk"       = "" #Skunk
    "timetravel"  = "" #Timetravel
    "tribus"      = "" #Tribus
	"x11evo"      = "" #X11evo
    "x12"         = "" #X12
    #"x16r"        = " -N 3" #X16r
    #"x16s"        = " -N 3" #X16s
    "x17"         = "" #X17
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
