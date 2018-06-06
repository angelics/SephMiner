using module ..\Include.psm1

$Path = ".\Bin\ZEnemy-NVIDIA-108\z-enemy.exe"
$Uri = "https://mega.nz/#!7D53kQjL!tV1vUsFdBIDqCzBrcMoXVR2G9YHD6xqct5QB2nBiuzM"

$Commands = [PSCustomObject]@{
    "bitcore" = " -N 3" #Bitcore
    "phi" = " -N 1" #Phi
    "x16s" = " -N 3" #Pigeon
    "x16r" = " -N 3" #Raven
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-a $_ -o $($Pools.(Get-Algorithm $_).Protocol)://$($Pools.(Get-Algorithm $_).Host):$($Pools.(Get-Algorithm $_).Port) -u $($Pools.(Get-Algorithm $_).User) -p $($Pools.(Get-Algorithm $_).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm $_) = $Stats."$($Name)_$(Get-Algorithm $_)_HashRate".Week * 0.99}
        API = "Ccminer"
        Port = 4068
        URI = $Uri
    }
}