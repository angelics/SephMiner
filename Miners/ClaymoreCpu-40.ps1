using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Path = ".\Bin\CryptoNight-Claymore-Cpu-40\NsCpuCNMiner64.exe"
$API = "Claymore"
$Uri = "https://mega.co.nz/#F!Hg4g1bLT!4Upg8GNiEZYCaZ04XVh_yg"
$Port = 3333
$Fee = 0

$Commands = [PSCustomObject]@{
    "CryptoNight"          = @("0","") #CryptoNight, first item is algo number, second for additional miner commands
    "CryptoNightV7"        = @("1","") #CryptoNightV7
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_
    
    if ($Pools.$Algorithm_Norm) { # must have a valid pool to mine

        $HashRate = ($Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week)
		
        $HashRate = $HashRate * (1 - $Fee / 100)

        [PSCustomObject]@{
            Name      = "CPU"
            Type      = $Type
            Path      = $Path
            Arguments = ("-r -1 -mport -$Port -pow7 $($Commands.$_ | Select-Object -Index 0) -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_ | Select-Object -Index 1)\")
            HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
            API       = $Api
            Port      = $Port
            URI       = $Uri
            MinerFee  = @($Fee)
        }
    }
}