using module ..\Include.psm1

$Path = ".\Bin\NVIDIA-Polytimos-2\ccminer.exe"
$URI = "https://github.com/punxsutawneyphil/ccminer/releases/download/polytimosv2/ccminer-polytimos_v2.zip"

$Commands = [PSCustomObject]@{
    "poly" = "" #Polytimos
	"c11" = " -i 21" #C11
	#"nist5" = "" #Nist5 excavator2 better.
	#"lyra2v2" = "" #Lyra2RE2 ccmineralexis78 better
	#"lbry" = "" #Lbry
	#"keccak" = " -m 2 -i 29" #Keccak excavator2 better
	"veltor" = " -i 23" #Veltor
	#"blake2s" = "" #Blake2s excavator2 better
	#"x17" = " -i 21" #X17 ccmineralexis78 better
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