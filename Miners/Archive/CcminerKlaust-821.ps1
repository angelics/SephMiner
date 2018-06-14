using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "NVIDIA"
if (-not $Devices.$Type) {return} # No NVIDIA mining device present in system

$Path = ".\Bin\NVIDIA-KlausT-821\ccminer.exe"
$Uri = "https://github.com/KlausT/ccminer/releases/download/8.21/ccminer-821-cuda91-x64.zip"
$Fee = 0

$Commands = [PSCustomObject]@{
    #"c11"        = "" #c11 CcminerPolytimos-2
    #"deep"       = "" #Deepcoin
    #"dmd-gr"     = "" #Diamond-Groestl
    #"fresh"      = "" #Freshcoin
    #"fugue256"   = "" #Fuguecoin
    #"jackpot"    = "" #Jackpot
    #"keccak"     = "" #Keccak ExcavatorNvidia-144a
    #"luffa"      = "" #Doomcoin
    #"lyra2v2"    = "" #VertCoin
    "neoscrypt"  = " --cpu-priority 5" #NeoScrypt
    #"penta"      = "" #Pentablake
    #"s3"         = "" #S3
    #"spread"     = "" #Spread
    #"x17"        = "" #X17
    #"yescrypt"   = "" #yescrypt
    #"whirl"      = "" #Whirlcoin
    #"whirlpoolx" = "" #Vanillacoin
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type      = $Type
        Path      = $Path
        Arguments = "-a $_ -b 4068 -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API       = "Ccminer"
        Port      = 4068
        URI       = $Uri
        MinerFee  = @($Fee)
    }
}
