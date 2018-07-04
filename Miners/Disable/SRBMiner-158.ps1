using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.AMD) {return} # No AMD mining device present in system

$Type = "AMD"
$Path = ".\Bin\AMD-SRBMiner-158\SRBMiner-CN.exe"
$Uri = "https://semitest.000webhostapp.com/binary/SRBMiner-CN-V1-5-8.zip"
$Port = 21555
$API = "SRBMiner"
$Fees = 0.85

# Commands are case sensitive!
$Commands = [PSCustomObject]@{
    # Note: For fine tuning directly edit [AlgorithmName]_config.txt in the miner binary 
    "alloy"           = "" # CryptoNightAlloy
    "artocash"        = "" # CryptoNightArtoCash
    "b2n"             = "" # CryptoNightB2N
    "liteV7"          = "" # CryptoNightLiteV7
    "heavy"           = "" # CryptoNightHeavy
    "ipbc"            = "" # CryptoNightIpbc
    "marketcash"      = "" # CryptoNightMarketCash
    "normalv7"        = "" # CryptoNightV7
    "alloy:2"         = "" # CryptoNightAlloy double threads
    "artocash2"       = "" # CryptoNightArtoCash double threads
    "b2n:2"           = "" # CryptoNightB2N double threads
    "liteV7:2"        = "" # CryptoNightLiteV7 double threads
    "heavy:2"         = "" # CryptoNightHeavy double threads
    "ipbc:2"          = "" # CryptoNightIpbc double threads
    "marketcash:2"    = "" # CryptoNightMarketCash double threads
    "normalv7:2"      = "" # CryptoNightV7
}

$CommonCommands = ""

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

# Get array of IDs of all devices in device set, returned DeviceIDs are of base $DeviceIdBase representation starting from $DeviceIdOffset
$DeviceIDsSet = Get-DeviceIDs -Config $Config -Devices $Devices -Type $Type -DeviceTypeModel $($Devices.$Type) -DeviceIdBase 16 -DeviceIdOffset 0

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.$(Get-Algorithm "cryptonight-$($_ -split(":") | Select-Object -Index 0)")} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm "cryptonight-$($_ -split(":") | Select-Object -Index 0)"
    $Miner_Name = "$Name$($_ -split(":") | Select-Object -Index 1)"
    
    $HashRate = $Stats."$Miner_Name".Week
    $HashRate = $HashRate * (1 - $Fees / 100)
    
    $ConfigFile = "Config-$($_ -replace ":2", "-DoubleThreads").txt"
  
    ([PSCustomObject]@{
            api_enabled      = $true
            api_port         = $Port
            api_rig_name     = "$($Config.Pools.$($Pools.$Algorithm_Norm.Name).Worker)"
            cryptonight_type = ($_ -split(":") | Select-Object -Index 0)
            double_threads   = (($_ -split(":") | Select-Object -Index 1) -eq "2")
        } | ConvertTo-Json -Depth 10
    ) | Set-Content "$(Split-Path $Path)\$($ConfigFile)" -ErrorAction Ignore

    [PSCustomObject]@{
        Name       = $Miner_Name
        Type       = $Type
        Path       = $Path
        Arguments  = "--config $ConfigFile --cpool $($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) --cwallet $($Pools.$Algorithm_Norm.User) --cpassword $($Pools.$Algorithm_Norm.Pass) --ctls $($Pools.$Algorithm_Norm.SSL) --cnicehash $($Pools.$Algorithm_Norm.Name -eq 'NiceHash')$($Command.$_)$($CommonCommands)"
        HashRates  = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API        = $Api
        Port       = $Port
        URI        = $Uri
        MinerFee   = @($Fees)
    }
}