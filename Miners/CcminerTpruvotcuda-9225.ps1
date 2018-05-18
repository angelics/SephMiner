using module ..\Include.psm1

$Path = ".\Bin\NVIDIA-TPruvotcuda9-225\ccminer.exe"
$Uri = "https://github.com/tpruvot/ccminer/releases/download/2.2.5-tpruvot/ccminer-x86-2.2.5-cuda9.7z"
$Fee = 0

$Commands = [PSCustomObject]@{
    #"bitcore" = "" #Bitcore CcminerTpruvot-224 better
    #"blake2s" = "" #Blake2s CcminerAlexis78-10 better
	#"groestl" = "" #Groestl ccminerklaust better
	#"hmq1725" = "" #hmq1725 ccminertpruvot better
	#"hsr" = "" #Hsr PalginNvidia2e3913c better
    "jha" = "" #Jha
	#"keccakc" = "" #Keccakc
	#"lyra2v2" = " -N 1" #Lyra2RE2 CcminerNanashi-22r2 better
	#"phi" = " -i 23 -N 1" #Phi ccmineralexis78phi better
	"polytimos" = "" #polytimos
	"sha256t" = "" #sha256t
	"skunk" = "" #skunk
	"timetravel" = "" #Timetravel
    #"tribus" = " -i 19.5" #Tribus
	#"x11evo" = "" #X11evo ccmineralexis78 better
	"x12" = "" #X12
	#"x17" = " -N 1" #X17 CcminerEnemy-103 better
	#"x16r" = " -N 3" #X16r
	#"x16s" = " -N 3" #X16s
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