using module ..\Include.psm1

$Path = ".\Bin\NVIDIA-TPruvotcuda9-224\ccminer.exe"
$Uri = "https://github.com/tpruvot/ccminer/releases/download/2.2.4-tpruvot/ccminer-x86-2.2.4-cuda9.7z"

$Commands = [PSCustomObject]@{
    "phi" = " -i 23" #Phi ccmineralexis78phi better
    "jha" = "" #Jha
    #"hmq1725" = "" #hmq1725 ccminertpruvot better
    #"lyra2z" = "" #Lyra2z ccminertpruvot better
    "timetravel" = "" #Timetravel
    "tribus" = "" #Tribus
	#"groestl" = "" #Groestl ccminerklaust better
	#"x11evo" = "" #X11evo ccmineralexis78 better
	"skunk" = "" #skunk
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