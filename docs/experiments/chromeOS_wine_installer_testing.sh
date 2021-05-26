#!/bin/bash

# To run this script, you must first enable Linux (Beta) for Chrome OS from within your settings menu.  You should allocate about 5 GB for the Linux VM/partition.
# Follow the guide at this link for more information: https://support.google.com/chromebook/answer/9145439?hl=en
# You probably won't have to enable the "Allow Linux access your microphone" setting

# If your Chromebook is pretty old or slow, VARA may not play audio correctly and may not be usable.  For example, my Dell Inspiron 3181 (Intel Celeron N3060 @ 1.60GHz, x86-64, 3.795 GB RAM, with Chrome Version 87.0.4280.152) wasn't fast enough to run VARA through RMS Express without audio glitches.  You can find ChromeOS system specs using thirdparty extensions like COG System Info Viewer.  You can also open the chrome browser and find some more info by typing  chrome://system/ to find out your system specs. 
# VARA may have some graphics glitches on Chrome OS, but should otherwise work to play and hear tones when used with RMS Express if your processor is fast enough.

################ Winlink & VARA Installer Script for Chrome OS ################
# Author: Eric Wiessner (KI7POL)                                              #
# Version: Rough draft (NOT FUNCTIONAL YET!)                                  #
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
winelink_dir=$(pwd)
sudo apt-get install p7zip-full -y

############  Clean up files from any failed past runs of this script ############
rm -rf $winelink_dir/downloads/
clear

############  Setup the ChromeOS to run Windows .exe files ############ 
# To run Windows .exe files on ChromeOS, we need an x86 emulator (box86) and a Windows API Call interpreter (wine)
# Box86 is opensource and runs about 10x faster than ExaGear or Qemu.  It's much smaller and easier to install too.

mkdir $winelink_dir/downloads/


# Find system and hardware info
uname -m # find hardware architecture (x86_64 is 64bit)
#chromebook returns x86_64

# if exist /etc/apt/sources.list.d/cros.list (which may contain "deb https://storage.googleapis.com/cros-packages/87 buster main") then we're probably running chrome OS
# may also be a file named "/etc/apt/sources.list.d/google-chrome.list.1"

cat /etc/os-release # Displays lots of system info:
#PRETTY_NAME="Debian GNU/Linux 10 (buster)"
#NAME="Debian GNU/Linux"
#VERSION_ID="10"
#VERSION="10 (buster)"
#VERSION_CODENAME=buster
#ID=debian
#HOME_URL="https://www.debian.org/"
#SUPPORT_URL="https://www.debian.org/support"
#BUG_REPORT_URL="https://bugs.debian.org/"

#cat /etc/issue # Shows "Debian GNU/Linux 10 \n \l" on my Chromebook

sudo apt-get update && sudo apt-get dist-upgrade -y
sudo apt-get install p7zip-full -y # We'll need this later
#sudo apt-get install nano

# Install wine from the official winehq repo (don't just install wine from the Debian repos - they sometimes have missing DLL/internet support)
wget -O - https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -
#sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/debian/ buster main' # this line only works if add-apt-repository is installed
echo "deb https://dl.winehq.org/wine-builds/debian/ buster main" | sudo tee -a /etc/apt/sources.list
#sudo apt-get update

#Wine 4.5+ needs libfaudio0 before wine-staging will install, otherwise it will tell you about missing dependencies
wget https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10/Release.key
sudo apt-key add Release.key
#sudo apt-add-repository 'deb https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10/ ./'
echo "deb https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10/ ./" | sudo tee -a /etc/apt/sources.list
#sudo apt-get update

sudo apt-get update
sudo apt install libfaudio0 -y

# Wine 5.13 comes with TwisterOS, so we'll use that version
sudo apt-get install --install-recommends wine-staging-i386=5.13~buster -y #32bit core?
sudo apt-get install --install-recommends wine-staging-amd64=5.13~buster -y #64bit core? Seems to be required for chrome OS (but not for Pi)
sudo apt-get install --install-recommends wine-staging=5.13~buster -y #executables?
sudo apt-get install --install-recommends winehq-staging=5.13~buster -y #shortcuts?

# Install winetricks
wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
sudo chmod +x winetricks
sudo mv -v winetricks /usr/local/bin
sudo apt-get install cabextract -y # needed for winetricks to work
#sudo apt-get install winbind -y # And accept the user prompt: "yes"

