@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-besle.ps1" %*
set "BESLE_EXIT=%ERRORLEVEL%"
if not "%BESLE_EXIT%"=="0" (
  echo.
  echo BESLE finalizo con un error ^(codigo %BESLE_EXIT%^).
  pause
)
exit /b %BESLE_EXIT%
