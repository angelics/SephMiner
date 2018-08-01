using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

if (-not $Devices.NVIDIA) {return} # No NVIDIA mining device present in system

$Type = "NVIDIA"
$Path = ".\Bin\CryptoNight-FireIce-245NF\xmr-stak.exe"
$API  = "XMRig"
$Uri  = "https://github.com/nemosminer/xmr-stak/releases/download/xmr-stakv2.4.5/xmr-stak-2.4.5.zip"
$Port = Get-FreeTcpPort -DefaultPort 3335
$Fee  = 0

$Commands = [PSCustomObject]@{
    "cryptonight_heavy"       = " --nvidia $($Type)_cnheavy.txt" #CryptoNightHeavy
    "cryptonight_lite_v7"     = " --nvidia $($Type)_cnlitev7.txt" #CryptoNightLiteV7 
    "cryptonight_lite_v7_xor" = " --nvidia $($Type)_cnlitev7xor.txt" #CryptoNightLiteV7xor
    #"cryptonight_V7"          = " --nvidia $($Type)_cn7.txt" #CryptoNightV7 CcminerTpruvot-23
    "cryptonight_V7_stellite" = " --nvidia $($Type)_cn7stellite.txt" #CryptoNightV7stellite
}

$CommonCommands = "" #eg. " -d 0,1,8,9"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_

    Switch ($Algorithm_Norm) {
        "allium"        {$ExtendInterval = 3}
        "CryptoNightV7" {$ExtendInterval = 3}
        "hmq1725"       {$ExtendInterval = 3}
        "Lyra2RE2"      {$ExtendInterval = 3}
        "phi"           {$ExtendInterval = 3}
        "phi2"          {$ExtendInterval = 3}
        "tribus"        {$ExtendInterval = 3}
        "X16R"          {$ExtendInterval = 4}
        "X16S"          {$ExtendInterval = 4}
        "X17"           {$ExtendInterval = 3}
        "Xevan"         {$ExtendInterval = 3}
        default         {$ExtendInterval = 0}
    }  
	
    $HashRate = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".Week * (1 - $Fee / 100)

([PSCustomObject]@{
        pool_list       = @([PSCustomObject]@{
                pool_address    = "$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port)"
                wallet_address  = "$($Pools.$Algorithm_Norm.User)"
                pool_password   = "$($Pools.$Algorithm_Norm.Pass)"
                rig_id = ""
                use_nicehash    = $true
                use_tls         = $Pools.$Algorithm_Norm.SSL
                tls_fingerprint = ""
                pool_weight     = 1
            }
        )
        currency        = "$_"
        call_timeout    = 10
        retry_time      = 10
        giveup_limit    = 0
        verbose_level   = 3
        print_motd      = $true
        h_print_time    = 60
        aes_override    = $null
        use_slow_memory = "warn"
        tls_secure_algo = $true
        daemon_mode     = $false
        flush_stdout    = $false
        output_file     = ""
        httpd_port      = $Port
        http_login      = ""
        http_pass       = ""
        prefer_ipv4     = $true
    } | ConvertTo-Json -Depth 10
) -replace "^{" -replace "}$" | Set-Content "$(Split-Path $Path)\$($Pools.$Algorithm_Norm.Name)_$($Algorithm_Norm)_$($Pools.$Algorithm_Norm.User)_$($Type).txt" -Force -ErrorAction SilentlyContinue

	[PSCustomObject]@{
    Type           = $Type
    Path           = $Path
    Arguments      = "-C $($Pools.$Algorithm_Norm.Name)_$($Algorithm_Norm)_$($Pools.$Algorithm_Norm.User)_$($Type).txt -c $($Pools.$Algorithm_Norm.Name)_$($Algorithm_Norm)_$($Pools.$Algorithm_Norm.User)_$($Type).txt --noUAC --noAMD --noCPU $($Commands.$_)$($CommonCommands)"
    HashRates      = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
    API            = $APi
    Port           = $Port
    URI            = $Uri
    MinerFee       = @($Fee)
    ExtendInterval = $ExtendInterval
	}
}