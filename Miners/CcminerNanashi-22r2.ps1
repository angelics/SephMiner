using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "NVIDIA"
if (-not $Devices.$Type) {return} # No NVIDIA mining device present in system

$Path = ".\Bin\NVIDIA-Nanashi-22r2\ccminer.exe"
$URI = "https://github.com/Nanashi-Meiyo-Meijin/ccminer/releases/download/v2.2-mod-r2/2.2-mod-r2-CUDA9.binary.zip"
$Port = Get-FreeTcpPort -DefaultPort 4068
$Fee = 0

$Commands = [PSCustomObject]@{
    "jha"       = "" #JHA
	"lyra2z"    = " -N 1" #Lyra2z
	#"lyra2v2"   = " -N 1" #Lyra2RE2
    #"neoscrypt" = "" #NeoScrypt palginnvidia better. 1080
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_
	
    if ($Pools.$Algorithm_Norm) {

        $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

        [PSCustomObject]@{
            Type      = $Type
            Path      = $Path
            Arguments = "-b $($Port) -a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)"
            HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
            API       = "Ccminer"
            Port      = $Port
            URI       = $Uri
            MinerFee  = @($Fee)
        }
	}
}