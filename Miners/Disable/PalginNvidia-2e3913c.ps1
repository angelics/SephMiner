using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "NVIDIA"
if (-not $Devices.$Type) {return} # No NVIDIA mining device present in system

$DriverVersion = (Get-Devices).NVIDIA.Platform.Version -replace ".*CUDA ",""
$RequiredVersion = "9.1.00"
if ($DriverVersion -gt $RequiredVersion) {
    Write-Log -Level Warn "Miner ($($Name)) requires CUDA version $($RequiredVersion) or lower (installed version is $($DriverVersion)). Please downgrade your Nvidia drivers to 390.77. "
    return
}

$Path = ".\Bin\HSR-Palgin-2e3913c\hsrminer_hsr.exe"
$API = "Ccminer"
$Uri = "https://github.com/palginpav/hsrminer/raw/master/HSR%20algo/Windows/hsrminer_hsr.exe"
$Port = Get-FreeTcpPort -DefaultPort 4001
$Fee = 1

$Commands = [PSCustomObject]@{
    "Hsr" = "" #Hsr
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    Switch ($Algorithm_Norm) {
        default {$ExtendInterval = 3}
    }
    
    if ($Pools.$Algorithm_Norm) { # must have a valid pool to mine

        $HashRate = ($Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week)
		
        $HashRate = $HashRate * (1 - $Fee / 100)

        [PSCustomObject]@{
            Name           = $Name
            Type           = $Type
            Path           = $Path
            Arguments      = ("-o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)")
            HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
            API            = $Api
            Port           = $Port
            URI            = $Uri
            MinerFee       = @($Fee)
            ExtendInterval = $ExtendInterval
        }
    }
}