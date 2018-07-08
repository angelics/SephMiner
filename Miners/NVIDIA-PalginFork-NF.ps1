using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

$Type = "NVIDIA"
$Path = ".\Bin\\NVIDIA-Palginfork-NF\\hsrminer_neoscrypt_fork_hp.exe"
$Uri  = "https://mega.nz/#!6GZ2xRYY!Xw9drYz3q7YTr0G1_DsWhWml96YwqdxyL_Ynm9_jMGg"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee  = 0

$Commands = [PSCustomObject]@{
    "neoscrypt" = "" #NeoScrypt
}

$CommonCommands = "" #eg. " -d 0,1,8,9"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    Switch ($Algorithm_Norm) {
        default {$ExtendInterval = 3}
    }

    [PSCustomObject]@{
        Type           = $Type
        Path           = $Path
        Arguments      = "--api-bind=$($Port) -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)$($CommonCommands)"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week}
        API            = "Ccminer"
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}
