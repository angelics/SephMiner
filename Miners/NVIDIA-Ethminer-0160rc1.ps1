using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

$Type = "NVIDIA"
$Path = ".\Bin\Ethash-Ethminer-0160rc1\ethminer.exe"
$API  = "Claymore"
$Uri  = "https://github.com/ethereum-mining/ethminer/releases/download/v0.16.0rc1/ethminer-0.16.0rc1-windows-amd64.zip"
$Port = Get-FreeTcpPort -DefaultPort 23333
$Fee  = 0

$Commands = [PSCustomObject]@{
    "ethash"    = ""
    "ethash2gb" = ""
    "ethash3gb" = ""
}

$CommonCommands = "" #eg. " -d 0,1,8,9"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_
    
	if ($Type -EQ "NVIDIA"){
	    # Get array of IDs of all devices in device set, returned DeviceIDs are of base $DeviceIdBase representation starting from $DeviceIdOffset
	    $DeviceIDsSet = Get-DeviceIDs -Config $Config -Devices $Devices -Type NVIDIA -DeviceTypeModel $($Devices.NVIDIA) -DeviceIdBase 10 -DeviceIdOffset 0
        Switch ($MainAlgorithm_Norm) { # default is all devices, ethash has a 4GB minimum memory limit
            "Ethash"    {$DeviceIDs = $DeviceIDsSet."4gb"}
            "Ethash2gb" {$DeviceIDs = $DeviceIDsSet."2gb"}
            "Ethash3gb" {$DeviceIDs = $DeviceIDsSet."3gb"}
            default     {$DeviceIDs = $DeviceIDsSet."All"}
        }
    }
	else {
        $DeviceIDs = (Get-DeviceIDs -Config $Config -Devices $Devices -Type NVIDIA -DeviceTypeModel $($Devices.NVIDIA) -DeviceIdBase 10 -DeviceIdOffset 0)."$($Type)"
	}
	
    if ($Pools.$Algorithm_Norm -and $DeviceIDs) { # must have a valid pool to mine and available devices

        $HashRate = ($Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week)

        [PSCustomObject]@{
            Name      = $Name
            Type      = $Type
            Path      = $Path
            Arguments = "--api-port $($Port) -P $($Pools.$Algorithm_Norm.Protocol)://$([System.Web.HttpUtility]::UrlEncode($Pools.$Algorithm_Norm.User)):$([System.Web.HttpUtility]::UrlEncode($Pools.$Algorithm_Norm.Pass))@$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port)$($Commands.$_)$($CommonCommands) --cuda --cuda-devices $($DeviceIDs)"
            HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
            API       = $Api
            Port      = $Port
            URI       = $Uri
            MinerFee  = @($Fee)
        }
    }
}