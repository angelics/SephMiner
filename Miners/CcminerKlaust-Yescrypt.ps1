using module ..\Include.psm1

$Path = ".\Bin\NVIDIA-KlausT-Yescrypt\ccminer.exe"
$Uri = "https://1drv.ms/f/s!AoT9lvLcOWd_hX-jrYCKzFFhNNfU"

$Commands = [PSCustomObject]@{
    "yescrypt" = "" #yescrypt
    "yescryptR8" = "" #yescryptR8
    "yescryptR16" = "" #Yenten
    "yescryptR16v2" = "" #PPNP
    "yescryptR24" = "" #yescryptR24
    "yescryptR32" = "" #WAVI
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-a $_ -b 4068 -o $($Pools.(Get-Algorithm $_).Protocol)://$($Pools.(Get-Algorithm $_).Host):$($Pools.(Get-Algorithm $_).Port) -u $($Pools.(Get-Algorithm $_).User) -p $($Pools.(Get-Algorithm $_).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm $_) = $Stats."$($Name)_$(Get-Algorithm $_)_HashRate".Week}
        API = "Ccminer"
        Port = 4068
        URI = $Uri
    }
}
