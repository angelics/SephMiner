using module ..\Include.psm1

$Path = ".\Bin\CryptoNight-Xrig\xrig.exe"
$Uri = "https://github.com/arnesson/xrig/releases/download/0.8.0/xrig_0.8.0_win64.zip"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$Port = 3336

([PSCustomObject]@{
        pool_list       = @([PSCustomObject]@{
                pool_address    = "$($Pools.CryptoNight.Host):$($Pools.CryptoNight.Port)"
                wallet_address  = "$($Pools.CryptoNight.User)"
                pool_password   = "$($Pools.CryptoNight.Pass)"
                use_nicehash    = $true
                use_tls         = $Pools.CryptoNight.SSL
                tls_fingerprint = ""
                pool_weight     = 1
            }
        )
        currency        = "monero"
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
) -replace "^{" -replace "}$" | Set-Content "$(Split-Path $Path)\$($Pools.CryptoNight.Name)_CryptoNight_$($Pools.CryptoNight.User)_Amd.txt" -Force -ErrorAction SilentlyContinue

[PSCustomObject]@{
    Type      = "AMD"
    Path      = $Path
    Arguments = "-c $($Pools.CryptoNight.Name)_CryptoNight_$($Pools.CryptoNight.User)_Amd.txt --noUAC --noCPU --noNVIDIA"
    HashRates = [PSCustomObject]@{CryptoNight = $Stats."$($Name)_CryptoNight_HashRate".Week * 0.99}
    API       = "XMRig"
    Port      = $Port
    URI       = $Uri
}
