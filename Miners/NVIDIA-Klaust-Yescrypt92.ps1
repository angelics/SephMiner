using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

$DriverVersion = (Get-Devices).NVIDIA.Platform.Version -replace ".*CUDA ",""
$RequiredVersion = "9.2.00"
if ($DriverVersion -lt $RequiredVersion) {
    Write-Log -Level Warn "Miner ($($Name)) requires CUDA version $($RequiredVersion) or above (installed version is $($DriverVersion)). Please update your Nvidia drivers to 397.93 or newer. "
    return
}

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-KlausT-Yescrypt\ccminer-x64-cuda9.2.exe"
$API  = "Ccminer"
$Uri  = "https://semitest.000webhostapp.com/binary/CCMiner%20Klaust%20-%20Yescrypt.7z"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee  = 0

$Commands = [PSCustomObject]@{
    "yescrypt"      = "" #yescrypt
    "yescryptR8"    = "" #yescryptR8
    #"yescryptR16"   = "" #Yenten CcminerKlaust-Yescrypt
    "yescryptR16v2" = "" #PPNP
    "yescryptR24"   = "" #yescryptR24
    "yescryptR32"   = "" #WAVI
}

$CommonCommands = "" #eg. " -d 0,1,8,9"

$DeviceIDs = (Get-DeviceIDs -Config $Config -Devices $Devices -Type NVIDIA -DeviceTypeModel $($Devices.NVIDIA) -DeviceIdBase 10 -DeviceIdOffset 0)."$(if ($Type -EQ "NVIDIA"){"All"}else{$Type})"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type      = $Type
        Path      = $Path
        Arguments = "-q -b $($Port) -a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)$($CommonCommands) -d $($DeviceIDs -join ',')"
        HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API       = $API
        Port      = $Port
        URI       = $Uri
        MinerFee  = @($Fee)
    }
}
