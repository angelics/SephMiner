# SephMiner | セフマイナー
multipoolminer 95d4193 with bug fixed or improvements commits | マルチプールマイナー95d4193から不具合や改善

* Added gpu reset / oc profiles | 自動的にGPUを回復（リセット） アルゴリズムによってオーバークロックプロフィールを設定
* Added pool coin variance | プール分散計算
* Moved in,br to Europe | インド、ブラジルをヨーロッパのサーバ-に
* Removed monitoring | モニタリング取り除く
* Excluded electroneum from miningpoolhubcoins, until auto-exchange is available | miningpoolhubcoinsからelectroneum除外された、 until auto-exchange is available.
* Excluded maxcoin from miningpoolhubcoins, remove it if auto-exchange set to BTC | miningpoolhubcoinsからmaxcoin除外されたが、remove it if auto-exchange set to BTC.
```
default config.txt for miningpoolhubcoins have Ethereum with disabledexchange | miningpoolhubcoinsのEthereumをdisabledexchange既定にしました
```
* Removed ASICS coins from all pools and miners | ASICできたコイン取り除く
* Removed auto-update | 自動構成取り除く
* If you are "upgrading" from master copy, remove all folders except Bin , Stats and OC. Run resetprofit after | 
* Default zergpool, zergpoolcoins mining address in config.txt is LTC. please change to "BTC": "$Wallet", if you are going to use BTC wallet | 
* **Default donation 24 minutes, minimum 10** | 
```
24mins = 1.667%

```
```
10mins = 0.694%

```
* **personnaly** recommend only use miningpoolhub or miningpoolhubcoins,zpool and zergpool1 or zergpool3 | 
* always move to disable folder for un-used pools | 
* always move to disable folder for un-used miners | 

# NVIDIA
NVIDIA users need to download nvidiainspecter to use OC feature | 
```
http://www.guru3d.com/files-details/nvidia-inspector-download.html
```
# AMD
AMD users need to download OverdriveNTool to use OC feature | 
```
https://forums.guru3d.com/threads/overdriventool-tool-for-amd-gpus.416116/
```

# OC profile name: | 
* (algorithm)(space)(algorithm)_(type).bat 
```
ethash blake2s_AMD.bat
```

# OhGodAnETHlargementPill
* recommended 1080 / 1080ti atm
```
https://github.com/OhGodACompany/OhGodAnETHlargementPill
```

# Lists of algos added:
* m7m
* x16r
* x16s
* yescrypt16
* yescrypt32
* axiom
* hodl
* keccakc
* cryptonight-heavy
* cryptonight-v7
* cryptonight-v7 lite
* allium

# Lists of algos removed:
* decred
* lbry
* pascal
* skein
* myr-gr
* nist5
* sia
* groestl
* cryptonight
* cryptonightlite
* sib
* veltor
* blakecoin
* vanilla

# Lists of algos to be removed:
* ethash
* equihash

# Lists of miner removed:
* CcminerHsr
* CcminerSib
* CcminerSkunk
* CcminerSp
* claymoredecred
* claymorelbry
* claymorepascal
* eminer
* MkxminerAmd
* NsgminerNvidia
* SgminerSkein
* SgminerXevan

# This is a free project feel free to donate be much appreciated:

aaronsace = 1MsrCoAt8qM53HUMsUxvy9gMj3QVbHLazH

angelics BTC = 19pQKDfdspXm6ouTDnZHpUcmEFN8a1x9zo

angelics ETH = 0xBD0e3c16447b68CE01fAA19f65aE9e3882a54C54

angelics LTC = Lex2wqKA44ZGkBvHhWE3STrqicbCdGG125

angelics DASH = XvJ4t1dWy86a3p6KRt7rtVQgeqcGAdsSNh