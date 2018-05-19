using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Path = ".\Bin\CPU-TPruvot-133\cpuminer-gw64-corei7.exe"
$Uri = "https://github.com/tpruvot/cpuminer-multi/archive/v1.3.3-multi.zip"
$Fee = 0

$Commands = [PSCustomObject]@{
    "blake2s"    = "" #Blake2s
    "bitcore"    = "" #bitcore
    "c11"        = "" #C11
    "jha"        = "" #jha
    "keccak"     = "" #Keccak
    "keccakc"    = "" #Keccakc
    "lyra2rev2"  = "" #Lyra2RE2
    "neoscrypt"  = "" #NeoScrypt
    "timetravel" = "" #Timetravel
    "x11evo"     = "" #X11evo
    "x16r"       = "" #x16r
    "x17"        = "" #X17
    "xevan"      = "" #Xevan
    "yescrypt"   = "" #Yescrypt
}

$CommonCommands = "" #eg. " --threads=6"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type      = "CPU"
        Path      = $Path
        Arguments = "-a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)$($CommonCommands)"
        HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API       = "Ccminer"
        Port      = 4068
        URI       = $Uri
        MinerFee  = @($Fee)
    }
}