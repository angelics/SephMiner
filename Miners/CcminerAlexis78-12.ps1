using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-Alexis78-12\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminerAlexis78/releases/download/Alexis78-v1.2/ccminerAlexis78v1.2x64.7z"
$Port = 4068
$Fee = 0

$Commands = [PSCustomObject]@{
    #"blake2s"   = "" #Blake2s not profit
    #"c11"       = " -i 21" #C11 CcminerAlexis78-13
    #"hsr"       = "" #Hsr PalginNvidia-2e3913c
    #"keccak"    = " -m 2 -i 29" #Keccak ExcavatorNvidia-144a
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

$CommonCommands = "" #eg. " -d 0,1,8,9"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    Switch ($Algorithm_Norm) {
        "Lyra2RE2" {$N = 1}
        default    {$ExtendInterval = 3
		$N = 3}
    }

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type           = $Type
        Path           = $Path
        Arguments      = "-q -b $($Port) -a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)$(CommonCommands) -N $($N)"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = "Ccminer"
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}
