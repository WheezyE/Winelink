#!/bin/bash

########### Winlink & VARA Installer Script for the Raspberry Pi 4B ###########
# Author: Eric Wiessner (KI7POL)                                              #
# Version: 0.001a (Work in progress - lots of bugs!)                          #
# Credits:                                                                    #
#   The Box86 team                                                            #
#      (ptitSeb, pale, chills340, Heasterian, phoenixbyrd, Icenowy, Longhorn, #
#       SpacingBat3, monkaBlyat, Botspot, epychan, !FlameKat53, #lukefrenner, #
#       luschia, #MonthlyDoseOfRPi, Binay Devkota, hacker420, et.al.)         #
#   K6ETA & DCJ21's Winlink on Linux guides                                   #
#   KM4ACK & OH8STN for inspiration                                           #
#   N7ACW & AD7HE for getting me started in ham radio                         #
#                                                                             #
#    "My humanity is bound up in yours, for we can only be human together"    #
#                                                - Nelson Mandela             #
#                                                                             #
# If you like this project and want to see RMS Express crash less, then       #
#   please donate to Sebastien Chevalier and tell him you'd like to see       #
#   more compatability for Winlink & .NET in Box86.                           #
#                         -  paypal.me/0ptitSeb  -                            #
#                                                                             #
###############################################################################

# About:
#    This script will help you install Box86, Wine, winetricks, Windows DLL's, Winlink (RMS Express) & VARA.  You will then
#    be asked to configure RMS Express & VARA to send/receive audio from a USB sound card plugged into your Pi.  This installer 
#    will only work on the Raspberry Pi 4B for now.  If you would like to use an older Raspberry Pi (3B+, 3B, 2B, Zero, for 
#    example), software may run very slow and you may need to compile a custom 2G/2G split memory kernel before installing.
#
#    To run Windows .exe files on RPi4, we need an x86 emulator (box86) and a Windows API Call interpreter (wine).
#    Box86 is opensource and runs about 10x faster than ExaGear or Qemu.  It's much smaller and easier to install too.
#
#    This installer should take about 70 minutes on a Raspberry Pi 4B.
#
# Distribution:
#    This script is free to use, open-source, and should not be monetized.  If you use this script in your project (or are inspired by it) just please be sure to mention ptitSeb, Box86, and myself (KI7POL).
#
# Legal:
#    All software used by this script is free and legal to use (with the exception of VARA, of course, which is shareware).  Box86 and Wine are both open-source (which avoids the legal problems of use & distribution that ExaGear had - ExaGear also ran much slower than Box86 and is no-longer maintained, despite what Huawei says these days).  All proprietary Windows DLL files required by Wine are downloaded directly from Microsoft and installed according to their redistribution guidelines.
#
# Known bugs:
#    RMS Express and VARA have lots of crashes.  Just ignore any error/crash messages that come up until the program truly crashes. Use 'wineserver -k' to restart everything if you get a freeze.
#    The Channel Selector is functional, it just takes about 5 minutes to update its propagation indices and sometimes crashes the first time it's loaded.  Just restart it if it crashes.  If you let it run for 5 minutes, then you shouldn't have to do that again - just don't hit the Update Table Via Internet button.  I'm currently experimenting with ITS HF: http://www.greg-hand.com/hfwin32.html
#    VARA has some graphics issues if we leave window control on in Wine.  Leaving window control on in Wine is a good idea for RPi4 since it reduces CPU overhead.
#
# Donations:
#    If you feel that you are able and would like to support this project, please consider sending donations to ptitSeb or KM4ACK - without whom, this script would not exist.
#        - Sebastien "ptitSeb" Chevalier - author of "Box86": paypal.me/0ptitSeb
#        - Jason Oleham (KM4ACK) - inspiration & Linux elmer: paypal.me/km4ack
#

