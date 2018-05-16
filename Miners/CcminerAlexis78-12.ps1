using module ..\Include.psm1

$Path = ".\Bin\NVIDIA-Alexis78-12\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminerAlexis78/releases/download/Alexis78-v1.2/ccminerAlexis78v1.2x64.7z"

$Commands = [PSCustomObject]@{
    "blake2s" = "" #Blake2s
    "c11" = " -i 21" #C11
    #"hsr" = "" #Hsr
    "keccak" = " -m 2 -i 29" #Keccak
    "keccakc" = " -i 29" #Keccakc
    "lyra2" = "" #Lyra2
    "lyra2v2" = " -N 1" #Lyra2RE2
    #"neoscrypt" = "" #NeoScrypt
    "poly" = "" #Poly
    "skein2" = "" #skein2
    "whirlcoin" = "" #WhirlCoin
    "whirlpool" = "" #Whirlpool
    "whirlpoolx" = "" #whirlpoolx
    "x11evo" = " -N 1 -i 21" #x11evo
    #"x17" = " -i 20" #X17
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
