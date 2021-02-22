#!/bin/bash

########### Winlink & VARA Installer Script for the Raspberry Pi 4B ###########
# Author: Eric Wiessner (KI7POL)                                              #
# Version: 0.46 (work in progress 02/21/2021)                                 #
# Credits:                                                                    #
#   The Box86 team                                                            #
#      (ptitSeb, pale, chills340, phoenixbyrd, Botspot, !FlameKat53, epychan, #
#       Heasterian, monkaBlyat, SpacingBat3, #lukefrenner, Icenowy, Longhorn, #
#       #MonthlyDoseOfRPi, luschia, Binay Devkota, hacker420, et.al.)         #
#   K6ETA & DCJ21's Winlink on Linux guides                                   #
#   KM4ACK & OH8STN for inspiration                                           #
#   N7ACW & AD7HE for getting me started in ham radio                         #
#                                                                             #
#    "My humanity is bound up in yours, for we can only be human together"    #
#                                                - Nelson Mandela             #
###############################################################################

# About:
#    This script will help you install Box86, Wine, winetricks, Windows DLL's, Winlink (RMS Express) & VARA.  You will then need to configure RMS Express & VARA to send/receive audio from a USB sound card plugged into your Pi.  This installer will only work on the Raspberry Pi 4B for now.  If you would like to use an older Raspberry Pi (3B+, 3B, 2B, Zero, for example), software may run very slow and you may need to compile a custom 2G/2G split memory kernel before installing.
#
# Distribution:
#    This script is free to use, open-source, and should not be monetized.  If you use this script in your project (or are inspired by it) just please be sure to mention ptitSeb, Box86, and myself (KI7POL).
#
# Legal:
#    All software used by this script is free and legal to use (with the exception of VARA, of course, which is shareware).  Box86 and Wine are both open-source (which avoids the legal problems of use & distribution that ExaGear had - ExaGear also ran much slower than Box86 and is no-longer maintained, despite what Huawei says these days).  All proprietary Windows DLL files required by Wine are downloaded directly from Microsoft and installed according to their redistribution guidelines.
#
# Donations:
#    If you feel that you are able and would like to support this project, please consider sending donations to ptitSeb or KM4ACK - without whom, this script would not exist.
#        - Sebastien "ptitSeb" Chevalier - author of "Box86": paypal.me/0ptitSeb
#        - Jason Oleham (KM4ACK) - inspiration & Linux elmer: paypal.me/km4ack
#

clear
############  Setup the RPi4 to run Windows .exe files ############ 
# To run Windows .exe files on RPi4, we need an x86 emulator (box86) and a Windows API Call interpreter (wine)
# Box86 is opensource and runs about 10x faster than ExaGear or Qemu.  It's much smaller and easier to install too.

### Install Box86
sudo apt-get install cmake -y
cd ~/Downloads
mkdir box86-installer && cd box86-installer
git clone https://github.com/ptitSeb/box86
cd box86/
git checkout db5efa89085a085d733c859662799ebcf4e5c3c2 # this version of box86 installs dotnet35sp1 but doesn't run RMS Express
mkdir build; cd build; cmake .. -DRPI4=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j4
sudo make install # copies box86 files to /usr/local/bin/box86
sudo systemctl restart systemd-binfmt # essentially initializes box86
git checkout master


### Download and install Wine 5.21 devel buster for i386
# Backup old wine
wineserver -k # stop any old wine installations from running
sudo mv ~/wine ~/wine-old
sudo mv ~/.wine ~/.wine-old
sudo mv /usr/local/bin/wine /usr/local/bin/wine-old
sudo mv /usr/local/bin/winecfg /usr/local/bin/winecfg-old
sudo mv /usr/local/bin/wineserver /usr/local/bin/wineserver-old

# Download wine
cd ~/Downloads
wget https://dl.winehq.org/wine-builds/debian/dists/buster/main/binary-i386/wine-devel-i386_5.21~buster_i386.deb
wget https://dl.winehq.org/wine-builds/debian/dists/buster/main/binary-i386/wine-devel_5.21~buster_i386.deb
dpkg-deb -xv wine-devel-i386_5.21~buster_i386.deb wine-installer
dpkg-deb -xv wine-devel_5.21~buster_i386.deb wine-installer
rm wine-devel-i386_5.21~buster_i386.deb # clean up
rm wine-devel_5.21~buster_i386.deb # clean up

# Install wine
sudo mv wine-installer/opt/wine-devel ~/wine
rm -rf wine-installer # clean up
sudo ln -s ~/wine/bin/wine /usr/local/bin/wine
sudo ln -s ~/wine/bin/winecfg /usr/local/bin/winecfg
sudo ln -s ~/wine/bin/wineserver /usr/local/bin/wineserver

