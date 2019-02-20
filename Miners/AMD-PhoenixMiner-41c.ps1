using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.AMD) {return} # No AMD mining device present in system

$Type = "AMD"
$Path = ".\Bin\PhoenixMiner-41c\PhoenixMiner.exe"
$API  = "Claymore"
$Uri  = "http://semitest.000webhostapp.com/binary/PhoenixMiner_4.1c_Windows.zip"
$Port = Get-FreeTcpPort -DefaultPort 23334
$Fee  = 0.65

$Commands = [PSCustomObject]@{
    "ethash"    = ""
    "ethash2gb" = ""
    "ethash3gb" = ""
}

$CommonCommands = "" #eg. " -d 0,1,8,9"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

# Get array of IDs of all devices in device set, returned DeviceIDs are of base $DeviceIdBase representation starting from $DeviceIdOffset
$DeviceIDsSet = Get-DeviceIDs -Config $Config -Devices $Devices -Type $Type -DeviceTypeModel $($Devices.$Type) -DeviceIdBase 10 -DeviceIdOffset 1

$Commands | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_
    
    Switch ($Algorithm_Norm) { # default is all devices, ethash has a 4GB minimum memory limit
        "Ethash"    {$DeviceIDs = $DeviceIDsSet."4gb"}
        "Ethash2gb" {$DeviceIDs = $DeviceIDsSet."2gb"}
        "Ethash3gb" {$DeviceIDs = $DeviceIDsSet."3gb"}
        default     {$DeviceIDs = $DeviceIDsSet."All"}
    }
	
    if ($Pools.$Algorithm_Norm -and $DeviceIDs) { # must have a valid pool to mine and available devices

        $HashRate = ($Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week)

        $HashRate = $HashRate * (1 - $Fees / 100)

        [PSCustomObject]@{
            Name      = $Name
            Type      = $Type
            Path      = $Path
            Arguments = "-rmode 0 -cdmport $($Port) -cdm 1 -pool $($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -wal $($Pools.$Algorithm_Norm.User) -pass $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)$($CommonCommands) -proto 4 -coin auto -amd -gpus $($DeviceIDs -join ',')"
            HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
            API       = $Api
            Port      = $Port
            URI       = $Uri
            MinerFee  = @($Fee)
        }
    }
}