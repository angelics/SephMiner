using module ..\Include.psm1

$Path = ".\Bin\NVIDIA-TPruvotcuda9-224\ccminer.exe"
$Uri = "https://github.com/tpruvot/ccminer/releases/download/2.2.4-tpruvot/ccminer-x86-2.2.4-cuda9.7z"

$Commands = [PSCustomObject]@{
    "bitcore" = "" #Bitcore
    "blake2s" = "" #Blake2s
	#"groestl" = "" #Groestl ccminerklaust better
	#"hmq1725" = "" #hmq1725 ccminertpruvot better
	#"hsr" = "" #Hsr PalginNvidia2e3913c better
    "jha" = "" #Jha
	"keccakc" = "" #Keccakc
	"lyra2v2" = " -N 1" #Lyra2RE2
	"nist5" = "" #Nist5
	"phi" = " -i 23 -N 1" #Phi ccmineralexis78phi better
	"polytimos" = "" #polytimos
	"sha256t" = "" #sha256t
	"sib" = "" #Sib
	"skunk" = "" #skunk
	"timetravel" = "" #Timetravel
    "tribus" = "" #Tribus
	#"x11evo" = "" #X11evo ccmineralexis78 better
	"x17" = " -N 1" #X17
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