# Initialize Wine silently (make a fresh wineprefix)
DISPLAY=0 WINEARCH=win32 wineboot # silently makes a fresh wineprefix in ~/.wine and skips installation of mono & gecko # win32 is required for ChromeOS

### Setup Wine (install system requirements for Winlink & VARA into our wineprefix)
winetricks -q corefonts dotnet35sp1 vb6run win7 sound=alsa # for RMS Express
winetricks -q vcrun2015 pdh # for VARA (run pdh here just for the winecfg dll override)


#################################################
#The rest of these commands should be uniform for all OS's since they set up wine



# Install official Windows NT 4.0 pdh.dll for VARA (the pdh.dll that "winetricks pdh" installs is too new for VARA)
cd $winelink_dir/downloads
wget http://download.microsoft.com/download/winntsrv40/update/5.0.2195.2668/nt4/en-us/nt4pdhdll.exe
7z x nt4pdhdll.exe pdh.dll
mv pdh.dll ~/.wine/drive_c/windows/system32
rm nt4pdhdll.exe # clean up

rm -rf ~/.cache/winetricks/ # clean up cached Microsoft installers now that we're done setting up Wine


### Setup AutoHotKey and make some .ahk scripts we'll use later
cd $winelink_dir/
mkdir ahk; cd ahk
wget https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.0.48.05/AutoHotkey104805_Install.exe
7z x AutoHotkey104805_Install.exe AutoHotkey.exe
sudo chmod +x AutoHotkey.exe
rm AutoHotkey104805_Install.exe # Clean up

#Create vara_install.ahk
echo '; AHK script to make VARA installer run completely silent'                       >> $winelink_dir/ahk/vara_install.ahk
echo 'SetTitleMatchMode, 2'                                                            >> $winelink_dir/ahk/vara_install.ahk
echo 'SetTitleMatchMode, slow'                                                         >> $winelink_dir/ahk/vara_install.ahk
echo '        Run, VARA setup (Run as Administrator).exe /SILENT, C:\'                 >> $winelink_dir/ahk/vara_install.ahk
echo '        WinWait, VARA Setup ; Wait for the "VARA installed successfully" window' >> $winelink_dir/ahk/vara_install.ahk
echo '        ControlClick, Button1, VARA Setup ; Click the OK button'                 >> $winelink_dir/ahk/vara_install.ahk
echo '        WinWaitClose'                                                            >> $winelink_dir/ahk/vara_install.ahk

#Create vara_setup.ahk
echo '; AHK script to assist users in setting up VARA on its first run'                >> $winelink_dir/ahk/vara_setup.ahk
echo 'SetTitleMatchMode, 2'                                                            >> $winelink_dir/ahk/vara_setup.ahk
echo 'SetTitleMatchMode, slow'                                                         >> $winelink_dir/ahk/vara_setup.ahk
echo '        Run, VARA.exe, C:\VARA'                                                  >> $winelink_dir/ahk/vara_setup.ahk
echo '        WinActivate, VARA HF'                                                    >> $winelink_dir/ahk/vara_setup.ahk
echo '        WinWait, VARA HF ; Wait for VARA to open'                                >> $winelink_dir/ahk/vara_setup.ahk
echo '        Sleep 3500 ; If we dont wait at least 2000 for VARA then AHK wont work'  >> $winelink_dir/ahk/vara_setup.ahk
echo '        Send, !{s} ; Open SoundCard menu'                                        >> $winelink_dir/ahk/vara_setup.ahk
echo '        Sleep 500'                                                               >> $winelink_dir/ahk/vara_setup.ahk
echo '        Send, {Down}'                                                            >> $winelink_dir/ahk/vara_setup.ahk
echo '        Sleep, 100'                                                              >> $winelink_dir/ahk/vara_setup.ahk
echo '        Send, {Enter}'                                                           >> $winelink_dir/ahk/vara_setup.ahk
echo '        Sleep 500'                                                               >> $winelink_dir/ahk/vara_setup.ahk
echo '        WinWaitClose, SoundCard ; Wait for user to finish setting up soundcard'  >> $winelink_dir/ahk/vara_setup.ahk
echo '        Sleep 50'                                                                >> $winelink_dir/ahk/vara_setup.ahk
echo '        WinClose, VARA HF ; Close VARA'                                          >> $winelink_dir/ahk/vara_setup.ahk






