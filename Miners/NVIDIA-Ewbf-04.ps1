using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

$DriverVersion = (Get-Devices).NVIDIA.Platform.Version -replace ".*CUDA ",""
$RequiredVersion = "9.1.00"
if ($DriverVersion -lt $RequiredVersion) {
    Write-Log -Level Warn "Miner ($($Name)) requires CUDA version $($RequiredVersion) or above (installed version is $($DriverVersion)). Please update your Nvidia drivers to 390.77 or newer. "
    return
}

$Type = "NVIDIA"
$Path = ".\Bin\NVIDIA-EWBF-04\miner.exe"
$API  = "DSTM"
$Uri  = "http://semitest.000webhostapp.com/binary/EWBF%20Equihash%20miner%20v0.3.zip"
$Port = Get-FreeTcpPort -DefaultPort 42000
$Fee  = 0

$Commands = [PSCustomObject]@{
    "Equihash144" = @("144_5","") #Equihash144
    "equihash192" = @("192_7","") #Equihash192
    "Minexcoin"   = @("96_5","") #Equihash96
}

$Coins = [PSCustomObject]@{
    "BitcoinGold" = "--pers BgoldPoW"
    "BitcoinZ"    = "--pers BitcoinZ"
    "Minexcoin"   = ""
    "Safecoin"    = "--pers Safecoin"
    "Snowgem"     = "--pers sngemPoW"
    "ZelCash"     = "--pers ZelProof"
    "Zero"        = "--pers ZERO_PoW"
    "ZeroCoin"    = "--pers ZERO_PoW"
}

$CommonCommands = ""

$DeviceIDs = (Get-DeviceIDs -Config $Config -Devices $Devices -Type NVIDIA -DeviceTypeModel $($Devices.NVIDIA) -DeviceIdBase 10 -DeviceIdOffset 0)."$(if ($Type -EQ "NVIDIA"){"All"}else{$Type})"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

    [PSCustomObject]@{
        Type           = $Type
        Path           = $Path
        Arguments      = "--algo $($Commands.$_ | Select-Object -Index 0) $($Coins."$($Pools.$Algorithm_Norm.CoinName)") --eexit 1 --api 127.0.0.1:$($Port) --server $($Pools.$Algorithm_Norm.Host) --port $($Pools.$Algorithm_Norm.Port) --user $($Pools.$Algorithm_Norm.User) --pass $($Pools.$Algorithm_Norm.Pass)$($Commands.$_ | Select-Object -Index 1)$($CommonCommands) --fee 0 --log 1 --cuda_devices $($DeviceIDs)"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = $API
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}