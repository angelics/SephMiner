using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "CPU"
$Path = ".\Bin\CPU-JCE-029e\jce_cn_cpu_miner64.exe"
$API  = "XMRig"
$Uri  = "https://github.com/jceminer/cn_cpu_miner/raw/master/jce_cn_cpu_miner.windows.029e.zip"
$Port = Get-FreeTcpPort -DefaultPort 4046
$Fee  = 1.5

$Commands = [PSCustomObject]@{
    "CryptoNightV7"    = @("--variation 3","") #CryptoNightV7 first item is algo number, second for additional miner commands
    "CryptoLightV7"    = @("--variation 4","") #CryptoLightV7
    "CryptoNightHeavy" = @("--variation 5","") #CryptoNightHeavy
    "CryptolightIPBC"  = @("--variation 6","") #CryptolightIPBC
    "CryptonightXTL"   = @("--variation 7","") #CryptonightXTL
    "CryptonightAlloy" = @("--variation 8","") #CryptonightAlloy
    "CryptonightMKT"   = @("--variation 9","") #CryptonightMKT
    "CryptonightArto"  = @("--variation 10","") #CryptonightArto
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
	
    if ($Pools.$Algorithm_Norm.host -match ".*nicehash\.com") { $Nicehash = "--nicehash"} else { $Nicehash = ""}
	
    $HashRate = ($Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week)
		
    $HashRate = $HashRate * (1 - $Fee / 100)

    [PSCustomObject]@{
        Name           = $Name
        Type           = $Type
        Path           = $Path
        Arguments      = "--auto $($Commands.$_ | Select-Object -Index 0) -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_ | Select-Object -Index 1)$($CommonCommands) --low --forever --any --mport $($Port) --stakjson $($Nicehash)"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API            = $Api
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}