@echo off

set then=(
set else=) else (
set endif=)
set greaterequal=GEQ
setlocal enabledelayedexpansion

set title=default
REM total number of nvidiagpu
set nvidiagpu=1

set forcepstate=2
set fanspeed=100
set temptarget=80
set baseclockoffsetlow=0
set memoryclockoffsetlowest=0
set powertarget=100
set /a timer = 3+%nvidiagpu%
title  %title%

REM check nvidia gpu if they are working
set /a gpu=0
:loop
for /F "tokens=*" %%p in ('"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi" --id^=%gpu% --query-gpu^=memory.used --format^=csv^,noheader^,nounits') do set gpu_mem=%%p
echo.%gpu_mem% | findstr /C:"Unknown error">nul && (
NV_Inspector\nvidiaInspector.exe -restartDisplayDriver
timeout %timer%
goto oc
)
echo.%gpu_mem% | findstr /C:"No device">nul && (
shutdown /r
)
set /a gpu+=1
if %gpu% %greaterequal% %nvidiagpu% %then%
goto oc
%else%
goto loop
%endif%

:oc
echo forcepstate=%forcepstate%, fanspeed=%fanspeed%, temptarget=%temptarget%, baseclockoffsetlow=%baseclockoffsetlow%, memoryclockoffset=%memoryclockoffsetlowest%, powertarget=%powertarget%
NV_Inspector\nvidiaInspector.exe -forcepstate:0,%forcepstate% -setfanspeed:0,%fanspeed% -settemptarget:0,0,%temptarget% -setbaseclockoffset:0,0,%baseclockoffsetlow% -setmemoryclockoffset:0,0,%memoryclockoffsetlowest% -setpowertarget:0,%powertarget%