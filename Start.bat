@echo off

setlocal enabledelayedexpansion
set cur=%cd%
set then=(
set else=) else (
set endif=)
set greaterequal=GEQ
set title=SephMiner

REM uncomment below if mining with amd
REM OC\OverdriveNTool.exe -r1 -r2 -r3 -r4 -r5 -r6

REM total number of nvidiagpu
set nvidiagpu=0
set /a timer = 3+%nvidiagpu%

if %nvidiagpu% == 0 %then%
goto start
%endif%

REM check nvidia gpu if they are working
set /a gpu=0
:loop1
for /F "tokens=*" %%p in ('"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi" --id^=%gpu% --query-gpu^=memory.used --format^=csv^,noheader^,nounits') do set gpu_mem=%%p
echo.%gpu_mem% | findstr /C:"Unknown error">nul && (
OC\NV_Inspector\nvidiaInspector.exe -restartDisplayDriver
timeout %timer%
goto start
)
echo.%gpu_mem% | findstr /C:"No device">nul && (
shutdown /r
)
set /a gpu+=1
if %gpu% %greaterequal% %nvidiagpu% %then%
goto start
%else%
goto loop1
%endif%

:start
setx GPU_FORCE_64BIT_PTR 1
setx GPU_MAX_HEAP_SIZE 100
setx GPU_USE_SYNC_OBJECTS 1
setx GPU_MAX_ALLOC_PERCENT 100
setx GPU_SINGLE_ALLOC_PERCENT 100

set wallet=19pQKDfdspXm6ouTDnZHpUcmEFN8a1x9zo
set username=SephMiner
set workername=SephMiner
set region=asia
set currency=usd
set type=amd,nvidia,cpu
set poolname=miningpoolhubcoins,zpool
set ExcludePoolName=miningpoolhub
REM asic algo = sha256,scrypt,x11,x13,x14,quark,qubit,decred,lbry,sia,Pascal,cryptonight,skein,myr-gr
set algorithm=ethash,lyra2re2,keccak,equihash,neoscrypt,lyra2z,m7m,xevan,hmq1725,blake2s,c11,phi,x17,bitcore,polytimos,x11evo,hsr,sib,yescrypt,tribus,lyra2v2,blakecoin,groestl,nist5,skunk,keccakc
set ExcludeAlgorithm=ethash2gb
set ExcludeMinerName=ccminerlyra2re2,prospector
set switchingprevention=2
set interval=600

set command=%cur%\SephMiner.ps1 -wallet %wallet% -username %username% -workername %workername% -region %region% -currency %currency%,btc -type %type% -poolname %poolname% -algorithm %algorithm% -ExcludeAlgorithm %ExcludeAlgorithm% -ExcludeMinerName %ExcludeMinerName% -donate 24 -watchdog -switchingprevention %switchingprevention% -interval %interval% -ExcludePoolName %ExcludePoolName%
title  %title%

pwsh -noexit -executionpolicy bypass -windowstyle maximized -command "%command%"
powershell -version 5.0 -noexit -executionpolicy bypass -windowstyle maximized -command "%command%"
msiexec -i https://github.com/PowerShell/PowerShell/releases/download/v6.0.2/PowerShell-6.0.2-win-x64.msi -qb!
pwsh -noexit -executionpolicy bypass -windowstyle maximized -command "%command%"

pause
