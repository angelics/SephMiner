using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "CPU"
if (-not ($Devices.$Type -or $Config.InfoOnly)) {return} # No CPU mining device present in system, InfoOnly is for Get-Binaries

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\CryptoNight-CPU-262\xmrig.exe"
$API = "XMRig"
$Uri = "https://github.com/xmrig/xmrig/releases/download/v2.6.2/xmrig-2.6.2-msvc-win64.zip"
$Port = 3335
$Fee = 1
$Commands = [PSCustomObject]@{
    "cn" = "" #CryptoNightV7
    "cn-heavy" = "" #CryptoNight-Heavy
}

$Commands | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_
    
    if ($Pools.$Algorithm_Norm) { # must have a valid pool to mine

        $HashRate = ($Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week)
		
        $HashRate = $HashRate * (1 - $Fee / 100)

        [PSCustomObject]@{
            Name      = $Name
            Type      = $Type
            Path      = $Path
            Arguments = ("--api-port $Port -a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass) --keepalive --nicehash --donate-level 1")
            HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
            API       = $Api
            Port      = $Port
            URI       = $Uri
            MinerFee  = @($Fee)
        }
    }
}