﻿using module ..\Include.psm1

$Path = ".\Bin\ZEnemy-NVIDIA-109b\z-enemy.exe"
$Uri = "https://mega.nz/#!iLYynQiR!la-zehh3Khsz2EoN5Ayr0vAZIBpmHIpgwokfTssu414"
$Fee = 1

$Commands = [PSCustomObject]@{
    "bitcore" = " -N 3" #Bitcore
    "phi" = " -N 1" #Phi
    "vit" = "" #Vitalium
    "tribus" = "" #Tribus
    "x16s" = " -N 3" #Pigeon
    "x16r" = " -N 3" #Raven
    "x17" = " -N 1" #X17
    "xevan" = "" #Xevan
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API       = "Ccminer"
        Port      = 4068
        URI       = $Uri
        MinerFee  = @($Fee)
    }
}