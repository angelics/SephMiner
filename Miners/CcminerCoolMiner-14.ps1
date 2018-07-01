﻿using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "NVIDIA"
if (-not $Devices.$Type) {return} # No NVIDIA mining device present in system

$DriverVersion = (Get-Devices).NVIDIA.Platform.Version -replace ".*CUDA ",""
$RequiredVersion = "9.2.00"
if ($DriverVersion -lt $RequiredVersion) {
    Write-Log -Level Warn "Miner ($($Name)) requires CUDA version $($RequiredVersion) or above (installed version is $($DriverVersion)). Please update your Nvidia drivers to 397.93 or newer. "
    return
}

$Path = ".\Bin\CoolMiner-NVIDIA-14\coolMiner-x64.exe"
$Uri = "http://semitest.000webhostapp.com/binary/coolMiner-x64-v1-4.zip"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee = 1

$Commands = [PSCustomObject]@{
    "lyra2z" = " -N 1" #Lyra2z
}

$CommonCommands = "" #eg. " -d 0,1,8,9"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    if ($Pools.$Algorithm_Norm) {
	
        $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

        [PSCustomObject]@{
            Type      = $Type
            Path      = $Path
            Arguments = "-q -b $($Port) -a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)"
            HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
            API       = "Ccminer"
            Port      = $Port
            URI       = $Uri
            MinerFee  = @($Fee)
        }
    }
}