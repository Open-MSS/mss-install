#!/bin/bash
#   mss-install.LinuxMac
#   ~~~~~~~~~~~~~~~~~~~~~
#
#   This script tries to install mamba and/or mss on a Linux or MacOS system automatically.
#
#   This file is part of MSS.
#
#   :copyright: Copyright 2021 May Baer
#   :copyright: Copyright 2021-2023 by the MSS team, see AUTHORS.
#   :license: APACHE-2.0, see LICENSE for details.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
set -euo pipefail
automatic="No"
if [[ "$#" == 1 ]]; then
    automatic=$({ [ "$1" = "a" ] || [ "$1" = "-a" ]; } && echo "Yes" || echo "No")
fi
echo "Checking Mamba installation..."
unameOS=$([ "$(uname -s)" == "Darwin" ] && echo "MacOSX" || echo "Linux")
architectureOS="$(uname -m)"
if [ "$(uname -m)" == "arm64" ] && [ "$unameOS" == "MacOSX" ]; then echo "Aborting. Mac ARM M1 currently not supported." && exit 1; fi
completeSize=4 # integer
mssSize=2 # integer

echo "
We recommend to start from Miniforge for the MSS installation.

Miniforge comes with the popular conda-forge channel preconfigured, but you can modify the configuration to use any channel you like.

The next steps are to check for an existing Miniforge Installation.

If possible we try to:

install Miniforge including mamba then Create a mssenv then Install MSS.
"

sleep 2
echo "..."
echo "Checking for a miniconda or anaconda based installation"

if command -v conda  &> /dev/null
then
    CHECKCONDA=$(which conda)
    if [[ $CHECKCONDA == *"miniconda"* ]] || [[ $CHECKCONDA == *"anaconda"* ]]; then
       echo "Found a anaconda/miniconda installation see documentation for a manual installation";
       exit 1;
    fi
else
     echo "You start from scratch. Not an old conda based installation found."
fi


sleep 2


# neither conda nor mamba -> Miniforge
which mamba || { echo "Downloading Miniforge..." &&
    if [[ $unameOS = "MacOSX" ]]
       then
          freespace=$(df -g  . |  tail -1 | awk '{print $4+0}')
       else
          freespace=$(df -BG --output='avail' . | tail -1 | awk '{print $1+0}') 
    fi &&
    if [[ $freespace -lt $completeSize ]]; then
	    echo "Aborting. You need at least $completeSize GB of space to install mamba and MSS" && exit 1;
    fi &&
   curl -L0 "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-${unameOS}-${architectureOS}.sh" --output miniforge-installer.sh &&
   ls -l miniforge-installer.sh &&
   echo "Installing miniforge..." &&
   chmod +x miniforge-installer.sh &&

   if [[ $unameOS = "MacOSX" ]]
   then
      if [[ $automatic  = "No" ]]; then script -q output.txt ./miniforge-installer.sh -u; else script -q output.txt ./miniforge-installer.sh -u -b -p ~/Miniforge; fi
   else
      if [[ $automatic  = "No" ]]; then script -q -c "./miniforge-installer.sh -u" output.txt; else script -q -c "./miniforge-installer.sh -u -b -p ~/Miniforge" output.txt; fi
   fi && cat output.txt &&
   location=$(< output.txt grep "PREFIX=" | tr -d "[:cntrl:]" | sed -e "s/.*PREFIX=//g") && rm output.txt &&
   if [[ "$location" != "" ]]; then . "$location/etc/profile.d/conda.sh" && . "$location/etc/profile.d/mamba.sh" & export PATH="$location/bin:$PATH" &&  mamba init; else . "$HOME/.bashrc"; fi
   if [[ "$SHELL" = *zsh ]]; then conda init zsh; fi && rm miniforge-installer.sh &&
   which mamba || { echo "mamba still not found, please restart your console and try again"; exit 1; }
}

echo "mamba installed"
    if [[ $unameOS = "MacOSX" ]]
       then
          freespace=$(df -g  . | tail -1 | awk '{print $4+0}') 
       else
          freespace=$(df -BG --output='avail' . | tail -1 | awk '{print $1+0}') 
    fi &&
    if [[ $freespace -lt $mssSize ]]; then
            echo "Aborting. You need at least $mssSize GB of space to install mamba and MSS" && exit 1;
    fi &&
    
    echo $HOME
    ls -R $HOME/Miniforge


    . "$HOME/Miniforge/etc/profile.d/conda.sh" &&
    . "$HOME/Miniforge/etc/profile.d/mamba.sh" &&
    mamba init &&
    mamba update -n base mamba -y && # update mamba to the newest version
    mamba activate mssenv || {
    echo "mssenv not found, creating..." &&
    mamba create -n mssenv -y &&
    mamba activate mssenv || { echo "'mssenv' environment could not be created, aborting"; exit 1; }
}

 echo "Installing MSS..."
 mamba install mss python -y
 mamba clean --all -y
 mamba list -f mss | grep "conda-forge" || { echo "MSS was not successfully installed, aborting"; exit 1; }
 echo "To start msui from the MSS Software,"
 echo "1. Activate your mamba environment with this command: 'mamba activate mssenv'"
 echo "2. Start msui with this command: 'msui'"
 exit 0;

