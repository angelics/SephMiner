using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [PSCustomObject]$Stats,
    [PSCustomObject]$Config,
    [PSCustomObject]$Devices
)

$Type = "CPU"
$Path = ".\Bin\CryptoNight-FireIce-245NF\xmr-stak.exe"
$API  = "XMRig"
$Uri  = "https://github.com/nemosminer/xmr-stak/releases/download/xmr-stakv2.4.5/xmr-stak-2.4.5.zip"
$Port = Get-FreeTcpPort -DefaultPort 3334
$Fee  = 0

$Commands = [PSCustomObject]@{
    "cryptonight_heavy"       = "" #CryptoNightHeavy --nvidia cnheavy.txt
    "cryptonight_lite_v7"     = "" #CryptoNightLiteV7 --nvidia cnlitev7.txt
    "cryptonight_lite_v7_xor" = "" #CryptoNightLiteV7xor --nvidia cnlitev7xor.txt
    "cryptonight_V7"          = "" #CryptoNightV7 --nvidia cn7.txt
    "cryptonight_V7_stellite" = "" #CryptoNightV7stellite --nvidia cn7stellite.txt
}

$CommonCommands = "" #eg. " -d 0,1,8,9"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

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
    Type      = $Type
    Path      = $Path
    Arguments = "-C $($Pools.$Algorithm_Norm.Name)_$($Algorithm_Norm)_$($Pools.$Algorithm_Norm.User)_$($Type).txt -c $($Pools.$Algorithm_Norm.Name)_$($Algorithm_Norm)_$($Pools.$Algorithm_Norm.User)_$($Type).txt --noUAC --noAMD --noNVIDIA $($Commands.$_)$($CommonCommands)"
    HashRates = [PSCustomObject]@{$Algorithm_Norm = $HashRate}
    API       = $API
    Port      = $Port
    URI       = $Uri
    MinerFee  = @($Fee)
	}
}