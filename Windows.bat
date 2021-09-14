::    mss-install.Windows
::    ~~~~~~~~~~~~~~~~~~~~~
::
::    This script tries to install conda and/or mss on a Windows system automatically.
::
::    This file is part of mss.
::
::    :copyright: Copyright 2021 May Baer
::    :copyright: Copyright 2021 by the mss team, see AUTHORS.
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
echo Checking Conda installation...
where conda
if %errorlevel% == 0 (goto condainstalled)

:installconda
echo Checking existing conda installs not in path...
set a="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Anaconda3 (64-bit)\Anaconda Prompt (anaconda3).lnk"
set b="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Anaconda3 (64-bit)\Anaconda Prompt (miniconda3).lnk"
set c="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Anaconda3 (32-bit)\Anaconda Prompt (anaconda3).lnk"
set d="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Anaconda3 (32-bit)\Anaconda Prompt (miniconda3).lnk"
if exist %a% if "%3" neq "a" if "%3" neq "b" if "%3" neq "c" if "%3" neq "d" call "cmd /c" %a% "& %script:"=% %automatic% %retry% a" & exit 0
if exist %b% if "%3" neq "b" if "%3" neq "c" if "%3" neq "d" call "cmd /c" %b% "& %script:"=% %automatic% %retry% b" & exit 0
if exist %c% if "%3" neq "c" if "%3" neq "d" call "cmd /c" %c% "& %script:"=% %automatic% %retry% c" & exit 0
if exist %d% if "%3" neq "d" call "cmd /c" %d% "& %script:"=% %automatic% %retry% d" & exit 0

wmic logicaldisk where DeviceID='%USERPROFILE:~0,2%' get FreeSpace > space.txt
for /f "delims= " %%i in ('type space.txt') do set space=%%i
del space.txt
set "spaceMB=%space:~,-6%"
if %spaceMB% LSS 3221 (echo You need at least 3GB of space to install conda and MSS, aborting. & pause & exit /B 1)
echo Downloading miniconda3...
if "%retry%"=="retry" (echo Conda still not found after installation, aborting & pause & exit /B 1)
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OSBIT=32BIT || set OSBIT=64BIT
if %OSBIT%==32BIT curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86.exe --output miniconda-installer.exe
if %OSBIT%==64BIT curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe --output miniconda-installer.exe
echo Installing miniconda3 (just use the default settings if you are unsure)...
if "%automatic%"=="a" (start /wait miniconda-installer.exe /S /D=%USERPROFILE%\miniconda3) else (start /wait miniconda-installer.exe)
del "miniconda-installer.exe"
start /i /b %script% %automatic% retry & exit 0

:condainstalled
echo Conda installed
wmic logicaldisk where DeviceID='%USERPROFILE:~0,2%' get FreeSpace > space.txt
for /f "delims= " %%i in ('type space.txt') do set space=%%i
del space.txt
set "spaceMB=%space:~,-6%"
if %spaceMB% LSS 2899 (echo You need at least 2.7GB of space to install MSS, aborting. & pause & exit /B 1)
call conda.bat config --add channels conda-forge
call conda.bat activate mssenv
if not %errorlevel% == 0 (
    echo mssenv not found, creating...
    call conda.bat create -n mssenv mamba -y
    call conda.bat activate mssenv
    if errorlevel 1 (echo Environment not found, aborting & pause & exit /B 1)
)

:envexists
echo Installing mss...
call mamba install mss python -y
call mamba list -f mss| findstr /i /e "conda-forge"
if not %errorlevel% == 0 (echo MSS was not successfully installed, aborting & pause & exit /B 1)

echo Done! To start mss: Press the Windows button, type in "mss" and press enter.
echo Alternatively:
echo 1. Activate your conda environment with this command: "conda activate mssenv"
echo 2. Start mss with this command: "mss"
pause
