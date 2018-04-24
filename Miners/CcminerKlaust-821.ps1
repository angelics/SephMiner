using module ..\Include.psm1

$Path = ".\Bin\NVIDIA-KlausT-821\ccminer.exe"
$Uri = "https://github.com/KlausT/ccminer/releases/download/8.21/ccminer-821-cuda91-x64.zip"

$Commands = [PSCustomObject]@{
    #"blake" = "" #Blake
    #"c11" = "" #X11 CcminerPolytimos-2 better
    #"deep" = "" #Deepcoin
    #"dmd-gr" = "" #Diamond-Groestl
    #"fresh" = "" #Freshcoin
    #"fugue256" = "" #Fuguecoin
    #"jackpot" = "" #Jackpot
    #"keccak" = "" #Keccak ExcavatorNvidia2-144a better
    #"luffa" = "" #Doomcoin
    "lyra2v2" = "" #VertCoin
    "neoscrypt" = " --cpu-priority 5" #NeoScrypt
    #"penta" = "" #Pentablake
    #"s3" = "" #S3
    #"spread" = "" #Spread
    #"x14" = "" #X14
    "x15" = "" #X15
    #"x17" = "" #X17
    #"yescrypt" = "" #yescrypt
    #"whirl" = "" #Whirlcoin
    #"whirlpoolx" = "" #Vanillacoin
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-a $_ -b 4068 -o $($Pools.(Get-Algorithm $_).Protocol)://$($Pools.(Get-Algorithm $_).Host):$($Pools.(Get-Algorithm $_).Port) -u $($Pools.(Get-Algorithm $_).User) -p $($Pools.(Get-Algorithm $_).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm $_) = $Stats."$($Name)_$(Get-Algorithm $_)_HashRate".Week}
        API = "Ccminer"
        Port = 4068
        URI = $Uri
    }
}
