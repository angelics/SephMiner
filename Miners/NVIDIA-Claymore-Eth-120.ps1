using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

$Type = "NVIDIA"
$Path = ".\Bin\Claymore-Eth-120\EthDcrMiner64.exe"
$API  = "Claymore"
$Uri  = "http://semitest.000webhostapp.com/binary/Claymore's%20Dual%20Ethereum+Decred_Siacoin_Lbry_Pascal_Blake2s_Keccak%20AMD+NVIDIA%20GPU%20Miner%20v12.0.zip"
$Port = Get-FreeTcpPort -DefaultPort 23333
$Fee  = 1

$Commands = [PSCustomObject]@{
    "ethash"                = @("")
    "ethash2gb"             = @("")
    "ethash3gb"             = @("")
    "ethash;blake2s:105"    = @("", "")
    "ethash;blake2s:130"    = @("", "")
    "ethash;blake2s:155"    = @("", "")
    "ethash;blake2s:180"    = @("", "")
    "ethash;blake2s:205"    = @("", "")
    "ethash;blake2s:230"    = @("", "")
    "ethash;keccak:5"       = @("", "")
    "ethash;keccak:30"      = @("", "")
    "ethash;keccak:50"      = @("", "")
    "ethash;keccak:70"      = @("", "")
    "ethash2gb;blake2s:55"  = @("", "")
    "ethash2gb;blake2s:80"  = @("", "")
    "ethash2gb;blake2s:105" = @("", "")
    "ethash2gb;blake2s:130" = @("", "")
    "ethash2gb;blake2s:155" = @("", "")
    "ethash2gb;blake2s:180" = @("", "")
    "ethash2gb;blake2s:205" = @("", "")
    "ethash2gb;blake2s:230" = @("", "")
    "ethash2gb;keccak:5"    = @("", "")
    "ethash2gb;keccak:30"   = @("", "")
    "ethash2gb;keccak:55"   = @("", "")
    "ethash2gb;keccak:80"   = @("", "")
    "ethash3gb;blake2s:55"  = @("", "")
    "ethash3gb;blake2s:80"  = @("", "")
    "ethash3gb;blake2s:105" = @("", "")
    "ethash3gb;blake2s:130" = @("", "")
    "ethash3gb;blake2s:155" = @("", "")
    "ethash3gb;blake2s:180" = @("", "")
    "ethash3gb;blake2s:205" = @("", "")
    "ethash3gb;blake2s:230" = @("", "")
    "ethash3gb;keccak:5"    = @("", "")
    "ethash3gb;keccak:30"   = @("", "")
    "ethash3gb;keccak:55"   = @("", "")
    "ethash3gb;keccak:80"   = @("", "")
}
$CommonCommands = @(" -logsmaxsize 1 -dbg 1 -logfile debug.log", "") # array, first value for main algo, second value for secondary algo

