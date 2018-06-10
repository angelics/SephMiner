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
if ($DriverVersion -lt $RequiredVersion) {
    Write-Log -Level Warn "Miner ($($Name)) requires CUDA version $($RequiredVersion) or above (installed version is $($DriverVersion)). Please update your Nvidia drivers to 390.77 or newer. "
    return
}

$Path = ".\Bin\ZEnemy-NVIDIA-111v3\z-enemy.exe"
$Uri = "http://semitest.000webhostapp.com/binary/z-enemy.1-11-public-final_v3.zip"
$Fee = 1

$Commands = [PSCustomObject]@{
    "aeriumx"    = "" #aeriumx
    "bitcore"    = " -N 3" #Bitcore
    "c11"        = " -N 3" #c11
    "phi"        = " -N 1" #Phi
    "poly"       = "" #poly
    "vit"        = "" #Vitalium
    "skunk"      = " -N 3" #skunk
    "timetravel" = " -N 3" #timetravel
    "tribus"     = " -N 1" #Tribus
    "x16s"       = " -i 21 -N 3" #Pigeon
    "x16r"       = " -i 21 -N 3" #Raven
    "x17"        = " -N 1" #X17
    "xevan"      = " -N 1" #Xevan
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type      = $Type
        Path      = $Path
        Arguments = "-a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API       = "Ccminer"
        Port      = 4068
        URI       = $Uri
        MinerFee  = @($Fee)
    }
}