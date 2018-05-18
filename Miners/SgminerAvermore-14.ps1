using module ..\Include.psm1

$Path = ".\Bin\AMD-avermore-14\sgminer.exe"
$Uri = "https://github.com/brian112358/avermore-miner/releases/download/v1.4/avermore-v1.4-windows.zip"
$Fee = 1

$Commands = [PSCustomObject]@{
    "bmw" = "" #bmw
    "echo" = "" #echo
    "Hamsi" = "" #Hamsi
    "Keccak" = "" #Keccak
    "whirlpool" = "" #whirlpool
    "x16s" = "" #x16s
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type = "AMD"
        Path = $Path
        Arguments = "--api-listen -k $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_) --gpu-platform $([array]::IndexOf(([OpenCl.Platform]::GetPlatformIDs() | Select-Object -ExpandProperty Vendor), 'Advanced Micro Devices, Inc.'))"
        HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API = "Xgminer"
        Port = 4028
        URI = $Uri
        MinerFee  = @($Fee)
    }
}