# Get array of IDs of all devices in device set, returned DeviceIDs are of base $DeviceIdBase representation starting from $DeviceIdOffset
$DeviceIDsSet = Get-DeviceIDs -Config $Config -Devices $Devices -Type NVIDIA -DeviceTypeModel $($Devices.NVIDIA) -DeviceIdBase 16 -DeviceIdOffset 0

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {

    $MainAlgorithm = $_.Split(";") | Select -Index 0
    $MainAlgorithm_Norm = Get-Algorithm $MainAlgorithm
    
	if ($Type -EQ "NVIDIA"){
        Switch ($MainAlgorithm_Norm) { # default is all devices, ethash has a 4GB minimum memory limit
            "Ethash"    {$DeviceIDs = $DeviceIDsSet."4gb"}
            "Ethash2gb" {$DeviceIDs = $DeviceIDsSet."2gb"}
            "Ethash3gb" {$DeviceIDs = $DeviceIDsSet."3gb"}
            default     {$DeviceIDs = $DeviceIDsSet."All"}
        }
    }
	else {
		$DeviceIDs = $DeviceIDsSet."$($Type)"
	}

    if ($Pools.$MainAlgorithm_Norm -and $DeviceIDs) { # must have a valid pool to mine and available devices

        $Miner_Name = $Name
        $MainAlgorithmCommands = $Commands.$_.Split(";") | Select -Index 0 # additional command line options for main algorithm
        $SecondaryAlgorithmCommands = $Commands.$_.Split(";") | Select -Index 1 # additional command line options for secondary algorithm

        if ($Pools.$MainAlgorithm_Norm.Name -eq 'NiceHash') {$EthereumStratumMode = "3"} else {$EthereumStratumMode = "2"} #Optimize stratum compatibility

        if ($_ -notmatch ";") { # single algo mining
            $Miner_Name = "$($Miner_Name)$($MainAlgorithm_Norm -replace '^ethash', '')"
            $HashRateMainAlgorithm = ($Stats."$($Miner_Name)_$($MainAlgorithm_Norm)_HashRate".Week)

            if ($Type -EQ "NVIDIA"){
                if (($DeviceIDsSet."4gb").Count -eq 0) {
                    # All GPUs are 3GB, miner is completely free in this case, developer fee will not be mined at all.
                    $Fee = 0
                }
			}
			else {
				if ($Type -EQ "10603gb") {
				    $Fee = 0
                }
			}

            # Single mining mode
            [PSCustomObject]@{
                Name      = $Miner_Name
                Type      = $Type
                Path      = $Path
                Arguments = ("-mode 1 -mport -$($Port) -epool $($Pools.$MainAlgorithm_Norm.Host):$($Pools.$MainAlgorithm_Norm.Port) -ewal $($Pools.$MainAlgorithm_Norm.User) -epsw $($Pools.$MainAlgorithm_Norm.Pass)$MainAlgorithmCommands$($CommonCommands | Select -Index 0) -esm $EthereumStratumMode -allpools 1 -allcoins 1 -platform 2 -di $($DeviceIDs -join '')" -replace "\s+", " ").trim()
                HashRates = [PSCustomObject]@{$MainAlgorithm_Norm = $HashRateMainAlgorithm}
                API       = $Api
                Port      = $Port
                URI       = $Uri
                MinerFee  = @($Fee)
            }
        }
        elseif ($_ -match "^.+;.+:\d+$") { # valid dual mining parameter set

            $SecondaryAlgorithm = ($_.Split(";") | Select -Index 1).Split(":") | Select -Index 0
            $SecondaryAlgorithm_Norm = Get-Algorithm $SecondaryAlgorithm
            $SecondaryAlgorithmIntensity = ($_.Split(";") | Select -Index 1).Split(":") | Select -Index 1
        
            $Miner_Name = "$($Miner_Name)$($MainAlgorithm_Norm -replace '^ethash', '')$($SecondaryAlgorithm_Norm)$($SecondaryAlgorithmIntensity)"
            $HashRateMainAlgorithm = ($Stats."$($Miner_Name)_$($MainAlgorithm_Norm)_HashRate".Week)
            $HashRateSecondaryAlgorithm = ($Stats."$($Miner_Name)_$($SecondaryAlgorithm_Norm)_HashRate".Week)

            if ($Type -EQ "NVIDIA"){
                if (($DeviceIDsSet."4gb").Count -eq 0) {
                    # All GPUs are 3GB, miner is completely free in this case, developer fee will not be mined at all.
                    $Fee = 0
                }
			}
			else {
				if ($Type -EQ "10603gb") {
				    $Fee = 0
                }
			}

            if ($Pools.$SecondaryAlgorithm_Norm -and $SecondaryAlgorithmIntensity -gt 0) { # must have a valid pool to mine and positive intensity
                # Dual mining mode
                [PSCustomObject]@{
                    Name      = $Miner_Name
                    Type      = $Type
                    Path      = $Path
                    Arguments = ("-mode 0 -mport -$($Port) -epool $($Pools.$MainAlgorithm_Norm.Host):$($Pools.$MainAlgorithm.Port) -ewal $($Pools.$MainAlgorithm_Norm.User) -epsw $($Pools.$MainAlgorithm_Norm.Pass)$MainAlgorithmCommand$($CommonCommands | Select -Index 0) -esm $EthereumStratumMode -allpools 1 -allcoins 1 -dcoin $SecondaryAlgorithm -dcri $SecondaryAlgorithmIntensity -dpool $($Pools.$SecondaryAlgorithm_Norm.Host):$($Pools.$SecondaryAlgorithm_Norm.Port) -dwal $($Pools.$SecondaryAlgorithm_Norm.User) -dpsw $($Pools.$SecondaryAlgorithm_Norm.Pass)$SecondaryAlgorithmCommands$($CommonCommands | Select -Index 1) -platform 2 -di $($DeviceIDs -join '')" -replace "\s+", " ").trim()
                    HashRates = [PSCustomObject]@{$MainAlgorithm_Norm = $HashRateMainAlgorithm; $SecondaryAlgorithm_Norm = $HashRateSecondaryAlgorithm}
                    API       = $Api
                    Port      = $Port
                    URI       = $Uri
                    MinerFee  = @($Fee)
                }
            }
        }
    }
}