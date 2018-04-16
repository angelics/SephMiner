using module ..\Include.psm1

$Path = ".\Bin\AMD-x17-01\sgminer.exe"
$Uri = "https://mega.nz/#!vnJ0UCaL!8bcpqNl8tP-uzvRg9C042ArmaGJXzrlhfVVXgkDgqY0"

$Commands = [PSCustomObject]@{
    "x17" = " --gpu-threads 2 --worksize 256 --intensity 21" #x17
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {
    [PSCustomObject]@{
        Type = "AMD"
        Path = $Path
        Arguments = "--api-listen -k $_ -o $($Pools.(Get-Algorithm $_).Protocol)://$($Pools.(Get-Algorithm $_).Host):$($Pools.(Get-Algorithm $_).Port) -u $($Pools.(Get-Algorithm $_).User) -p $($Pools.(Get-Algorithm $_).Pass)$($Commands.$_) --text-only --gpu-platform $([array]::IndexOf(([OpenCl.Platform]::GetPlatformIDs() | Select-Object -ExpandProperty Vendor), 'Advanced Micro Devices, Inc.'))"
        HashRates = [PSCustomObject]@{(Get-Algorithm $_) = $Stats."$($Name)_$(Get-Algorithm $_)_HashRate".Week * 0.98}
        API = "Xgminer"
        Port = 4028
        URI = $Uri
    }
}