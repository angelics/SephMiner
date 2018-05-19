using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "NVIDIA"
if (-not $Devices.$Type) {return} # No NVIDIA mining device present in system

$Threads = 2

$Path = ".\Bin\Excavator-144a\excavator.exe"
$Uri = "https://github.com/nicehash/excavator/releases/"
$Fee = 0

$Commands = [PSCustomObject]@{
    #"blake2s"         = @() #Blake2s alexis78 better
    #"daggerhashimoto" = @() #Ethash
    #"equihash"        = @() #Equihash dstm better
    "keccak"          = @() #keccak
    "lyra2rev2"       = @() #Lyra2RE2 ccmineralexis78 better
    #"neoscrypt"       = @() #NeoScrypt palginnvidia better
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$Port = 3456 + (2 * 10000)

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    try {
        if ((Get-Algorithm $_) -ne "Decred" -and (Get-Algorithm $_) -ne "Sia") {
            if ((Test-Path (Split-Path $Path)) -and $Pools.$(Get-Algorithm $_).Host) {
                [PSCustomObject]@{time = 0; commands = @([PSCustomObject]@{id = 1; method = "algorithm.add"; params = @("$_", "$([Net.DNS]::Resolve($Pools.$(Get-Algorithm $_).Host).AddressList.IPAddressToString | Select-Object -First 1):$($Pools.$(Get-Algorithm $_).Port)", "$($Pools.$(Get-Algorithm $_).User):$($Pools.$(Get-Algorithm $_).Pass)")})},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "0") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "1") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "2") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "3") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "4") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "5") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "6") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "7") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "8") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "9") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "10") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "11") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "12") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "13") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "14") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "15") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "16") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "17") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "18") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "19") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 10; loop = 10; commands = @([PSCustomObject]@{id = 1; method = "algorithm.print.speeds"; params = @("0")})} | ConvertTo-Json -Depth 10 | Set-Content "$(Split-Path $Path)\$($Pools.$(Get-Algorithm $_).Name)_$(Get-Algorithm $_)_$($Pools.$(Get-Algorithm $_).User)_$($Threads)_Nvidia.json" -Force -ErrorAction Stop
            }

                $Algorithm_Norm = Get-Algorithm $_

                $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

                [PSCustomObject]@{
                Type             = $Type
                Path             = $Path
                Arguments        = "-p $Port -c $($Pools.$($Algorithm_Norm).Name)_$($Algorithm_Norm)_$($Pools.$($Algorithm_Norm).User)_$($Threads)_Nvidia.json -na"
                HashRates        = [PSCustomObject]@{$($Algorithm_Norm) = $HashRate}
                API              = "NiceHash"
                Port             = $Port
                URI              = $Uri
                MinerFee         = @($Fee)
                PrerequisitePath = "$env:SystemRoot\System32\msvcr120.dll"
                PrerequisiteURI  = "http://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe"
            }
        }
        else {
            if ((Test-Path (Split-Path $Path)) -and $Pools."$(Get-Algorithm $_)NiceHash".Host) {
                [PSCustomObject]@{time = 0; commands = @([PSCustomObject]@{id = 1; method = "algorithm.add"; params = @("$_", "$([Net.DNS]::Resolve($Pools."$(Get-Algorithm $_)NiceHash".Host).AddressList.IPAddressToString | Select-Object -First 1):$($Pools."$(Get-Algorithm $_)NiceHash".Port)", "$($Pools."$(Get-Algorithm $_)NiceHash".User):$($Pools."$(Get-Algorithm $_)NiceHash".Pass)")})},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "0") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "1") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "2") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "3") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "4") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "5") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "6") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "7") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "8") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "9") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "10") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "11") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "12") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "13") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "14") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "15") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "16") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "17") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "18") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 3; commands = @([PSCustomObject]@{id = 1; method = "worker.add"; params = @("0", "19") + $Commands.$_}) * $Threads},
                [PSCustomObject]@{time = 10; loop = 10; commands = @([PSCustomObject]@{id = 1; method = "algorithm.print.speeds"; params = @("0")})} | ConvertTo-Json -Depth 10 | Set-Content "$(Split-Path $Path)\$($Pools."$(Get-Algorithm $_)NiceHash".Name)_$(Get-Algorithm $_)_$($Pools."$(Get-Algorithm $_)NiceHash".User)_$($Threads)_Nvidia.json" -Force -ErrorAction Stop
            }

                $Algorithm_Norm = Get-Algorithm $_

                $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

                [PSCustomObject]@{
                Type             = $Type
                Path             = $Path
                Arguments        = "-p $Port -c $($Pools."$($Algorithm_Norm)NiceHash".Name)_$($Algorithm_Norm)_$($Pools."$($Algorithm_Norm)NiceHash".User)_$($Threads)_Nvidia.json -na"
                HashRates        = [PSCustomObject]@{"$($Algorithm_Norm)NiceHash" = $HashRate}
                API              = "NiceHash"
                Port             = $Port
                URI              = $Uri
				MinerFee         = @($Fees)
                PrerequisitePath = "$env:SystemRoot\System32\msvcr120.dll"
                PrerequisiteURI  = "http://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe"
            }
        }
    }
    catch {
    }
}