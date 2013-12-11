cls
@echo off
pushd \\10.0.0.52\share\proxy
setlocal

set /p name=Enter name: 
for /F "tokens=*" %%i in ('openssl passwd -1 2^>nul ^|^| echo 1') do set pass=%%i
if "%pass%"=="1" goto failed
set num=10000

echo %name%:%pass%:%num%:%num%:%name%:/var/run:/bin/false>>passwd
echo OK!
goto end

:failed
echo Failed!

:end
endlocal
popd
pause