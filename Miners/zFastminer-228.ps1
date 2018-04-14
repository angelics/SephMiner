using module ..\Include.psm1

$Path = ".\Bin\NVIDIA-zFastminer-2285\zFastminer-V2285.exe"
$Uri = "https://file.fm/f/pdt2g5dc"

$Commands = [PSCustomObject]@{
    "lyra2z" = "" #Lyra2h
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-a $_ -o $($Pools.(Get-Algorithm $_).Protocol)://$($Pools.(Get-Algorithm $_).Host):$($Pools.(Get-Algorithm $_).Port) -u $($Pools.(Get-Algorithm $_).User) -p $($Pools.(Get-Algorithm $_).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm $_) = $Stats."$($Name)_$(Get-Algorithm $_)_HashRate".Week * 0.98}
        API = "Ccminer"
        Port = 4068
        URI = $Uri
    }
}