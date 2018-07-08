using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.AMD) {return} # No AMD mining device present in system

$Type = "AMD"
$Path = ".\Bin\AMD-XMRIG-261\xmrig-amd.exe"
$API  = "XMRig"
$Uri  = "https://github.com/xmrig/xmrig-amd/releases/download/v2.6.1/xmrig-amd-2.6.1-win64.zip"
$Port = Get-FreeTcpPort -DefaultPort 3335
$Fee  = 1

$Commands = [PSCustomObject]@{
    "cn"                = "" #CryptoNightV7
    "cryptonight-heavy" = "" #CryptoNightHeavy
}

$CommonCommands = "" #eg. " -d 0,1,8,9"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_
 
    Switch ($Algorithm_Norm) {
        "allium"        {$ExtendInterval = 2}
        "CryptoNightV7" {$ExtendInterval = 2}
        "Lyra2RE2"      {$ExtendInterval = 2}
        "phi"           {$ExtendInterval = 2}
        "phi2"          {$ExtendInterval = 2}
        "tribus"        {$ExtendInterval = 2}
        "X16R"          {$ExtendInterval = 3}
        "X16S"          {$ExtendInterval = 3}
        "X17"           {$ExtendInterval = 2}
        "Xevan"         {$ExtendInterval = 2}
        default         {$ExtendInterval = 0}
    }
 
    if ($Pools.$Algorithm_Norm) { # must have a valid pool to mine

        $HashRate = ($Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week)
		
        $HashRate = $HashRate * (1 - $Fee / 100)

        [PSCustomObject]@{
            Name           = $Name
            Type           = $Type
            Path           = $Path
            Arguments      = "--api-port $($Port) -a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)$($CommonCommands) --keepalive --nicehash --donate-level 1"
            HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
            API            = $Api
            Port           = $Port
            URI            = $Uri
            MinerFee       = @($Fee)
            ExtendInterval = $ExtendInterval
        }
    }
}