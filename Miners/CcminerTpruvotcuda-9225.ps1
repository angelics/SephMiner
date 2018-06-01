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
$RequiredVersion = "9.0.00"
if ($DriverVersion -lt $RequiredVersion) {
    Write-Log -Level Warn "Miner ($($Name)) requires CUDA version $($RequiredVersion) or above (installed version is $($DriverVersion)). Please update your Nvidia drivers. "
    return
}

$Path = ".\Bin\NVIDIA-TPruvotcuda9-225\ccminer.exe"
$Uri = "https://github.com/tpruvot/ccminer/releases/download/2.2.5-tpruvot/ccminer-x86-2.2.5-cuda9.7z"
$Fee = 0

$Commands = [PSCustomObject]@{
    #"bitcore"    = " -N 3" #Bitcore CcminerTpruvot-224 better
    #"blake2s"    = "" #Blake2s CcminerAlexis78-10 better
	#"groestl"    = "" #Groestl ccminerklaust better
	#"hmq1725"    = " -N 3" #hmq1725 ccminertpruvot better
	#"hsr"        = " -N 3" #Hsr PalginNvidia2e3913c better
    "jha"        = "" #Jha
	#"keccakc"    = "" #Keccakc
	#"lyra2v2"    = " -N 1" #Lyra2RE2 CcminerNanashi-22r2 better
	#"lyra2z"      = " -N 1" #Lyra2z
	#"phi"        = " -i 23 -N 1" #Phi ccmineralexis78phi better
	"polytimos"  = "" #polytimos
	"sha256t"    = "" #sha256t
	"skunk"      = " -N 5" #skunk
	"timetravel" = " -N 5" #Timetravel
    #"tribus"     = " -i 19.5 -N 1" #Tribus
	#"x11evo"     = "" #X11evo ccmineralexis78 better
	"x12"        = "" #X12
	#"x17"        = " -N 1" #X17 CcminerEnemy-103 better
	#"x16r"       = " -N 3" #X16r
	#"x16s"       = " -N 3" #X16s
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