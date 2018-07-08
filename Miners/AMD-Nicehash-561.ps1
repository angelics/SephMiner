using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.AMD) {return} # No AMD mining device present in system

$Type = "AMD"
$Path = ".\Bin\AMD-NiceHash-561\sgminer.exe"
$API  = "Xgminer"
$Uri  = "https://github.com/nicehash/sgminer/releases/download/5.6.1/sgminer-5.6.1-nicehash-51-windows-amd64.zip"
$Port = Get-FreeTcpPort -DefaultPort 4028
$Fee  = 0

$Commands = [PSCustomObject]@{
    #"bitcore"    = "" #Bitcore
    #"blake2s"    = "" #Blake2s
    #"c11"        = "" #C11
    #"ethash"     = " --gpu-threads 1 --worksize 192 --xintensity 1024" #Ethash
    #"hmq1725"    = "" #HMQ1725
    #"jha"        = "" #JHA
    "maxcoin"     = "" #Keccak
    "lyra2rev2"   = " --gpu-threads 2 --worksize 128 --intensity d" #Lyra2RE2
    #"lyra2z"     = " --worksize 32 --intensity 18" #Lyra2z
    #"neoscrypt"  = " --gpu-threads 1 --worksize 64 --intensity 15" #NeoScrypt
    #"skunk"      = "" #Skunk
    #"timetravel" = "" #Timetravel
    #"tribus"     = "" #Tribus
    #"x11evo"     = "" #X11evo
    #"x17"        = "" #X17
    "yescrypt"    = " --worksize 4 --rawintensity 256" #Yescrypt
    #"xevan-mod"  = " --intensity 15" #Xevan
}

$CommonCommands = "" #eg. " -d 0,1,8,9"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

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
	
    [PSCustomObject]@{
        Type           = $Type
        Path           = $Path
        Arguments      = "--api-listen --api-port $($Port) -k $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)$($CommonCommands) --gpu-platform $([array]::IndexOf(([OpenCl.Platform]::GetPlatformIDs() | Select-Object -ExpandProperty Vendor), 'Advanced Micro Devices, Inc.'))"
        HashRates      = [PSCustomObject]@{$Algorithm_Norm = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week}
        API            = $API
        Port           = $Port
        URI            = $Uri
        MinerFee       = @($Fee)
        ExtendInterval = $ExtendInterval
    }
}