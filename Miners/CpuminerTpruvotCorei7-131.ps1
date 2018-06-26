using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Path = ".\Bin\CPU-TPruvot-131\cpuminer-gw64-corei7.exe"
$Uri = "https://github.com/tpruvot/cpuminer-multi/releases/download/v1.3.1-multi/cpuminer-multi-rel1.3.1-x64.zip"
$Fee = 0

$Commands = [PSCustomObject]@{
    "blake2s"    = "" #Blake2s
    "c11"        = "" #C11
    "keccak"     = "" #Keccak
    "lyra2rev2"  = "" #Lyra2RE2
    "neoscrypt"  = "" #NeoScrypt
    "skein"      = "" #skein
    "timetravel" = "" #Timetravel
    "x11evo"     = "" #X11evo
    "x17"        = "" #X17
    "xevan"      = "" #Xevan
    "yescrypt"   = "" #Yescrypt
}

$CommonCommands = "" #eg. " --threads=6"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    Switch ($Algorithm_Norm) {
        "X16R"  {$ExtendInterval = 3}
        "X16S"  {$ExtendInterval = 3}
        default {$ExtendInterval = 3}
    }

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type           = "CPU"
        Path           = $Path
        Arguments      = "-a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)$($CommonCommands)"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = "Ccminer"
        Port           = 4068
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}