function run_main()
{
        ### Clean up files left over from any failed past runs of this script
        rm -rf Winelink && mkdir Winelink && cd Winelink
        rm ~/Desktop/Reset\ Wine


        ### Hello world
        run_greeting
        #timer_start=$SECONDS


        ### Install software on our operating system
        run_downloadbox86 1_Jan_21 # Aiming for commit db5efa89. (12_Jun_21 was also a promising date for 681e06)
        #run_buildbox86 db5efa89085a085d733c859662799ebcf4e5c3c2 # this version of box86 installs dotnet35sp1 but doesn't run RMS Express. 681e06ce73c0c5ec6eebd39b57b627bec03242a6 might cause a broken dotnet35sp1 install but installation says that it completes

        run_installwine # Download and install Wine 5.21 devel buster for i386
        rm -rf ~/.cache/wine # make sure we don't install mono or gecko (if their msi files are in wine cache)
        DISPLAY=0 wineboot # Initialize Wine silently - silently makes a fresh wineprefix in ~/.wine and skips installation of mono & gecko

        run_installwinetricks


        ### Configure our wineprefix
        BOX86_NOBANNER=1 winetricks -q dotnet35sp1 win7 sound=alsa # for RMS Express. corefonts & vcrun2015 do not appear to be needed
        BOX86_NOBANNER=1 winetricks -q vb6run pdh_nt4 # for VARA
        #BOX86_NOBANNER=1 winetricks -q riched30 richtx32 crypt32 comctl32ocx comdlg32ocx # These have helped Box86 Box86 compatibility in the past (to cover any wine libraries that aren't wrapped in Box86 yet)
        rm -rf ~/.cache/winetricks/ # clean up cached Microsoft installers now that we're done setting up Wine

        clear
        #timer_duration=$(( SECONDS - timer_start )) && echo "Setting up our wineprefix took" $timer_duration "seconds."
        echo ""
        echo "In winecfg, go to the Audio tab to set up your default in/out soundcards."
        BOX86_NOBANNER=1 winecfg # Nobanner option here just to make the console look prettier
        
        
        ### KLUDGE: Download & Install an older Box86 that works with RMS Express # Aiming for commit cad16020.
        run_downloadbox86 30_Jan_21
        #run_buildbox86 cad160205fd9a267e6c3d9d784fbef72b1c68dde # VARA & RMS Express work. Also try 6a498c373c35ed2542a9667617abb96c4c767036
        
        
        ### Install Winlink & VARA into our configured wineprefix
        run_installrms
        run_installvara
        
        
        ### Post-install
        run_makerestartscript
        
        RED='\033[0;31m' # Red text color
        NC='\033[0m' # Regular text color
        clear
        echo ""
        echo "We will now run RMS Express."
        echo "Please enter your callsign and Winlink password, click 'Update', then let"
        echo "RMS Express run for a few moments before closing the program."
        echo ""
        echo -e "${RED}If you click the buttons of any error pop-ups, RMS Express will crash.${NC}"
        echo -e "${RED}Just ignore any error messages that pop-up.  Don't click on their buttons.${NC}"
        echo ""
        echo "If RMS Express freezes or won't re-open, click 'Wine Restart' on the desktop"
        echo "and try running RMS Express again."
        echo ""
        echo "Press any key to continue . . ."
        echo "(Also please ignore any error messages in the terminal below this message.)"
        echo ""
        echo ""
        read -n 1 -s -r -p ""
        wine ~/.wine/drive_c/RMS\ Express/RMS\ Express.exe
        
        clear
        echo ""
        echo "Setup complete."
        echo ""
        echo "Press any key to continue . . ."
        echo ""
        echo ""
        read -n 1 -s -r -p ""
        wineserver -k
        exit
}

























function run_greeting()
{
clear
echo ""
echo "########### Winlink & VARA Installer Script for the Raspberry Pi 4B ###########"
echo "# Author: Eric Wiessner (KI7POL)                                              #"
echo "# Version: 0.001a (Work in progress - lots of bugs!)                          #"
echo "# Credits:                                                                    #"
echo "#   The Box86 team                                                            #"
echo "#      (ptitSeb, pale, chills340, Heasterian, phoenixbyrd, Icenowy, Longhorn, #"
echo "#       SpacingBat3, monkaBlyat, Botspot, epychan, !FlameKat53, #lukefrenner, #"
echo "#       luschia, #MonthlyDoseOfRPi, Binay Devkota, hacker420, et.al.)         #"
echo "#   K6ETA & DCJ21's Winlink on Linux guides                                   #"
echo "#   KM4ACK & OH8STN for inspiration                                           #"
echo "#   N7ACW & AD7HE for getting me started in ham radio                         #"
echo "#                                                                             #"
echo "#    \"My humanity is bound up in yours, for we can only be human together\"    #"
echo "#                                                - Nelson Mandela             #"
echo "#                                                                             #"
echo "# If you like this project and want to see RMS Express crash less, then       #"
echo "#   please donate to Sebastien Chevalier and tell him you'd like to see       #"
echo "#   more compatability for Winlink & .NET in Box86.                           #"
echo "#                         -  paypal.me/0ptitSeb  -                            #"
echo "#                                                                             #"
echo "###############################################################################"
read -n 1 -s -r -p "Press any key to continue . . ."
clear
}