# Initialize wine silently
rm -rf ~/.cache/wine # make sure we don't install mono or gecko (if their msi files are in wine cache)
DISPLAY=0 wine wineboot # silently makes a fresh wineprefix in ~/.wine and skips installation of mono & gecko


### Download & install winetricks
sudo mv /usr/local/bin/winetricks /usr/local/bin/winetricks-old # backup old winetricks
cd ~/Downloads
wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks # download
sudo chmod +x winetricks 
sudo cp winetricks /usr/local/bin # install
rm winetricks # clean up
sudo apt-get install cabextract -y # winetricks needs this


### Setup Wine (install system requirements into our wineprefix for Winlink & VARA)
BOX86_NOBANNER=1 winetricks -q corefonts dotnet35sp1 vb6run win7 sound=alsa # for RMS Express
BOX86_NOBANNER=1 winetricks -q vcrun2015 pdh # for VARA (run pdh here just for the winecfg dll override)
BOX86_NOBANNER=1 winetricks -q riched30 richtx32 crypt32 comctl32ocx comdlg32ocx # for Box86 compatibility (to cover any wine libraries that aren't wrapped in Box86 yet)
# NOTE: This command needs testing - vcrun2015, crypt32, and the ocx components may not install properly
# Notes: Does Winlink HF Channel Selector (ITS) need ie6 or gecko?

# Install an older pdh.dll (the pdh.dll from "winetricks pdh" is too new for VARA)
sudo apt-get install zip -y
cd ~/Downloads && mkdir pdhNT40 && cd pdhNT40
wget http://download.microsoft.com/download/winntsrv40/update/5.0.2195.2668/nt4/en-us/nt4pdhdll.exe
unzip -o nt4pdhdll.exe
cp pdh.dll ~/.wine/drive_c/windows/system32





# NOTE: THIS IS A KLUDGE!!
# dotnet35sp1 installer needs an old box86, but our programs need the latest box86. Update box86 with these commands.
cd ~/Downloads/box86-installer
cd box86/
git checkout cad160205fd9a267e6c3d9d784fbef72b1c68dde # freeze box86 version on a commit known to work
cd build
make -j4
sudo make install

rm -rf ~/Downloads/box86-installer # clean up







############  Install Winlink and VARA (into our configured wineprefix) ############
sudo apt-get install p7zip-full -y
sudo apt-get install megatools -y

# Download/extract/install Winlink Express (formerly RMS Express) [https://downloads.winlink.org/User%20Programs/]
cd ~/Downloads
wget -r -l1 -np -nd -A "Winlink_Express_install_*.zip" https://downloads.winlink.org/User%20Programs # Download Winlink no matter its version number
7z x Winlink_Express_install_*.zip -o"WinlinkExpressInstaller"
wine ~/Downloads/WinlinkExpressInstaller/Winlink_Express_install.exe /SILENT
rm -rf ~/Downloads/WinlinkExpressInstaller # clean up

# Download/extract/install VARA HF (or newer) [https://rosmodem.wordpress.com/]
cd ~/Downloads
VARALINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?<=<a href=").*?(?=" target="_blank" rel="noopener noreferrer">VARA HF v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
megadl ${VARALINK}
7z x VARA*.zip -o"VARAInstaller"
wine ~/Downloads/VARAInstaller/VARA\ setup*.exe /SILENT
rm -rf ~/Downloads/VARAInstaller # clean up
# NOTE: VARA prompts user to hit 'ok' after install even if silent install.  We could skip it with wine AHK, but since the next step is user configuration and involves user input anyway, we can just have the user click ok here.
# Inno Setup Installer commandline commands: https://jrsoftware.org/ishelp/index.php?topic=setupcmdline



###### Configure Winlink and VARA ######
echo "In winecfg, go to the Audio tab to set up your default in/out soundcards."
wine winecfg

echo "In VARA, set up your soundcard input and output (go to Settings ... Soundcard)"
wine ~/.wine/drive_c/VARA/VARA.exe

echo "In RMS Express, enter your callsign, password, gridsquare, and soundcard in/out, then close the program.  Ignore any errors for now."
wine ~/.wine/drive_c/RMS\ Express/RMS\ Express.exe


#############  Known bugs ############# 
# The Channel Selector is functional, it just takes about 5 minutes to update its propagation indices and sometimes crashes the first time it's loaded.  Just restart it if it crashes.  If you let it run for 5 minutes, then you shouldn't have to do that again - just don't hit the Update Table Via Internet button.  I'm currently experimenting with ITS HF: http://www.greg-hand.com/hfwin32.html
# VARA has some graphics issues for now.  This is an issue with Wine, not box86
# RMS Express internet may not work on the first run (or in some cases ever) for some reason.  This might be due to vbrun6 being installed with old box86?
