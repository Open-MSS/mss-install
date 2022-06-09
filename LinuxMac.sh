#   mss-install.LinuxMac
#   ~~~~~~~~~~~~~~~~~~~~~
#
#   This script tries to install conda and/or mss on a Linux or MacOS system automatically.
#
#   This file is part of MSS.
#
#   :copyright: Copyright 2021 May Baer
#   :copyright: Copyright 2021-2022 by the MSS team, see AUTHORS.
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

#!/bin/bash -i
set -euo pipefail
automatic=$(([ "$1" = "a" ] || [ "$1" = "-a" ]) && echo "Yes" || echo "No")
echo "Checking Conda installation..."
condaInstalled="Yes"
unameOS=$([ "$(uname -s)" == "Darwin" ] && echo "MacOSX" || echo "Linux")
if [ $(uname -m) == "arm64" ] && [ $unameOS == "MacOSX" ]; then echo "Aborting. Mac ARM M1 currently not supported." && exit 1; fi
dfCommand=$([ $unameOS = "MacOSX" ] && echo "df -g ." || echo "df -BG .")
completeSize=3
mssSize=2.7

which conda || { echo "Downloading miniconda3..." &&
   condaInstalled="No" &&
   { awk -v n1="$($dfCommand | tail -1 | awk '{print $4+0}')" "BEGIN {exit !(n1 < $completeSize)}" && echo "Aborting. You need at least $completeSize GB of space to install conda and MSS" && exit 0; }
   curl "https://repo.anaconda.com/miniconda/Miniconda3-latest-${unameOS}-x86_64.sh" --output miniconda-installer.sh &&
   echo "Installing miniconda3..." &&
   chmod +x miniconda-installer.sh &&

   if [[ $unameOS = "MacOSX" ]]
   then
      if [[ $automatic  = "No" ]]; then script -q output.txt ./miniconda-installer.sh -u; else script -q output.txt ./miniconda-installer.sh -u -b -p ~/miniconda3; fi
   else
      if [[ $automatic  = "No" ]]; then script -q -c "./miniconda-installer.sh -u" output.txt; else script -q -c "./miniconda-installer.sh -u -b -p ~/miniconda3" output.txt; fi
   fi && cat output.txt &&
   location=$(cat output.txt | grep "PREFIX=" | tr -d [:cntrl:] | sed -e "s/.*PREFIX=//g") && rm output.txt &&
   if [[ $location != "" ]]; then . $location/etc/profile.d/conda.sh; else . ~/.bashrc; fi && conda init &&
   if [[ $SHELL = *zsh ]]; then conda init zsh; fi && rm miniconda-installer.sh &&
   which conda || { echo "Conda still not found, please restart your console and try again"; exit 1; }
}

echo "Conda installed"
{ awk -v n1="$($dfCommand | tail -1 | awk '{print $4+0}')" "BEGIN {exit !(n1 < $mssSize)}" && echo "Aborting. You need at least $mssSize GB of space to install MSS" && exit 0; } ;
. $(conda info --base)/etc/profile.d/conda.sh
conda config --add channels conda-forge
conda activate mssenv || {
    echo "mssenv not found, creating..." &&
    conda create -n mssenv mamba -y &&
    conda activate mssenv || { echo "Environment not found, aborting"; exit 1; }
}

echo "Installing MSS..."
mamba install mss python -y
mamba list -f mss | grep "conda-forge" || { echo "MSS was not successfully installed, aborting"; exit 1; }

echo "Done!"
if [[ $condaInstalled = "No" ]]; then echo "Please restart your shell for changes to take effect! 'exec $SHELL'"; fi
echo "To start msui from the MSS Software,"
echo "1. Activate your conda environment with this command: 'conda activate mssenv'"
echo "2. Start msui with this command: 'msui'"
