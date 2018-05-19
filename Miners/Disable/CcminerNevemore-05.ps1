using module ..\Include.psm1

$Path = ".\Bin\NVIDIA-Nevermore-05\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminerx16r-x16s/releases/download/v0.5/ccminerx16rx16s64-bit.7z"
$Fee = 0

$Commands = [PSCustomObject]@{
    "x16r" = " -i 21 -N 3" #Raven
    "x16s" = " -N 3" #Pigeon
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
        MinerFee = @(Fee)
    }
}