function run_downloadbox86()
{ # Download & Install Box86. This function needs a date passed to it.
    sudo apt-get install p7zip-full -y
    local date="$1"
    
    mkdir box86; cd box86
        sudo rm /usr/local/bin/box86 # in case box86 is already installed and running
        wget https://archive.org/download/box86.7z_20200928/box86_"$date".7z
        7z x box86_"$date".7z
        sudo cp box86_"$date"/build/system/box86.conf /etc/binfmt.d/
        sudo cp box86_"$date"/build/box86 /usr/local/bin/box86
        sudo cp box86_"$date"/x86lib/* /usr/lib/i386-linux-gnu/
        sudo systemctl restart systemd-binfmt # must be run after first installation of box86 (initializes binfmt configs so any encountered i386 binaries are sent to box86)
    cd ..
}

function run_buildbox86()
{ # Build & Install Box86. This function needs a date passed to it.
    sudo apt-get install cmake git -y
    local commit="$1"
    
    mkdir box86; cd box86
        rm -rf box86-builder; mkdir box86-builder && cd box86-builder/
            git clone https://github.com/ptitSeb/box86 && cd box86/
                git checkout "$commit"
                mkdir build; cd build
                    cmake .. -DRPI4=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
                    make -j4
                    sudo make install # copies box86 files into their directories (/usr/local/bin/box86, /usr/lib/i386-linux-gnu/, /etc/binfmt.d/)
                cd ..
            cd ..
        cd ..
    cd ..
    sudo systemctl restart systemd-binfmt # must be run after first installation of box86 (initializes binfmt configs so any encountered i386 binaries are sent to box86)
}

function run_installwine() # Fix directories so that they're not hardcoded
{
    mkdir downloads; cd downloads
        wineserver -k # stop any old Wine installations from running
        
        # Backup old wine
        rm -rf ~/wine-old; mv ~/wine ~/wine-old
        rm -rf ~/.wine-old; mv ~/.wine ~/.wine-old
        sudo mv /usr/local/bin/wine /usr/local/bin/wine-old
        sudo mv /usr/local/bin/wineboot /usr/local/bin/wineboot-old
        sudo mv /usr/local/bin/winecfg /usr/local/bin/winecfg-old
        sudo mv /usr/local/bin/wineserver /usr/local/bin/wineserver-old

        # Download, extract wine, and install wine
        # (Replace the links/versions below with links/versions from the WineHQ site for the version of wine you wish to install. Note that we need the i386 version for Box86 even though we're installing it on our ARM processor.)
        # (Pick an i386 version of wine-devel, wine-staging, or wine-stable)
        wget https://dl.winehq.org/wine-builds/debian/dists/buster/main/binary-i386/wine-devel-i386_5.21~buster_i386.deb # NOTE: Replace this link with the version you want
        wget https://dl.winehq.org/wine-builds/debian/dists/buster/main/binary-i386/wine-devel_5.21~buster_i386.deb  # NOTE: Also replace this link with the version you want
        dpkg-deb -xv wine-devel-i386_5.21~buster_i386.deb wine-installer # NOTE: Make sure these dpkg command matches the filename of the deb package you just downloaded
        dpkg-deb -xv wine-devel_5.21~buster_i386.deb wine-installer
        mv wine-installer/opt/wine* ~/wine

        # Install shortcuts (make 32bit launcher & symlinks. Credits: grayduck, Botspot)
        echo -e '#!/bin/bash\nsetarch linux32 -L '"$HOME/wine/bin/wine "'"$@"' | sudo tee -a /usr/local/bin/wine >/dev/null # Create a script to launch wine programs as 32bit only
        #sudo ln -s ~/wine/bin/wine /usr/local/bin/wine # You could also just make a symlink, but box86 only works for 32bit apps at the moment
        sudo ln -s ~/wine/bin/wineboot /usr/local/bin/wineboot
        sudo ln -s ~/wine/bin/winecfg /usr/local/bin/winecfg
        sudo ln -s ~/wine/bin/wineserver /usr/local/bin/wineserver
        sudo chmod +x /usr/local/bin/wine /usr/local/bin/wineboot /usr/local/bin/winecfg /usr/local/bin/wineserver

        # These packages are needed for running wine-staging on RPi 4 (Credits: chills340)
        #sudo apt-get install libstb0 -y
        #wget http://ftp.us.debian.org/debian/pool/main/f/faudio/libfaudio0_20.11-1~bpo10+1_i386.deb
        #wget -r -l1 -np -nd -A "libfaudio0_*~bpo10+1_i386.deb" http://ftp.us.debian.org/debian/pool/main/f/faudio/ # Download libfaudio i386 no matter its version number
        #dpkg-deb -xv libfaudio0_*~bpo10+1_i386.deb libfaudio
        #sudo cp -TRv libfaudio/usr/ /usr/
    cd ..
}

function run_installwinetricks()
{
    mkdir downloads; cd downloads
        # Download & install winetricks
        sudo apt-get install cabextract -y # winetricks needs this
        sudo mv /usr/local/bin/winetricks /usr/local/bin/winetricks-old # backup old winetricks
        wget https://raw.githubusercontent.com/Winetricks/winetricks/7d10e264cb21a80b80e3fa4713625f561b024879/src/winetricks
        ##!##wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks # download
        sudo chmod +x winetricks 
        sudo mv winetricks /usr/local/bin # install
    cd ..
}

function run_installrms()  # Fix directories so that they're not hardcoded
{
    mkdir downloads; cd downloads
        # Download/extract/install Winlink Express (formerly RMS Express) [https://downloads.winlink.org/User%20Programs/]
        wget -r -l1 -np -nd -A "Winlink_Express_install_*.zip" https://downloads.winlink.org/User%20Programs # Download Winlink no matter its version number
        
        #We could also use curl if we don't want to use wget to find the link . . .
        #RMSLINKPREFIX="https://downloads.winlink.org"
        #RMSLINKSUFFIX=$(curl -s https://downloads.winlink.org/User%20Programs/ | grep -oP '(?=/User%20Programs/Winlink_Express_install_).*?(\.zip).*(?=">Winlink_Express_install_)')
        #RMSLINK=$RMSLINKPREFIX$RMSLINKSUFFIX
        #wget $RMSLINK

        7z x Winlink_Express_install_*.zip -o"WinlinkExpressInstaller"
        wine WinlinkExpressInstaller/Winlink_Express_install.exe /SILENT
        cp ~/.local/share/applications/wine/Programs/RMS\ Express/Winlink\ Express.desktop ~/Desktop/ # Make desktop shortcut.  FIX ME: Run a script instead with wineserver -k in front of it
    cd ..
}

function run_installvara()  # Fix directories so that they're not hardcoded
{
    sudo apt-get install megatools curl p7zip-full -y
    
    mkdir downloads; cd downloads
        # Download / extract / install VARA HF [https://rosmodem.wordpress.com/]
        VARALINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA HF v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
        megadl ${VARALINK}
        7z x VARA*.zip -o"VARAInstaller"
        cp VARAInstaller/VARA\ setup*.exe ~/.wine/drive_c/ # Move VARA installer here so AHK can find it later
    cd ..
        
    mkdir ahk; cd ahk
        # Download AutoHotKey
        wget https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.0.48.05/AutoHotkey104805_Install.exe
        7z x AutoHotkey104805_Install.exe AutoHotkey.exe
        sudo chmod +x AutoHotkey.exe
    
        # The VARA installer prompts the user to hit 'OK' even during silent install (due to a secondary installer).  We will suppress this prompt with AHK.
        #Create vara_install.ahk
        echo '; AHK script to make VARA installer run completely silent'                       >> vara_install.ahk
        echo 'SetTitleMatchMode, 2'                                                            >> vara_install.ahk
        echo 'SetTitleMatchMode, slow'                                                         >> vara_install.ahk
        echo '        Run, VARA setup (Run as Administrator).exe /SILENT, C:\'                 >> vara_install.ahk
        echo '        WinWait, VARA Setup ; Wait for the "VARA installed successfully" window' >> vara_install.ahk
        echo '        ControlClick, Button1, VARA Setup ; Click the OK button'                 >> vara_install.ahk
        echo '        WinWaitClose'                                                            >> vara_install.ahk
        wine AutoHotkey.exe vara_install.ahk # Install VARA silently using AHK
        
        cp ~/.local/share/applications/wine/Programs/VARA/VARA.desktop ~/Desktop/ # Make desktop shortcut.
        rm ~/.wine/drive_c/VARA\ setup*.exe # clean up

        # VARA then needs the user to configure their soundcard input/output.  We will guide the user to the VARA audio setup menu.
        clear
        echo ""
        echo "Please set up your soundcard input/output for VARA"

        #Create vara_configure.ahk
        echo '; AHK script to assist users in setting up VARA on its first run'                >> vara_configure.ahk
        echo 'SetTitleMatchMode, 2'                                                            >> vara_configure.ahk
        echo 'SetTitleMatchMode, slow'                                                         >> vara_configure.ahk
        echo '        Run, VARA.exe, C:\VARA'                                                  >> vara_configure.ahk
        echo '        WinActivate, VARA HF'                                                    >> vara_configure.ahk
        echo '        WinWait, VARA HF ; Wait for VARA to open'                                >> vara_configure.ahk
        echo '        Sleep 3500 ; If we dont wait at least 2000 for VARA then AHK wont work'  >> vara_configure.ahk
        echo '        Send, !{s} ; Open SoundCard menu'                                        >> vara_configure.ahk
        echo '        Sleep 500'                                                               >> vara_configure.ahk
        echo '        Send, {Down}'                                                            >> vara_configure.ahk
        echo '        Sleep, 100'                                                              >> vara_configure.ahk
        echo '        Send, {Enter}'                                                           >> vara_configure.ahk
        echo '        Sleep 5000'                                                              >> vara_configure.ahk
        echo '        WinWaitClose, SoundCard ; Wait for user to finish setting up soundcard'  >> vara_configure.ahk    # This line may need some debugging
        echo '        Sleep 100'                                                               >> vara_configure.ahk
        echo '        WinClose, VARA HF ; Close VARA'                                          >> vara_configure.ahk

        BOX86_NOBANNER=1 wine AutoHotkey.exe vara_configure.ahk # Nobanner option here just to make the console look prettier
    cd ..
    
    ## Do this last - Fix some VARA graphics glitches caused by Wine's (wincfg) window manager (otherwise VARA appears as a black screen when auto-run by RMS Express)
    ## NOTE: It might actually be better to keep this disabled for Pi 4B and weaker processors to reduce CPU overhead with extra graphics and prevent freezes.
    ##Create override-x11.reg
    #echo 'REGEDIT4'                                      >> override-x11.reg
    #echo ''                                              >> override-x11.reg
    #echo '[HKEY_CURRENT_USER\Software\Wine\X11 Driver]'  >> override-x11.reg
    #echo '"Decorated"="Y"'                               >> override-x11.reg
    #echo '"Managed"="N"'                                 >> override-x11.reg
    #wine cmd /c regedit /s override-x11.reg
}

function run_makerestartscript()
{
    # RMS Express & VARA crash or freeze often. It would help users to have a 'rest button' on their desktop for these crashes.
    #Create Reset\ Wine.sh
    echo '#!/bin/bash'   >> ~/Desktop/Reset\ Wine
    echo ''              >> ~/Desktop/Reset\ Wine
    echo 'wineserver -k' >> ~/Desktop/Reset\ Wine
    echo 'zenity --info --timeout=8 --height 150 --width 500 --text="Resetting Wine now so that Winlink Express and VARA will run again.\\n\\nIf you try to run RMS Express again and it crashes or doesn'\''t open, just keep trying to run it.  It should open eventually after enough tries." --title="Resetting Wine to help RMS Express"'          >> ~/Desktop/Reset\ Wine
    sudo chmod +x ~/Desktop/Reset\ Wine
}

run_main "$@"; exit # Run the "run_main" function after all other functions have been defined in bash.  This allows us to keep our main code at the top of the script.
