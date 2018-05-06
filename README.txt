# SephMiner
multipoolminer 95d4193 with bug fixed or improvements commits

* Added gpu reset / oc profiles.

* Added pool and miner fee.

* Added pool coin variance.

* Moved in,br to Europe.

* Removed monitoring.

* Excluded electroneum from miningpoolhubcoins, until auto-exchange is available.

* Excluded maxcoin from miningpoolhubcoins, unless auto-exchange set to BTC.
```
default config.txt for miningpoolhubcoins have Ethereum with disabledexchange.
```
* Removed ASICS coins from all pools and miners.

* Removed auto-update.

* If you are "upgrading" from master copy, remove all folders except Bin , Stats and OC. Run resetprofit after.

* Default zergpool, zergpoolcoins mining address in config.txt is LTC. please change to "BTC": "$Wallet", if you are going to use BTC wallet.

* **Default donation 24 minutes, minimum 10**
```
24mins = 1.667%
```
```
10mins = 0.694%
```

* **personnaly** recommend only use miningpoolhub or miningpoolhubcoins,zpool and zergpool1 or zergpool3

* always move to disable folder for un-used pools

* always move to disable folder for un-used miners

# NVIDIA
NVIDIA users need to download nvidiainspecter to use OC feature
```
http://www.guru3d.com/files-details/nvidia-inspector-download.html
```
# AMD
AMD users need to download OverdriveNTool to use OC feature
```
https://forums.guru3d.com/threads/overdriventool-tool-for-amd-gpus.416116/
```

# OC profile name:
* (algorithm)(space)(algorithm)_(type).bat 
```
ethash blake2s_AMD.bat
```

# OhGodAnETHlargementPill
* recommended for heavymem miners, only supports 1080 / 1080ti atm
```
https://github.com/OhGodACompany/OhGodAnETHlargementPill
```

# Lists of algos added:
* m7m
* x12
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