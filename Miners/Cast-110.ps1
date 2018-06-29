using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "AMD"
if (-not $Devices.$Type) {return} # No AMD mining device present in system

$Path = ".\Bin\CryptoNight-Cast-110\cast_xmr-vega.exe"
$API = "XMRig"
$Uri = "http://www.gandalph3000.com/download/cast_xmr-vega-win64_110.zip"
$Port = Get-FreeTcpPort -DefaultPort 7777
$Fee = 1.5

$Commands = [PSCustomObject]@{
    "CryptoNightV7"        = @("1","") #CryptoNightV7
    "CryptoNight-Heavy"    = @("2","") #CryptoNightHeavy
    "cryptonight-litev7"   = @("4","") #CryptoNightLitetV7
    "CryptoNightIPBC-Lite" = @("5","") #CryptoNightIPBCLite
}
#For example switch all Polaris based GPUs to Compute Mode:
#switch-radeon-gpu --compute=on autorestart
#To turn HBCC Memory option for all Vega based GPUs to off:
#switch-radeon-gpu --hbcc=off autorestart
#To toggle Large Pages only for the 1st GPU to on:
#switch-radeon-gpu -G 0 --largepages=on restart 
$CommonCommands = "" #

# Get array of IDs of all devices in device set, returned DeviceIDs are of base $DeviceIdBase representation starting from $DeviceIdOffset
$DeviceIDs = (Get-DeviceIDs -Config $Config -Devices $Devices -Type $Type -DeviceTypeModel $($Devices.$Type) -DeviceIdBase 16 -DeviceIdOffset 0)."All"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_
    
    if ($Pools.$Algorithm_Norm) { # must have a valid pool to mine

        $HashRate = ($Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week)
		
        $HashRate = $HashRate * (1 - $Fee / 100)
		
        [PSCustomObject]@{
            Name      = $Name
            Type      = $Type
            Path      = $Path
            Arguments = ("--remoteaccess --remoteport $($Port) --algo=$($Commands.$_ | Select-Object -Index 0) -S $($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_ | Select-Object -Index 1)$($CommonCommands) --fastjobswitch  -G $($DeviceIDs -join ',')")
            HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
            API       = $Api
            Port      = $Port
            URI       = $Uri
            MinerFee  = @($Fee)
        }
    }
}