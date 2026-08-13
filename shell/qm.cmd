@echo off
rem qm.cmd -- Windows launcher for the `?` (ask-cli) wrapper.
rem The wrapper is a bash script installed as "%USERPROFILE%\bin\qm.bash".
rem NTFS forbids a file literally named `?`, so Windows installs use `qm`.
rem This shim calls out to bash (Git Bash / WSL) with the args forwarded.
rem
rem Set QM_BASH to the bash binary used on your system if it's not on PATH:
rem   setx QM_BASH "C:\Program Files\Git\bin\bash.exe"
setlocal
set "BASH=%QM_BASH%"
if not defined BASH set "BASH=bash"
set "QM=%USERPROFILE%\bin\qm.bash"
if not exist "%QM%" set "QM=%LOCALAPPDATA%\bin\qm.bash"
if not exist "%QM%" (
  echo qm.cmd: cannot find qm.bash ^(expected %%USERPROFILE%%\bin\qm.bash or %%LOCALAPPDATA%%\bin\qm.bash^) 1>&2
  exit /b 1
)
rem Git Bash needs the MSYS path style for the script.
"%BASH%" -lc "qm.bash %*"
exit /b %ERRORLEVEL%