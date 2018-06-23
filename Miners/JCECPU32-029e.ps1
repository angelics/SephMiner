using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Path = ".\Bin\JCE-CPU-029e\jce_cn_cpu_miner32.exe"
$API = "XMRig"
$Uri = "https://github.com/jceminer/cn_cpu_miner/raw/master/jce_cn_cpu_miner.windows.029e.zip"
$Port = 4046
$Fee = 3

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

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_
    
    if ($Pools.$Algorithm_Norm.host -match ".*nicehash\.com") { $Nicehash = "--nicehash"} else { $Nicehash = ""}
	
    $HashRate = ($Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week)
		
    $HashRate = $HashRate * (1 - $Fee / 100)

    [PSCustomObject]@{
        Name      = $Name
        Type      = "CPU"
        Path      = $Path
        Arguments = ("--auto $($Commands.$_ | Select-Object -Index 0) -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_ | Select-Object -Index 1) --low --forever --any --mport 4046 --stakjson $($Nicehash)")
        HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
        API       = $Api
        Port      = $Port
        URI       = $Uri
        MinerFee  = @($Fee)
    }
}