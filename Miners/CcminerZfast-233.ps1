using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "NVIDIA"
if ($Devices.$Type.count -lt 2) {
	Write-Log -Level Warn "Miner ($($Name)) requires 2 NVIDIA mining device present in system"
	return
} 

$DriverVersion = (Get-Devices).NVIDIA.Platform.Version -replace ".*CUDA ",""
$RequiredVersion = "9.2.00"
if ($DriverVersion -lt $RequiredVersion) {
    Write-Log -Level Warn "Miner ($($Name)) requires CUDA version $($RequiredVersion) or above (installed version is $($DriverVersion)). Please update your Nvidia drivers to 397.93 or newer. "
    return
}

$Path = ".\Bin\zFast-NVIDIA-233\zFastminer-v233.exe"
$Uri = "https://semitest.000webhostapp.com/binary/zFastminer-v233.zip"
$Fee = 1.8

$Commands = [PSCustomObject]@{
    "lyra2z" = " -N 1" #Lyra2z
}

#avaiable only for GTX 1060, 1070, 1070 TI, 1080, 1080 TI
# Get array of IDs of all devices in device set, returned DeviceIDs are of base $DeviceIdBase representation starting from $DeviceIdOffset
$DeviceIDs = (Get-DeviceIDs -Config $Config -Devices $Devices -Type $Type -DeviceTypeModel $($Devices.$Type) -DeviceIdBase 10 -DeviceIdOffset 0)."1060"
$DeviceIDs += (Get-DeviceIDs -Config $Config -Devices $Devices -Type $Type -DeviceTypeModel $($Devices.$Type) -DeviceIdBase 10 -DeviceIdOffset 0)."1070"
$DeviceIDs += (Get-DeviceIDs -Config $Config -Devices $Devices -Type $Type -DeviceTypeModel $($Devices.$Type) -DeviceIdBase 10 -DeviceIdOffset 0)."1070ti"
$DeviceIDs += (Get-DeviceIDs -Config $Config -Devices $Devices -Type $Type -DeviceTypeModel $($Devices.$Type) -DeviceIdBase 10 -DeviceIdOffset 0)."1080"
$DeviceIDs += (Get-DeviceIDs -Config $Config -Devices $Devices -Type $Type -DeviceTypeModel $($Devices.$Type) -DeviceIdBase 10 -DeviceIdOffset 0)."1080ti"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    if ($Pools.$Algorithm_Norm.host -match ".*miningpoolhub\.com") {
	
        $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

        [PSCustomObject]@{
            Type      = $Type
            Path      = $Path
            Arguments = "-a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_) -d $($DeviceIDs -join ',')"
            HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
            API       = "Ccminer"
            Port      = 4068
            URI       = $Uri
            MinerFee  = @($Fee)
        }
    }
}