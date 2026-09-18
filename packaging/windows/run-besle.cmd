@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-besle.ps1" %*
set "BESLE_EXIT=%ERRORLEVEL%"
if not "%BESLE_EXIT%"=="0" (
  echo.
  echo BESLE exited with an error ^(code %BESLE_EXIT%^).
  echo Press any key to close . . .
  pause > nul
)
exit /b %BESLE_EXIT%
