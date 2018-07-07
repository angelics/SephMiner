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
$Uri = "https://semitest.000webhostapp.com/binary/ccminerAlexis78v1.2x32.7z"
$Port = 4068
$Fee = 0

$Commands = [PSCustomObject]@{
    #"blake2s"   = "" #Blake2s not profit
    #"c11"       = " -i 21" #C11 CcminerAlexis78-13
    #"hsr"       = "" #Hsr PalginNvidia-2e3913c
    #"keccak"    = " -m 2 -i 29" #Keccak ExcavatorNvidia-144a
    #"keccakc"   = " -i 29" #Keccakc CcminerAlexis78-13
    "lyra2"     = "" #Lyra2
    #"lyra2v2"   = "" #Lyra2RE2 ExcavatorNvidia-144a
    #"neoscrypt" = "" #NeoScrypt PalginNvidiaFork-45ee8fa
    "poly"      = "" #Poly
    "skein"     = "" #skein
    "skein2"    = "" #skein2
    "whirlcoin" = "" #WhirlCoin
    "whirlpool" = "" #Whirlpool
    "x11evo"    = " -i 21" #x11evo
    #"x17"       = " -i 20" #X17 crash
}

$CommonCommands = "" #eg. " -d 0,1,8,9"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    Switch ($Algorithm_Norm) {
        default         {$ExtendInterval = 3}
    }
	
    Switch ($Algorithm_Norm) {
        "Lyra2RE2" {$Average = 1}
        "lyra2z"   {$Average = 1}
        "phi"      {$Average = 1}
        "tribus"   {$Average = 1}
        "Xevan"    {$Average = 1}
        default    {$Average = 3}
    }

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type           = $Type
        Path           = $Path
        Arguments      = "-q -b $($Port) -a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)$($CommonCommands) -N $($Average)"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = "Ccminer"
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}
