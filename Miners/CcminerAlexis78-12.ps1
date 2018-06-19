using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "NVIDIA"
if (-not $Devices.$Type) {return} # No NVIDIA mining device present in system

$Path = ".\Bin\NVIDIA-Alexis78-12\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminerAlexis78/releases/download/Alexis78-v1.2/ccminerAlexis78v1.2x64.7z"
$Fee = 0

$Commands = [PSCustomObject]@{
    #"blake2s"   = "" #Blake2s not profit
    #"c11"       = " -i 21" #C11 CcminerAlexis78-13
    #"hsr"       = "" #Hsr PalginNvidia-2e3913c
    #"keccak"    = " -m 2 -i 29" #Keccak CcminerAlexis78-13
    #"keccakc"   = " -i 29" #Keccakc CcminerAlexis78-13
    "lyra2"     = "" #Lyra2
    #"lyra2v2"   = " -N 1" #Lyra2RE2 ExcavatorNvidia-144a
    #"neoscrypt" = "" #NeoScrypt PalginNvidiaFork-45ee8fa
    "poly"      = "" #Poly
    "skein"     = "" #skein
    "skein2"    = "" #skein2
    "whirlcoin" = "" #WhirlCoin
    "whirlpool" = "" #Whirlpool
    "x11evo"    = " -N 1 -i 21" #x11evo
    #"x17"       = " -i 20" #X17 crash
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type      = $Type
        Path      = $Path
        Arguments = "-a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API       = "Ccminer"
        Port      = 4068
        URI       = $Uri
        MinerFee  = @($Fee)
    }
}
