::    mss-install.Windows
::    ~~~~~~~~~~~~~~~~~~
::
::    This script tries to install mamba and/or mss on a Windows system automatically.
::
::    This file is part of MSS.
::
::    :copyright: Copyright 2021 May Baer
::    :copyright: Copyright 2021-2023 by the MSS team, see AUTHORS.
::    :license: APACHE-2.0, see LICENSE for details.
::
::    Licensed under the Apache License, Version 2.0 (the "License");
::    you may not use this file except in compliance with the License.
::    You may obtain a copy of the License at
::
::       http://www.apache.org/licenses/LICENSE-2.0
::
::    Unless required by applicable law or agreed to in writing, software
::    distributed under the License is distributed on an "AS IS" BASIS,
::    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
::    See the License for the specific language governing permissions and
::    limitations under the License.

@echo off
if "%1"=="a" (set automatic=a) else (if "%1"=="-a" (set automatic=a) else (set automatic=No))
if "%2"=="retry" (set retry=retry) else (set retry=No)
set script=%~f0

echo We recommend to start from Mambaforge for the MSS installation.
echo Mambaforge comes with the popular conda-forge channel preconfigured,
echo but you can modify the configuration to use any channel you like.
echo The next steps are to check for an existing Installation.
echo If possible we try to:
echo install MambaForge then Create a mssenv then Install MSS.


echo Checking existing Anaconda/Miniconda installs not in path...
echo ============================================================
set a="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Anaconda3 (64-bit)\Anaconda Prompt (anaconda3).lnk"
set b="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Anaconda3 (64-bit)\Anaconda Prompt (miniconda3).lnk"
set c="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Anaconda3 (32-bit)\Anaconda Prompt (anaconda3).lnk"
set d="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Anaconda3 (32-bit)\Anaconda Prompt (miniconda3).lnk"

if exist %a% if "%3" neq "a" if "%3" neq "b" if "%3" neq "c" if "%3" neq "d" (goto showmanualhint)
if exist %b% if "%3" neq "b" if "%3" neq "c" if "%3" neq "d" (goto showmanualhint)
if exist %c% if "%3" neq "c" if "%3" neq "d" (goto showmanualhint)
if exist %d% if "%3" neq "d" (goto showmanualhint)

echo Checking Mamba installation...
echo ==============================
where mamba
if %errorlevel% == 0 (goto mambainstalled)


:installmamba
wmic logicaldisk where DeviceID='%USERPROFILE:~0,2%' get FreeSpace > space.txt
for /f "delims= " %%i in ('type space.txt') do set space=%%i
del space.txt
set "spaceMB=%space:~,-6%"
if %spaceMB% LSS 3221 (echo You need at least 3GB of space to install mamba and MSS, aborting. & pause & exit /B 1)
echo Downloading mambaforge...
echo =========================

if "%retry%"=="retry" (echo Mamba still not found after installation, aborting & pause & exit /B 1)
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OSBIT=32BIT || set OSBIT=64BIT
if %OSBIT%==64BIT curl https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Windows-x86_64.exe --output mambaforge-installer.exe
echo Installing mambaforge (Enable: Register Mambaforge as my default Python ...)
echo ============================================================================

if "%automatic%"=="a" (start /wait mambaforge-installer.exe /S /D=%USERPROFILE%\mambaforge) else (start /wait mambaforge-installer.exe)
del "mambaforge-installer.exe"
start /i /b %script% %automatic% retry & exit 0


:mambainstalled
echo Mamba installed
echo ===============
wmic logicaldisk where DeviceID='%USERPROFILE:~0,2%' get FreeSpace > space.txt
for /f "delims= " %%i in ('type space.txt') do set space=%%i
del space.txt
set "spaceMB=%space:~,-6%"
if %spaceMB% LSS 2899 (echo You need at least 2.7GB of space to install MSS, aborting. & pause & exit /B 1)
call mamba.bat activate mssenv
if not %errorlevel% == 0 (
    echo mssenv not found, creating...
    call mamba.bat create -n mssenv -y
    call mamba.bat activate mssenv
    if errorlevel 1 (echo Environment not found, aborting & pause & exit /B 1)
)

:envexists
echo Installing MSS...
echo =================
call mamba install mss python -y
call mamba list -f mss| findstr /i /e "conda-forge"
if not %errorlevel% == 0 (echo MSS was not successfully installed, aborting & pause & exit /B 1)

echo Done! To start msui from the MSS Software: Press the Windows button, type in "msui" and press enter.
echo Alternatively:
echo 1. Activate your mamba environment with this command: "mamba activate mssenv"
echo 2. Start msui with this command: "msui"

pause

exit /B 1

:showmanualhint
echo Found a anaconda/miniconda installation see documentation for a manual installation
echo ===================================================================================

pause

exit /B 1
