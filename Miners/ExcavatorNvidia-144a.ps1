using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "NVIDIA"
if (-not $Devices.$Type) {return} # No NVIDIA mining device present in system

$Path = ".\Bin\Excavator-144a\excavator.exe"
$Uri = "https://github.com/nicehash/excavator/releases/download/v1.4.4a/excavator_v1.4.4a_NVIDIA_Win64.zip"
$Fee = 0

$Commands = [PSCustomObject]@{
    #"daggerhashimoto:1" = @("","") #Ethash 1 thread commands,difficulty
    #"equihash:1"        = @("","") #Equihash 1 thread
    #"neoscrypt:1"       = @("","") #NeoScrypt 1 thread
    "lyra2rev2:1"       = @("","") #Lyra2RE2 1 thread
    #"blake2s:1"         = @("","") #blake2s 1 thread
    "keccak:1"          = @("","") #keccak 1 thread
    #"daggerhashimoto:2" = @("","") #Ethash 2 threads
    #"equihash:2"        = @("","") #Equihash 2 threads
    #"neoscrypt:2"       = @("","") #NeoScrypt 2 threads
    "lyra2rev2:2"       = @("","") #Lyra2RE2 2 threads
    "keccak:2"          = @("","") #keccak 2 threads
    #"daggerhashimoto:3" = @("","") #Ethash 3 threads
    #"equihash:3"        = @("","") #Equihash 3 threads
    #"neoscrypt:3"       = @("","") #NeoScrypt 3 threads
    "lyra2rev2:3"       = @("","") #Lyra2RE2 3 threads
    "keccak:3"          = @("","") #keccak 3 threads
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$Port = 3456 + (2 * 10000)

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algorithm = $_.Split(":") | Select-Object -Index 0
    $Algorithm_Norm = Get-Algorithm $Algorithm
	
    $CommonCommand = $Commands.$_ | Select -Index 0
    $StaticDiff = $Commands.$_ | Select -Index 1

    $Threads =  $_ -split ":" | Select -Index 1
    $Miner_Name = "$($Name)$($Threads)"
		
            if ($Pools.$Algorithm_Norm.Host) {
                [PSCustomObject]@{time = 0; commands = @([PSCustomObject]@{id = 1; method = "algorithm.add"; params = @("$Algorithm", "$([Net.DNS]::Resolve($Pools.$($Algorithm_Norm).Host).AddressList.IPAddressToString | Select-Object -First 1):$($Pools.$($Algorithm_Norm).Port)", "$($Pools.$($Algorithm_Norm).User):$($Pools.$($Algorithm_Norm).Pass)$($StaticDiff)")})},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "0") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "1") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "2") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "3") * $Threads}) + $CommonCommand_},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "4") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "5") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "6") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "7") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "8") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "9") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "10") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "11") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "12") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "13") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "14") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "15") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "16") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "17") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "18") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "19") * $Threads}) + $CommonCommand},
                [PSCustomObject]@{time = 10; loop = 10; commands = @([PSCustomObject]@{id = 1; method = "algorithm.print.speeds"; params = @("0")})} | ConvertTo-Json -Depth 10 | Set-Content "$(Split-Path $Path)\$($Pools.$($Algorithm_Norm).Name)_$($Algorithm_Norm)_$($Pools.$($Algorithm_Norm).User)_$($Threads)_Nvidia.json" -Force -ErrorAction Stop
            }
                [PSCustomObject]@{
                Name             = $Miner_Name
                Type             = $Type
                Path             = $Path
                Arguments        = "-p $Port -c $($Pools.$($Algorithm_Norm).Name)_$($Algorithm_Norm)_$($Pools.$($Algorithm_Norm).User)_$($Threads)_Nvidia.json -na"
                HashRates        = [PSCustomObject]@{$($Algorithm_Norm) = $Stats."$($Miner_Name)_$($Algorithm_Norm)_HashRate".Week}
                API              = "Excavator"
                Port             = $Port
                URI              = $Uri
                MinerFee         = @($Fee)
                PrerequisitePath = "$env:SystemRoot\System32\msvcr120.dll"
                PrerequisiteURI  = "http://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe"
            }
}