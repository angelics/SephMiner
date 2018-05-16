using module ..\Include.psm1

$Path = ".\Bin\CPU-TPruvot-131\cpuminer-gw64-core2.exe"
$Uri = "https://github.com/tpruvot/cpuminer-multi/releases/download/v1.3.1-multi/cpuminer-multi-rel1.3.1-x64.zip"

$Commands = [PSCustomObject]@{
    "blake2s" = "" #Blake2s
    "c11" = "" #C11
    "keccak" = "" #Keccak
	"lyra2rev2" = "" #Lyra2RE2
    "neoscrypt" = "" #NeoScrypt
    "timetravel" = "" #Timetravel
    "x11evo" = "" #X11evo
    "x17" = "" #X17
	"xevan" = "" #Xevan
    "yescrypt" = "" #Yescrypt
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    [PSCustomObject]@{
        Type = "CPU"
        Path = $Path
        Arguments = "-a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{$Algorithm_Norm = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week}
        API = "Ccminer"
        Port = 4048
        URI = $Uri
    }
}