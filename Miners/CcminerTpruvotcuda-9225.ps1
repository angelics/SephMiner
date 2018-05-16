using module ..\Include.psm1

$Path = ".\Bin\NVIDIA-TPruvotcuda9-225\ccminer.exe"
$Uri = "https://github.com/tpruvot/ccminer/releases/download/2.2.5-tpruvot/ccminer-x86-2.2.5-cuda9.7z"

$Commands = [PSCustomObject]@{
    #"bitcore" = "" #Bitcore CcminerTpruvot-224 better
    #"blake2s" = "" #Blake2s CcminerAlexis78-10 better
	#"groestl" = "" #Groestl ccminerklaust better
	#"hmq1725" = "" #hmq1725 ccminertpruvot better
	#"hsr" = "" #Hsr PalginNvidia2e3913c better
    "jha" = "" #Jha
	"keccakc" = "" #Keccakc
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
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-a $_ -o $($Pools.(Get-Algorithm $_).Protocol)://$($Pools.(Get-Algorithm $_).Host):$($Pools.(Get-Algorithm $_).Port) -u $($Pools.(Get-Algorithm $_).User) -p $($Pools.(Get-Algorithm $_).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm $_) = $Stats."$($Name)_$(Get-Algorithm $_)_HashRate".Week}
        API = "Ccminer"
        Port = 4068
        URI = $Uri
    }
}