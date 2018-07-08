@echo off
set then=(
set else=) else (
set endif=)
set less=LSS
set greaterequal=GEQ
set greater=GTR
set log_file=mining_problems_log.txt
set ping_time=500
set mypath=%~dp0
set title=NVIDIA monitoring

mode con cols=50 lines=10
cls
REM 60+12 sec countdown
FOR /L %%A IN (66,-1,0) DO (
  cls
  echo Timeout [92;1m%%A[0m seconds...
  timeout /t 1 >nul
)

:start
set strike = 0
cls
for /F %%p in ('"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi" --id^=0 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage0=%%p
for /F %%p in ('"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi" --id^=1 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage1=%%p
for /F %%p in ('"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi" --id^=0 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage2=%%p
for /F %%p in ('"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi" --id^=1 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage3=%%p
for /F %%p in ('"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi" --id^=0 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage4=%%p
for /F %%p in ('"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi" --id^=1 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage5=%%p
set /a total=%gpu_usage0%+%gpu_usage1%+%gpu_usage2%+%gpu_usage3%+%gpu_usage4%+%gpu_usage5%
set /a gpu_average=%total%/6
echo START: Average Usage of *6 GPUs usage is %gpu_average%%%
if %gpu_average% %greater% 40 %then%
	echo [92;1mMining is working[0m
	echo [102;92;1mMining is working[0m
	REM pause 10+6 to recheck gpu usage
	timeout /t 16 >nul
	goto start
%else%
	REM check if net down
	goto netcheck
%endif%

:netcheck
cls
FOR /F "skip=8 tokens=10" %%G in ('ping -n 3 google.com') DO set ping_time=%%G
if %ping_time% %greater% 0 %then%
	echo Control checking of GPUs usage, timeout 16 sec...
	REM pause 16 to recheck gpu usage
	timeout /t 16 >nul
	goto lastcheck
%else%
	cls
	echo      %date% %time% No internet connection>> %log_file%
	echo No internet connection, keep working...
	REM pause 16 to recheck gpu usage
	timeout /t 16 >nul
	set /a strike += 1
	goto lastcheck
%endif%

:lastcheck
cls
for /F %%p in ('"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi" --id^=0 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage0=%%p
for /F %%p in ('"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi" --id^=1 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage1=%%p
for /F %%p in ('"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi" --id^=0 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage2=%%p
for /F %%p in ('"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi" --id^=1 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage3=%%p
for /F %%p in ('"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi" --id^=0 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage4=%%p
for /F %%p in ('"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi" --id^=1 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage5=%%p
set /a total=%gpu_usage0%+%gpu_usage1%+%gpu_usage2%+%gpu_usage3%+%gpu_usage4%+%gpu_usage5%
set /a gpu_average=%total%/6
echo %strike%: Average Usage of *6 GPUs usage is %gpu_average%%%
if %gpu_average% %greater% 40 %then%
	echo [92;1mMining is working[0m
	echo [102;92;1mMining is working[0m
	REM pause 16 to recheck gpu usage
	timeout /t 16 >nul
	goto start
%endif%
if %strike% %greater% 3 %then%
goto reboot
%else%
set /a strike += 1
goto netcheck
%endif%

:reboot
REM screenshot
REM SET scrpath=%mypath%Scr
REM if not exist "%scrpath%" mkdir "%scrpath%"
REM "%mypath%nircmd.exe" savescreenshot "%scrpath%\%TIME:~0,-9%-%TIME:~3,2%-%TIME:~6,2%.png"
REM echo "%scrpath%%DATE:~6,4%.%DATE:~3,2%.%DATE:~0,2% %TIME:~0,-9%-%TIME:~3,2%-%TIME:~6,2%.png"

echo.>> %log_file%
echo ---------------------------------------------------------------------------------------------------->> %log_file%
echo.>> %log_file%
echo PC was restarted at %date% %time%>> %log_file%, mining issue. GPUs usage is %gpu_average%%%
"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi">> %log_file%
echo.>> %log_file%
echo ---------------------------------------------------------------------------------------------------->> %log_file%
echo.>> %log_file%

echo [101;93mMining is NOT working, rebooting in 10 seconds...[0m
timeout /t 10 >nul
shutdown.exe /r /t 00
goto eof

:eof