using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)
$Type = "AMD"
if (-not $Devices.$Type) {return} # No AMD mining device present in system

$Path = ".\Bin\AMD-KL-105\sgminer.exe"
$Uri = "https://github.com/KL0nLutiy/sgminer-kl/releases/download/kl-1.0.5/sgminer-kl-1.0.5-windows.zip"
$Fee = 1

$Commands = [PSCustomObject]@{
    "aergo" = " -X 256 -g 2" #aergo
    "phi"   = " -X 256 -w 256 -g 2" #phi
    "x16r"  = " -X 256 -g 2 --intensity 18" #Raven increase 19,21
    "x16s"  = " -X 256 -g 2" #x16s
    "x17"   = " -X 256 -g 2" #x17
    "xevan" = " -X 256 -g 2" #Xevan
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    Switch ($Algorithm_Norm) {
        "X16R"  {$ExtendInterval = 3}
        "X16S"  {$ExtendInterval = 3}
        default {$ExtendInterval = 0}
    }

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type           = $Type
        Path           = $Path
        Arguments      = "--api-listen -k $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_) --gpu-platform $([array]::IndexOf(([OpenCl.Platform]::GetPlatformIDs() | Select-Object -ExpandProperty Vendor), 'Advanced Micro Devices, Inc.'))"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = "Xgminer"
        Port           = 4028
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}