############  Install Winlink and VARA (into our configured wineprefix) ############
### Download/extract/install Winlink Express (formerly RMS Express) [https://downloads.winlink.org/User%20Programs/]
cd $winelink_dir/downloads

wget -r -l1 -np -nd -A "Winlink_Express_install_*.zip" https://downloads.winlink.org/User%20Programs # Download Winlink no matter its version number

7z x Winlink_Express_install_*.zip -o"WinlinkExpressInstaller"
    wine $winelink_dir/downloads/WinlinkExpressInstaller/Winlink_Express_install.exe /SILENT
    cp ~/.local/share/applications/wine/Programs/RMS\ Express/Winlink\ Express.desktop ~/Desktop/ # Make desktop shortcut.  FIX ME: Run a script instead with wineserver -k in front of it

rm Winlink_Express_install_*.zip # clean up
rm -rf WinlinkExpressInstaller # clean up


### Download/extract/install VARA HF (or newer) [https://rosmodem.wordpress.com/]
sudo apt-get install megatools -y

cd $winelink_dir/downloads
VARALINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?<=<a href=").*?(?=" target="_blank" rel="noopener noreferrer">VARA HF v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
megadl ${VARALINK}

7z x VARA*.zip -o"VARAInstaller"
    mv $winelink_dir/downloads/VARAInstaller/VARA\ setup*.exe ~/.wine/drive_c/ # Move VARA installer here so AHK can find it
    # The VARA installer prompts the user to hit 'OK' even during silent install (due to a secondary installer).  We will suppress this prompt with AHK.
    wine $winelink_dir/ahk/AutoHotkey.exe $winelink_dir/ahk/vara_install.ahk
    cp ~/.local/share/applications/wine/Programs/VARA/VARA.desktop ~/Desktop/ # Make desktop shortcut.  FIX ME: Run a script instead with wineserver -k in front of it

rm VARA*.zip # clean up
rm ~/.wine/drive_c/VARA\ setup*.exe # clean up
rm -rf VARAInstaller # clean up




###### Configure Winlink and VARA ######
clear
echo 
echo "In winecfg, go to the Audio tab to set up your default in/out soundcards."
winecfg
clear



### Fix some VARA graphics glitches caused by Wine's window manager (otherwise VARA appears as a black screen when auto-run by RMS Express)
# Make sure "Allow the window manager to control the windows" is unchecked in winecfg's Graphics tab
# NEEDS FIXING
RESULT=$(grep '"Managed"="Y"' ~/.wine/user.reg)
if [ "$RESULT" == '"Managed"="Y"' ]
then
    sed -i 's/"Managed"="Y"/"Managed"="N"/g' ~/.wine/user.reg
fi    # if wine already enabled window manager control then disable it

RESULT=$(grep '"Managed"="N"' ~/.wine/user.reg)
if [ "$RESULT" == '"Managed"="N"' ]
then
    : # if wine has window manager control disabled, then do nothing
else
    echo '' >> ~/.wine/user.reg
    echo '[Software\\Wine\\X11 Driver] 1614196385' >> ~/.wine/user.reg
    echo '#time=1d70ae6ab06f57a' >> ~/.wine/user.reg
    echo '"Decorated"="Y"' >> ~/.wine/user.reg
    echo '"Managed"="N"' >> ~/.wine/user.reg
fi    # if wine doesn't have any window manager control setting preferences yet, then set them as disabled



### Set up VARA (with some help from AutoHotKey)
clear
echo 
echo "Please set up your soundcard input/output for VARA"
#wine ~/.wine/drive_c/VARA/VARA.exe
wine $winelink_dir/ahk/AutoHotkey.exe $winelink_dir/ahk/vara_setup.ahk


clear
echo "In RMS Express, enter your callsign, password, gridsquare, and soundcard in/out, then close the program.  Ignore any errors for now."
wine ~/.wine/drive_c/RMS\ Express/RMS\ Express.exe

clear
echo "We're going to run Winlink a few more times so it can shake some bugs out"
wineserver -k
wine ~/.wine/drive_c/RMS\ Express/RMS\ Express.exe
wineserver -k
wine ~/.wine/drive_c/RMS\ Express/RMS\ Express.exe


