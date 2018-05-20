using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "AMD"
if (-not $Devices.$Type) {return} # No AMD mining device present in system

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\CryptoNight-Cast-100\cast_xmr-vega.exe"
$API = "XMRig"
$Uri = "http://www.gandalph3000.com/download/cast_xmr-vega-win64_100.zip"
$Port = 7777
$Fee = 1.5

$Commands = [PSCustomObject]@{
    "CryptoNight"          = "" #CryptoNight
    "CryptoNightV7"        = "" #CryptoNightV7
    "CryptoNight-Heavy"    = "" #CryptoNight-Heavy
    "CryptoNightLite"      = "" #CryptoNightLite
    "cryptonight-litev7"   = "" #CryptoNightLitetV7
    "CryptoNightIPBC-Lite" = "" #CryptoNightIPBC-Lite
}

$Commands | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_
    
    if ($Pools.$Algorithm_Norm) { # must have a valid pool to mine

        $HashRate = ($Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week)
		
        $HashRate = $HashRate * (1 - $Fee / 100)

		#temp fix
		switch ($Algorithm_Norm) {
            "CryptoNight"          {$algo=0}
            "CryptoNightV7"        {$algo=1}
            "CryptoNight-Heavy"    {$algo=2}
            "CryptoNightLite"      {$algo=3}
            "CryptoNightLitetV7"   {$algo=4}
            "CryptoNightIPBC-Lite" {$algo=5}
		}
		
        [PSCustomObject]@{
            Name      = $Name
            Type      = $Type
            Path      = $Path
            Arguments = ("--remoteaccess --algo=$algo -S $($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass) --forcecompute --fastjobswitch  -G $($DeviceIDs -join ',')")
            HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
            API       = $Api
            Port      = $Port
            URI       = $Uri
            MinerFee  = @($Fee)
        }
    }
}