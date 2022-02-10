#!/bin/bash

function run_greeting()
{
    clear
    echo ""
    echo "########### Winlink & VARA Installer Script for the Raspberry Pi 4B ###########"
    echo "# Author: Eric Wiessner (KI7POL)                    Install time: apx 30 min  #"
    echo "# Version: 0.0087a (Work in progress)                                         #"
    echo "# Credits:                                                                    #"
    echo "#   The Box86 team (ptitSeb, pale, chills340, Itai-Nelken, Heasterian, et al) #"
    echo "#   Esme 'madewokherd' Povirk (CodeWeavers) for wine-mono debugging/support   #"
    echo "#   N7ACW, AD7HE, & KK6FVG for getting me started in ham radio                #"
    echo "#   KM4ACK & OH8STN for inspiration                                           #"
    echo "#   K6ETA & DCJ21's Winlink on Linux guides                                   #"
    echo "#                                                                             #"
    echo "#    \"My humanity is bound up in yours, for we can only be human together\"    #"
    echo "#                                                - Nelson Mandela             #"
    echo "#                                                                             #"
    echo "# If you like this project please consider donating to Sebastien Chevalier    #"
    echo "#   (the creator of box86) or CodeWeavers (wine, wine-mono).                  #"
    echo "#                                                                             #"
    echo "#                  - Donate to Box86:  paypal.me/0ptitSeb -                   #"
    echo "#    - Support Esme & CodeWeavers: https://www.codeweavers.com/crossover -    #"
    echo "#       - Donate to Wine / wine-mono:  https://www.winehq.org/donate -        #"
    echo "###############################################################################"
    read -n 1 -s -r -p "Press any key to continue . . ."
    clear
}

# About:
#    This script will help you install Box86, Wine, winetricks, Windows DLL's, Winlink (RMS Express) & VARA.  You will then
#    be asked to configure RMS Express & VARA to send/receive audio from a USB sound card plugged into your Pi.  This installer 
#    will only work on the Raspberry Pi 4B for now.  If you would like to use an older Raspberry Pi (3B+, 3B, 2B, Zero, for 
#    example), software may run very slow and you may need to compile a custom 2G/2G split memory kernel before installing.
#
#    To run Windows .exe files on RPi4, we need an x86 emulator (box86) and a Windows API Call interpreter (wine).
#    Box86 is opensource and runs about 10x faster than ExaGear or Qemu.  It's much smaller and easier to install too.
#
#    This installer should take about 30 minutes on a Raspberry Pi 4B.
#
# Distribution:
#    This script is free to use, open-source, and should not be monetized.  If you use this script in your project (or are inspired by it) just please be sure to mention ptitSeb, Box86, and myself (KI7POL).
#
# Legal:
#    All software used by this script is free and legal to use (with the exception of VARA, of course, which is shareware).  Box86 and Wine are both open-source (which avoids the legal problems of use & distribution that ExaGear had - ExaGear also ran much slower than Box86 and is no-longer maintained, despite what Huawei says these days).  All proprietary Windows DLL files required by Wine are downloaded directly from Microsoft and installed according to their redistribution guidelines.
#
# Known bugs:
#    If programs freeze, use 'wineserver -k' to restart wine.
#    The Channel Selector is functional, it just takes about 5 minutes to update its propagation indices and sometimes crashes the first time it's loaded.  Just restart it if it crashes.  If you let it run for 5 minutes, then you shouldn't have to do that again - just don't hit the Update Table Via Internet button.  I'm currently experimenting with ITS HF: http://www.greg-hand.com/hfwin32.html
#    VARA has some graphics issues if we leave window control on in Wine.  Leaving window control on in Wine is a good idea for RPi4 since it reduces CPU overhead.
#
# Donations:
#    If you feel that you are able and would like to support this project, please consider sending donations to ptitSeb or KM4ACK - without whom, this script would not exist.
#        - Sebastien "ptitSeb" Chevalier - author of "Box86": paypal.me/0ptitSeb
#        - Jason Oleham (KM4ACK) - inspiration & Linux elmer: paypal.me/km4ack
#
# Code overview:
#    This script has a main routine that runs subroutines.  Not all subroutines in this script are used - some are just for testing purposes.
#    This script just works for Raspberry Pi 4B at the moment, but I hope to one day have it detect CPU, OS, and distro, and install accordingly.
#


function run_main()
{
        local ARG="$1" # store the first argument passed to the script file as a variable here (i.e. 'bash install_winelink.sh vara_only')

        ### Pre-installation
            exec > >(tee "../winelink.log") 2>&1 # start logging
            run_checkpermissions
            run_checkxhost
            run_gather_os_info
            #run_detect_arch # TODO: Customize this section to install wine for different operating systems.
            rm -rf Winelink-tmp winelink.log 2>/dev/null; mkdir Winelink-tmp && cd Winelink-tmp # clean up any failed past runs of this script
            rm ~/Desktop/Reset\ Wine ~/Desktop/Update\ VARA ~/Desktop/VARA.desktop ~/Desktop/VARA\ Chat.desktop ~/Desktop/VARA\ FM.desktop ~/Desktop/Winlink\ Express.desktop 2>/dev/null # remove old winlink/wine desktop shortcuts (in case we are reinstalling wine)
            run_greeting
        
        ### Install Wine & winetricks
            run_installwine "pi4" "devel" "7.1" "debian" "${VERSION_CODENAME}" "-1" # windows API-call interperter for non-windows OS's - freeze version to ensure compatability
            run_installwinetricks # software installer script for wine
            run_downloadbox86 10_Dec_21 # emulator to run wine-i386 on ARM - freeze version to ensure compatability
            
        ### Set up Wine (silently make & configure a new wineprefix)
            if [ "$ARG" = "vara_only" ]; then
                run_setupwineprefix_varaonly
            else
                run_setupwineprefix
            fi
        
        ### Install Winlink & VARA into our configured wineprefix
            if [ "$ARG" = "vara_only" ]; then
                run_installvara
            else
                run_installrms
                run_installvara
                #run_installvARIM
            fi
        
        ### Post-installation
            run_makewineserverkscript
            run_makevaraupdatescript
            clear
            echo -e "\n${GREENTXT}Setup complete.${NORMTXT}\n"
            cd .. && rm -rf Winelink-tmp winelink.log # cleanup
            
        exit
}




############################################# Subroutines #############################################


function run_checkpermissions()  # Ensure that script is not run as root & that user account has sudo permissions
{
    # If user ran script as root, then exit (since wine should not be initialized as root)
    if [ "$(whoami)" = "root" ]; then
        echo -e "\n${GREENTXT}This script must not be run as root or sudo.${NORMTXT}\n"
        run_giveup
    fi
    
    # If user cannot run sudo commands, then exit (since we have lots of sudo commands in this script)
    sudo -l &> /dev/null || SUDOCHECK="no_sudo" # if an error returns from the command 'sudo -l' then set SUDOCHECK to "no_sudo"
    if [ "$SUDOCHECK" = "no_sudo" ]; then
        echo -e "\n${GREENTXT}Please give your user account sudoer access before running this script.${NORMTXT}\n"
        run_giveup
    fi
}

function run_checkxhost()  # Check to see if an xserver is running (ie are we in SSH? because we will need a GUI for the script to work)
{
    if ! xhost >& /dev/null ; then # credits: xylo04 - thank you for this function!
        echo "No X window session, this script must be run with a GUI"
        run_giveup
    fi
}

function run_downloadbox86()  # Download & install Box86. (This function needs a date passed to it)
{
    sudo apt-get install p7zip-full -y # TODO: remove redundant apt-get installs - put them at top of script.
    local date="$1"
    
    echo -e "\n${GREENTXT}Downloading and installing Box86 . . .${NORMTXT}\n"
    mkdir box86; cd box86
        sudo rm /usr/local/bin/box86 # in case box86 is already installed and running
        wget -q https://archive.org/download/box86.7z_20200928/box86_"$date".7z || { echo "box86_$date download failed!" && run_giveup; }
        7z x box86_"$date".7z
        sudo cp box86_"$date"/build/system/box86.conf /etc/binfmt.d/
        sudo cp box86_"$date"/build/box86 /usr/local/bin/box86
        sudo cp box86_"$date"/x86lib/* /usr/lib/i386-linux-gnu/
        sudo systemctl restart systemd-binfmt # must be run after first installation of box86 (initializes binfmt configs so any encountered i386 binaries are sent to box86)
    cd ..
}

function run_buildbox86()  # Build & install Box86. (This function needs a commit hash passed to it)
{
    sudo apt-get install cmake git -y
    local commit="$1"
    
    echo -e "\n${GREENTXT}Building and installing Box86 . . .${NORMTXT}\n"
    mkdir box86; cd box86
        rm -rf box86-builder; mkdir box86-builder && cd box86-builder/
            git clone https://github.com/ptitSeb/box86 && cd box86/
                git checkout "$commit"
                mkdir build; cd build
                    cmake .. -DRPI4=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
                    make #-j4 may cause crashes in some builds of box86 due to high cpu load
                    sudo make install # copies box86 files into their directories (/usr/local/bin/box86, /usr/lib/i386-linux-gnu/, /etc/binfmt.d/)
                cd ..
            cd ..
        cd ..
    cd ..
    sudo systemctl restart systemd-binfmt # must be run after first installation of box86 (initializes binfmt configs so any encountered i386 binaries are sent to box86)
}

function run_setupwineprefix()  # Set up a new wineprefix silently.  A wineprefix is kind of like a virtual harddrive for wine
{
    # Silently create a new wineprefix
        echo -e "\n${GREENTXT}Creating a new wineprefix.  This may take a moment . . .${NORMTXT}\n" 
        rm -rf ~/.cache/wine # make sure no old wine-mono files are in wine's cache, or else they will be auto-installed on first wineboot
        DISPLAY=0 WINEARCH=win32 wine wineboot # initialize Wine silently (silently makes a fresh wineprefix in `~/.wine`)

    # Install pre-requisite software into the wineprefix for RMS Express and VARA
        echo -e "\n${GREENTXT}Setting up your wineprefix for RMS Express & VARA . . .${NORMTXT}\n"
        run_installwinemono # wine-mono replaces dotnet46
        #BOX86_NOBANNER=1 winetricks -q win7 sound=alsa # for RMS Express # - TODO: This line may be redundant
        # - TODO: Check to see if 'winetricks -q corefonts riched20' would make text look nicer
        BOX86_NOBANNER=1 winetricks -q vb6run pdh_nt4 win7 sound=alsa # for VARA

    # Guide the user to the wineconfig audio menu (configure hardware soundcard input/output)
        sudo apt-get install zenity -y
        clear
        echo ""
        echo -e "\n${GREENTXT}In winecfg, go to the Audio tab to set up your system's in/out soundcards.\n(please click 'Ok' on the user prompt textbox to continue)${NORMTXT}"
        zenity --info --height 100 --width 350 --text="We will now setup your soundcards for Wine. \n\nPlease navigate to the Audio tab and choose your systems soundcards \n\nInstall will continue once you have closed the winecfg menu." --title="Wine Soundcard Setup"
        echo -e "${GREENTXT}Loading winecfg now . . .${NORMTXT}\n"
        echo ""
        BOX86_NOBANNER=1 winecfg # nobanner just for prettier terminal
        clear
}

function run_setupwineprefix_varaonly()  # TODO: This function is probably redundant now that we're using wine-mono
{
    # Silently create a new wineprefix
        echo -e "\n${GREENTXT}Creating a new wineprefix.  This may take a moment . . .${NORMTXT}\n" 
        rm -rf ~/.cache/wine # make sure no old wine-mono files are in wine's cache, or else they will be auto-installed on first wineboot
        DISPLAY=0 WINEARCH=win32 wine wineboot # initialize Wine silently (silently makes a fresh wineprefix in `~/.wine`)

    # Install pre-requisite software into the wineprefix for RMS Express and VARA
        echo -e "\n${GREENTXT}Setting up your wineprefix for RMS Express & VARA . . .${NORMTXT}\n"
        BOX86_NOBANNER=1 winetricks -q vb6run pdh_nt4 win7 sound=alsa # for VARA

    # Guide the user to the wineconfig audio menu (configure hardware soundcard input/output)
        sudo apt-get install zenity -y
        clear
        echo ""
        echo -e "\n${GREENTXT}In winecfg, go to the Audio tab to set up your system's in/out soundcards.\n(please click 'Ok' on the user prompt textbox to continue)${NORMTXT}"
        zenity --info --height 100 --width 350 --text="We will now setup your soundcards for Wine. \n\nPlease navigate to the Audio tab and choose your systems soundcards \n\nInstall will continue once you have closed the winecfg menu." --title="Wine Soundcard Setup"
        echo -e "${GREENTXT}Loading winecfg now . . .${NORMTXT}\n"
        echo ""
        BOX86_NOBANNER=1 winecfg # nobanner just for prettier terminal
        clear
}

function run_installwinemono()  # Wine-mono replaces MS.NET 4.6 and earlier.  MS.NET 4.6 takes a very long time to install on RPi4 in Wine
{
    sudo apt-get install p7zip-full -y
    
    mkdir ~/.cache/wine 2>/dev/null
    echo -e "\n${GREENTXT}Downloading and installing wine-mono . . .${NORMTXT}\n"
    #wget -q -P ~/.cache/wine https://github.com/madewokherd/wine-mono/releases/download/wine-mono-6.4.1/wine-mono-6.4.1-x86.msi || { echo "wine-mono .msi install file download failed!" && run_giveup; }
    #wine msiexec /i ~/.cache/wine/wine-mono-6.4.1-x86.msi # TODO: Updated this to an official release version of wine-mono that includes fixes for COM ports (as soon as link is available)
    
        # Kludge: Use a 'nightly build' of wine-mono until official wine-mono 7.1.3 is released
        # Link from https://github.com/madewokherd/mono/actions/runs/1773995893 (https://github.com/madewokherd/mono/pull/22)
        wget -q -P ~/.cache/wine https://nightly.link/madewokherd/mono/actions/artifacts/154265073.zip || { echo "wine-mono .msi install file download failed!" && run_giveup; }
        7z x ~/.cache/wine/154265073.zip -o"$HOME/.cache/wine/"
        wine msiexec /i ~/.cache/wine/wine-mono-7.1.1-x86.msi # wine-mono-7.1.1 might require wine-devel 6.19 or newer
    
    rm -rf ~/.cache/wine # clean up to save disk space
}

function run_installwine()  # Download and install Wine for i386 Debian Buster (This function needs variables passed to it)
                            #   (Example function variables: run_installwine "pi4" "devel" "7.1" "debian" "${VERSION_CODENAME}" "-1")
{
    # These variables are here in the hopes that more systems might be implemented in the future. For now, they just help change wine version more easily.
    local system="$1" #example: "pi4" - TODO: implement other systems, like pi3
    local branch="$2" #example: "devel" or "stable" without quotes (staging requires more install steps)
    local version="$3" #example: "7.1"
    local build="$4" #example: debian - TODO: implement other distros, like Ubuntu
    local dist="$5" #example: bullseye
    local tag="$6" #example: -1

    wineserver -k &> /dev/null # stop any old wine installations from running - TODO: double-check this command
    rm -rf ~/.cache/wine # remove any old wine-mono or wine-gecko install files in case wine was installed previously
    rm -rf ~/.local/share/applications/wine # remove any old program shortcuts
    mkdir downloads 2>/dev/null; cd downloads
        # Backup any old wine installs
            rm -rf ~/wine-old 2>/dev/null; mv ~/wine ~/wine-old 2>/dev/null
            rm -rf ~/.wine-old 2>/dev/null; mv ~/.wine ~/.wine-old 2>/dev/null
            sudo mv /usr/local/bin/wine /usr/local/bin/wine-old 2>/dev/null
            sudo mv /usr/local/bin/wineboot /usr/local/bin/wineboot-old 2>/dev/null
            sudo mv /usr/local/bin/winecfg /usr/local/bin/winecfg-old 2>/dev/null
            sudo mv /usr/local/bin/wineserver /usr/local/bin/wineserver-old 2>/dev/null

        # Download, extract, and install wine-i386 onto our armhf device
            echo -e "\n${GREENTXT}Downloading wine . . .${NORMTXT}"
            wget -q https://dl.winehq.org/wine-builds/debian/dists/${dist}/main/binary-i386/wine-${branch}-i386_${version}~${dist}${tag}_i386.deb || { echo "wine-${branch}-i386_${version}_i386.deb download failed!" && run_giveup; }
            wget -q https://dl.winehq.org/wine-builds/debian/dists/${dist}/main/binary-i386/wine-${branch}_${version}~${dist}${tag}_i386.deb || { echo "wine-${branch}_${version}_i386.deb download failed!" && run_giveup; }
            echo -e "${GREENTXT}Extracting wine . . .${NORMTXT}"
            dpkg-deb -x wine-${branch}-i386_${version}~${dist}${tag}_i386.deb wine-installer
            dpkg-deb -x wine-${branch}_${version}~${dist}${tag}_i386.deb wine-installer
            echo -e "${GREENTXT}Installing wine . . .${NORMTXT}\n"
            mv wine-installer/opt/wine* ~/wine

        # Install symlinks (and make 32bit launcher. Credits: grayduck, Botspot)
            echo -e '#!/bin/bash\nsetarch linux32 -L '"$HOME/wine/bin/wine "'"$@"' | sudo tee -a /usr/local/bin/wine >/dev/null # script to launch wine programs as 32bit only
            #sudo ln -s ~/wine/bin/wine /usr/local/bin/wine # you could also just make a symlink, but box86 only works for 32bit apps at the moment
            sudo ln -s ~/wine/bin/wineboot /usr/local/bin/wineboot
            sudo ln -s ~/wine/bin/winecfg /usr/local/bin/winecfg
            sudo ln -s ~/wine/bin/wineserver /usr/local/bin/wineserver
            sudo chmod +x /usr/local/bin/wine /usr/local/bin/wineboot /usr/local/bin/winecfg /usr/local/bin/wineserver
    cd ..
}

function run_installwinetricks() # Download and install winetricks
{
    sudo apt-get remove winetricks -y
    sudo apt-get install cabextract -y # winetricks needs this
    mkdir downloads 2>/dev/null; cd downloads
        echo -e "\n${GREENTXT}Downloading and installing winetricks . . .${NORMTXT}\n"
        sudo mv /usr/local/bin/winetricks /usr/local/bin/winetricks-old 2>/dev/null # backup any old winetricks installs
        wget -q https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks || { echo "winetricks download failed!" && run_giveup; } # download
        sudo chmod +x winetricks
        sudo mv winetricks /usr/local/bin # install
    cd ..
}

function run_installrms()  # Download/extract/install RMS Express
{
    mkdir downloads 2>/dev/null; cd downloads
        # Download RMS Express (no matter its version number) [https://downloads.winlink.org/User%20Programs/]
            echo -e "\n${GREENTXT}Downloading and installing RMS Express . . .${NORMTXT}\n"
            wget -q -r -l1 -np -nd -A "Winlink_Express_install_*.zip" https://downloads.winlink.org/User%20Programs || { echo "RMS Express download failed!" && run_giveup; }
        
        # We could also use curl if we don't want to use wget to find the link . . .
            #RMSLINKPREFIX="https://downloads.winlink.org"
            #RMSLINKSUFFIX=$(curl -s https://downloads.winlink.org/User%20Programs/ | grep -oP '(?=/User%20Programs/Winlink_Express_install_).*?(\.zip).*(?=">Winlink_Express_install_)')
            #RMSLINK=$RMSLINKPREFIX$RMSLINKSUFFIX
            #wget -q $RMSLINK || { echo "RMS Express download failed!" && run_giveup; }

        # Extract/install RMS Express
            7z x Winlink_Express_install_*.zip -o"WinlinkExpressInstaller"
            wine WinlinkExpressInstaller/Winlink_Express_install.exe /SILENT
            
        # Make a RMS Express desktop shortcut
            echo '[Desktop Entry]'                                                                             >> ~/Desktop/Winlink\ Express.desktop
            echo 'Name=Winlink Express'                                                                        >> ~/Desktop/Winlink\ Express.desktop
            echo 'Exec=env BOX86_DYNAREC_BIGBLOCK=0 wine '$HOME'/.wine/drive_c/RMS\ Express/RMS\ Express.exe'  >> ~/Desktop/Winlink\ Express.desktop
            echo 'Type=Application'                                                                            >> ~/Desktop/Winlink\ Express.desktop
            echo 'StartupNotify=true'                                                                          >> ~/Desktop/Winlink\ Express.desktop
            echo 'Icon=219D_RMS Express.0'                                                                     >> ~/Desktop/Winlink\ Express.desktop
            echo 'StartupWMClass=rms express.exe'                                                              >> ~/Desktop/Winlink\ Express.desktop
            #cp ~/.local/share/applications/wine/Programs/RMS\ Express/Winlink\ Express.desktop ~/Desktop/ # sometimes wine makes broken links
            sudo chmod +x ~/Desktop/Winlink\ Express.desktop
    cd ..
}

function run_installvara()  # Download / extract / install VARA HF/FM/Chat, then configure them with AutoHotKey scripts
{
    sudo apt-get install curl megatools p7zip-full -y
    
    mkdir downloads 2>/dev/null; cd downloads
        # Download / extract VARA HF
            # files: VARA HF v4.4.3 Setup > VARA setup (Run as Administrator).exe > /SILENT install has an OK button at end
            echo -e "\n${GREENTXT}Downloading VARA HF . . .${NORMTXT}\n"
            VARAHFLINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA HF v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
            megadl ${VARAHFLINK} || { echo "VARA HF download failed!" && run_giveup; }
            7z x VARA\ HF*.zip -o"VARAHFInstaller"
            cp VARAHFInstaller/VARA\ setup*.exe ~/.wine/drive_c/ # move VARA installer here (so AHK can find it later)
            # VARA HF will be installed and configured with an AHK script later
        
        # Download / extract VARA FM
            # files: VARA FM v4.1.3 Setup.zip > VARA FM setup (Run as Administrator).exe > /SILENT install has an OK button at end
            echo -e "\n${GREENTXT}Downloading VARA FM . . .${NORMTXT}\n"
            VARAFMLINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA FM v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
            megadl ${VARAFMLINK} || { echo "VARA FM download failed!" && run_giveup; }
            7z x VARA\ FM*.zip -o"VARAFMInstaller"
            cp VARAFMInstaller/VARA\ FM\ setup*.exe ~/.wine/drive_c/ # move VARA installer here (so AHK can find it later)
            # VARA FM will be installed and configured with an AHK script later
            
        # Download / extract / install VARA Chat
            # files: VARA Chat v1.2.5 Setup.zip > VARA Chat setup (Run as Administrator).exe > /SILENT install is silent
            echo -e "\n${GREENTXT}Downloading VARA Chat . . .${NORMTXT}\n"
            VARACHATLINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA Chat v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
            megadl ${VARACHATLINK} || { echo "VARA Chat download failed!" && run_giveup; }
            7z x VARA\ Chat*.zip -o"VARAChatInstaller"
            
            echo -e "\n${GREENTXT}Installing VARA Chat . . .${NORMTXT}\n"
            wine VARAChatInstaller/VARA\ Chat\ setup*.exe /SILENT # install VARA Chat
            
        # TODO: Add VARA SAT
            
            # Make a VARA Chat desktop shortcut
            echo '[Desktop Entry]'                                                                                            >> ~/Desktop/VARA\ Chat.desktop
            echo 'Name=VARA Chat'                                                                                             >> ~/Desktop/VARA\ Chat.desktop
            echo 'Exec=wine '$HOME'/.wine/drive_c/VARA/VARA\ Chat.exe'                                                        >> ~/Desktop/VARA\ Chat.desktop
            echo 'Type=Application'                                                                                           >> ~/Desktop/VARA\ Chat.desktop
            echo 'StartupNotify=true'                                                                                         >> ~/Desktop/VARA\ Chat.desktop
            echo 'Icon=DF53_VARA Chat.0'                                                                                      >> ~/Desktop/VARA\ Chat.desktop
            echo 'StartupWMClass=vara chat.exe'                                                                               >> ~/Desktop/VARA\ Chat.desktop
            #cp ~/.local/share/applications/wine/Programs/VARA\ Chat/VARA.desktop ~/Desktop/VARA\ Chat.desktop # wine makes broken shortcuts sometimes
            sudo chmod +x ~/Desktop/VARA\ Chat.desktop
    cd ..
        
    mkdir ahk; cd ahk
        # Download AutoHotKey
            wget -q https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.0.48.05/AutoHotkey104805_Install.exe || { echo "AutoHotKey download failed!" && run_giveup; }
            7z x AutoHotkey104805_Install.exe AutoHotkey.exe
            sudo chmod +x AutoHotkey.exe
        
        # Install VARA HF silently
            # Create varahf_install.ahk
            # The VARA installer prompts the user to hit 'OK' even during silent install (due to a secondary installer).  We will suppress this prompt with AHK.
            echo '; AHK script to make VARA installer run completely silent'                       >> varahf_install.ahk
            echo 'SetTitleMatchMode, 2'                                                            >> varahf_install.ahk
            echo 'SetTitleMatchMode, slow'                                                         >> varahf_install.ahk
            echo '        Run, VARA setup (Run as Administrator).exe /SILENT, C:\'                 >> varahf_install.ahk
            echo '        WinWait, VARA Setup ; Wait for the "VARA installed successfully" window' >> varahf_install.ahk
            echo '        ControlClick, Button1, VARA Setup ; Click the OK button'                 >> varahf_install.ahk
            echo '        WinWaitClose'                                                            >> varahf_install.ahk

            # Run varahf_install.ahk
            echo -e "\n${GREENTXT}Installing VARA HF . . .${NORMTXT}\n"
            BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 wine AutoHotkey.exe varahf_install.ahk # install VARA silently using AHK
            rm ~/.wine/drive_c/VARA\ setup*.exe # clean up
            
            # Make a VARA HF desktop shortcut
            echo '[Desktop Entry]'                                                                 >> ~/Desktop/VARA.desktop
            echo 'Name=VARA'                                                                       >> ~/Desktop/VARA.desktop
            echo 'Exec=wine '$HOME'/.wine/drive_c/VARA/VARA.exe'                                   >> ~/Desktop/VARA.desktop
            echo 'Type=Application'                                                                >> ~/Desktop/VARA.desktop
            echo 'StartupNotify=true'                                                              >> ~/Desktop/VARA.desktop
            echo 'Icon=F302_VARA.0'                                                                >> ~/Desktop/VARA.desktop
            echo 'StartupWMClass=vara.exe'                                                         >> ~/Desktop/VARA.desktop
            #cp ~/.local/share/applications/wine/Programs/VARA/VARA.desktop ~/Desktop/ # wine makes broken shortcuts sometimes
            sudo chmod +x ~/Desktop/VARA.desktop
        
        # Install VARA FM silently
            # Create/run varafm_install.ahk
            # The VARA installer prompts the user to hit 'OK' even during silent install (due to a secondary installer).  We will suppress this prompt with AHK.
            echo '; AHK script to make VARA installer run completely silent'                       >> varafm_install.ahk
            echo 'SetTitleMatchMode, 2'                                                            >> varafm_install.ahk
            echo 'SetTitleMatchMode, slow'                                                         >> varafm_install.ahk
            echo '        Run, VARA FM setup (Run as Administrator).exe /SILENT, C:\'              >> varafm_install.ahk
            echo '        WinWait, VARA Setup ; Wait for the "VARA installed successfully" window' >> varafm_install.ahk
            echo '        ControlClick, Button1, VARA Setup ; Click the OK button'                 >> varafm_install.ahk
            echo '        WinWaitClose'                                                            >> varafm_install.ahk
            
            # Run varafm_install.ahk
            echo -e "\n${GREENTXT}Installing VARA FM . . .${NORMTXT}\n"
            BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 wine AutoHotkey.exe varafm_install.ahk # install VARA silently using AHK
            rm ~/.wine/drive_c/VARA\ FM\ setup*.exe # clean up
            
            # Make a VARA FM desktop shortcut
            echo '[Desktop Entry]'                                                                 >> ~/Desktop/VARA\ FM.desktop
            echo 'Name=VARA FM'                                                                    >> ~/Desktop/VARA\ FM.desktop
            echo 'Exec=wine '$HOME'/.wine/drive_c/VARA\ FM/VARAFM.exe'                             >> ~/Desktop/VARA\ FM.desktop
            echo 'Type=Application'                                                                >> ~/Desktop/VARA\ FM.desktop
            echo 'StartupNotify=true'                                                              >> ~/Desktop/VARA\ FM.desktop
            echo 'Icon=C497_VARAFM.0'                                                              >> ~/Desktop/VARA\ FM.desktop
            echo 'StartupWMClass=varafm.exe'                                                       >> ~/Desktop/VARA\ FM.desktop
            #cp ~/.local/share/applications/wine/Programs/VARA\ FM/VARA\ FM.desktop ~/Desktop/ # wine makes broken shortcuts sometimes
            sudo chmod +x ~/Desktop/VARA\ FM.desktop
        
        # Guide the user to the VARA HF audio setup menu (configure hardware soundcard input/output)
            echo -e "\n${GREENTXT}Configuring VARA HF . . .${NORMTXT}\n"
            sudo apt-get install zenity -y
            clear
            echo -e "\n${GREENTXT}Please set up your soundcard input/output for VARA HF\n(please click 'Ok' on the user prompt textbox to continue)${NORMTXT}\n"
            zenity --info --height 100 --width 350 --text="We will now setup your soundcards for VARA HF. \n\nInstall will continue once you have closed the VARA Settings menu." --title="VARA HF Soundcard Setup"
            echo -e "\n${GREENTXT}Loading VARA HF now . . .${NORMTXT}\n"

            # Create/run varahf_configure.ahk
            # We will disable all graphics except gauges to help RPi4 CPU. Users can enable these if they have better CPU
            # We will then open the soundcard menu for users so that they can set up their sound cards
            # After the settings menu is closed, we will close VARA HF
            echo '; AHK script to assist users in setting up VARA on its first run'                >> varahf_configure.ahk
            echo 'SetTitleMatchMode, 2'                                                            >> varahf_configure.ahk
            echo 'SetTitleMatchMode, slow'                                                         >> varahf_configure.ahk
            echo '        Run, VARA.exe, C:\VARA'                                                  >> varahf_configure.ahk
            echo '        WinActivate, VARA HF'                                                    >> varahf_configure.ahk
            echo '        WinWait, VARA HF ; Wait for VARA HF to open'                             >> varahf_configure.ahk
            echo '        Sleep 2500 ; If we dont wait at least 2000 for VARA then AHK wont work'  >> varahf_configure.ahk
            echo '        Send, !{s} ; Open SoundCard menu for user to set up sound cards'         >> varahf_configure.ahk
            echo '        Sleep 500'                                                               >> varahf_configure.ahk
            echo '        Send, {Down}'                                                            >> varahf_configure.ahk
            echo '        Sleep, 100'                                                              >> varahf_configure.ahk
            echo '        Send, {Enter}'                                                           >> varahf_configure.ahk
            echo '        Sleep 5000'                                                              >> varahf_configure.ahk
            echo '        WinWaitClose, SoundCard ; Wait for user to finish setting up soundcard'  >> varahf_configure.ahk
            echo '        Sleep 100'                                                               >> varahf_configure.ahk
            echo '        WinClose, VARA HF ; Close VARA'                                          >> varahf_configure.ahk
            BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 wine AutoHotkey.exe varahf_configure.ahk # nobanner option to make console prettier
            sleep 5
            sed -i 's+View\=1+View\=3+g' ~/.wine/drive_c/VARA/VARA.ini # turn off VARA HF's waterfall (change 'View=1' to 'View=3' in VARA.ini). INI file shows up after first run of VARA HF.
        
        # Guide the user to the VARA FM audio setup menu (configure hardware soundcard input/output)
            sudo apt-get install zenity -y
            clear
            echo -e "\n${GREENTXT}Please set up your soundcard input/output for VARA FM\n(please click 'Ok' on the user prompt textbox to continue)${NORMTXT}\n"
            zenity --info --height 100 --width 350 --text="We will now setup your soundcards for VARA FM. \n\nInstall will continue once you have closed the VARA Settings menu." --title="VARA FM Soundcard Setup"
            echo -e "\n${GREENTXT}Loading VARA FM now . . .${NORMTXT}\n"

            #Create varafm_configure.ahk
            # We will disable all graphics except gauges to help RPi4 CPU. Users can enable these if they have better CPU
            # We will then open the soundcard menu for users so that they can set up their sound cards
            # After the settings menu is closed, we will close VARA FM
            echo '; AHK script to assist users in setting up VARA on its first run'                >> varafm_configure.ahk
            echo 'SetTitleMatchMode, 2'                                                            >> varafm_configure.ahk
            echo 'SetTitleMatchMode, slow'                                                         >> varafm_configure.ahk
            echo '        Run, VARAFM.exe, C:\VARA FM'                                             >> varafm_configure.ahk
            echo '        WinActivate, VARA FM'                                                    >> varafm_configure.ahk
            echo '        WinWait, VARA FM ; Wait for VARA FM to open'                             >> varafm_configure.ahk
            echo '        Sleep 2000 ; If we dont wait at least 2000 for VARA then AHK wont work'  >> varafm_configure.ahk
            echo '        Send, !{s} ; Open SoundCard menu for user to set up sound cards'         >> varafm_configure.ahk
            echo '        Sleep 500'                                                               >> varafm_configure.ahk
            echo '        Send, {Down}'                                                            >> varafm_configure.ahk
            echo '        Sleep, 100'                                                              >> varafm_configure.ahk
            echo '        Send, {Enter}'                                                           >> varafm_configure.ahk
            echo '        Sleep 5000'                                                              >> varafm_configure.ahk
            echo '        WinWaitClose, SoundCard ; Wait for user to finish setting up soundcard'  >> varafm_configure.ahk
            echo '        Sleep 100'                                                               >> varafm_configure.ahk
            echo '        WinClose, VARA FM ; Close VARA'                                          >> varafm_configure.ahk
            BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 wine AutoHotkey.exe varafm_configure.ahk # Nobanner option to make console prettier
            sleep 5
            sed -i 's+View\=1+View\=3+g' ~/.wine/drive_c/VARA\ FM/VARAFM.ini # turn off VARA FM's graphics (change 'View=1' to 'View=3' in VARAFM.ini). INI file shows up after first run of VARA FM.
    cd ..
    
    # In older versions of wine, this fixed graphics glitches caused by Wine's (winecfg) window manager (VARA appeared as a black screen when auto-run by RMS Express)
        # NOTE: If using dotnet (instead of wine-mono) on Pi, this will slow things down a lot
        # Create override-x11.reg
        echo 'REGEDIT4'                                      >> override-x11.reg
        echo ''                                              >> override-x11.reg
        echo '[HKEY_CURRENT_USER\Software\Wine\X11 Driver]'  >> override-x11.reg
        echo '"Decorated"="Y"'                               >> override-x11.reg
        echo '"Managed"="N"'                                 >> override-x11.reg
        wine cmd /c regedit /s override-x11.reg
    
    # Install dll's needed by users of "RA-boards," like the DRA-50
    #  https://masterscommunications.com/products/radio-adapter/dra/dra-index.html
        sudo apt install p7zip-full -y
        BOX86_NOBANNER=1 winetricks -q hid
        wget http://uz7.ho.ua/modem_beta/ptt-dll.zip
        7z x ptt-dll.zip -o"$HOME/.wine/drive_c/VARA/" # For VARA HF & VARAChat
        7z x ptt-dll.zip -o"$HOME/.wine/drive_c/VARA FM/" # For VARA FM
        
}

function run_installvARIM()  # Download, build, and install an open-source stand-alone interface for VARA, called vARIM
{
    # Build and install vARIM for RPi - Building takes longer than downloading, but building is a cleaner install than the pre-compiled package
    echo -e "\n${GREENTXT}Downloading and installing vARIM . . .${NORMTXT}\n"
    sudo apt-get install gcc cmake zlibc libfltk1.3-dev libfltk-images1.3 -y # build dependencies
    wget -q https://www.whitemesa.net/varim/src/varim-1.4.tar.gz || { echo "vARIM Sourcecode download failed!" && run_giveup; } # "Current vARIM Version 1.4 source code and help file"
    tar -xzvf varim-1.4.tar.gz
    cd varim-1.4
            ./configure
            make -j$(nproc)
            sudo make install
            sudo chmod 644 ~/varim/varim.ini
    cd ..
    rm -rf varim-1.4
    cp /usr/local/share/applications/varim.desktop ~/Desktop/varim.desktop
    sudo chmod +x ~/Desktop/varim.desktop

    ## Download and install vARIM for RPi3B+ or RPi4B
    # THIS IS BROKEN - vARIM pre-made packages are 'portable' and thus can't be installed into /usr/local/bin like the compiled version.
    #wget -q https://www.whitemesa.net/varim/pkg/varim-1.4-bin-linux-gnueabihf-armv7l.tar.gz || { echo "vARIM Portable download failed!" && run_giveup; }
    #sudo apt-get install libfltk-images1.3 -y
    #tar -xzvf varim-1.4-bin-linux-gnueabihf-armv7l.tar.gz
    #cd varim-1.4
    #        # Install components (based on how the install script for built versions of vARIM does it)
    #        sudo mkdir -p '/usr/local/bin'
    #        sudo mkdir -p '/usr/local/share/applications'
    #        sudo mkdir -p '/usr/local/share/doc/varim'
    #        sudo mkdir -p '/usr/local/share/varim'
    #        sudo mkdir -p '/usr/local/share/pixmaps'
    #        sudo install -c varim '/usr/local/bin'
    #        sudo install -c -m 644 varim.desktop '/usr/local/share/applications'
    #        sudo install -c -m 644 doc/varim-help-v1.4.pdf doc/varim-help.txt doc/varim\(1\)-v1.4.pdf doc/varim\(5\)-v1.4.pdf doc/NEWS doc/AUTHORS doc/COPYING doc/README '/usr/local/share/doc/varim'
    #        sudo install -c -m 644 files/test.txt varim.ini in.mbox varim.png varim-64x64.png '/usr/local/share/varim'
    #        sudo install -c -m 644 out.mbox sent.mbox '/usr/local/share/varim'
    #        sudo install -c -m 644 varim.xpm '/usr/local/share/pixmaps'
    #        cp /usr/local/share/applications/varim.desktop ~/Desktop/varim.desktop
    #        sudo chmod +x ~/Desktop/varim.desktop
    #cd ..
}

function run_makewineserverkscript()  # Make a script for the desktop that will rest wine in case it freezes/crashes
{
    sudo apt-get install zenity -y
    # Create 'Reset\ Wine.sh'
        echo '#!/bin/bash'   >> ~/Desktop/Reset\ Wine
        echo ''              >> ~/Desktop/Reset\ Wine
        echo 'wineserver -k' >> ~/Desktop/Reset\ Wine
        echo 'zenity --info --timeout=8 --height 150 --width 500 --text="Wine has been reset so that Winlink Express and VARA will run again.\\n\\nIf you try to run RMS Express again and it crashes or doesn'\''t open, just keep trying to run it.  It should open eventually after enough tries." --title="Wine has been reset"'          >> ~/Desktop/Reset\ Wine
        sudo chmod +x ~/Desktop/Reset\ Wine
}

function run_makevaraupdatescript()
{
	# Create 'Update\ VARA.sh'
	
	# Inject code into a new script that can be run later from the desktop by users who wish to update VARA HF, VARA FM, and VARAChat
	#   Note that this script uses tabs (	) instead of spaces ( ) for formatting since it relies on heredoc (i.e. eom & eot).
	#   Also note that none of this code gets run right now.
	cat > $HOME/Desktop/Update\ VARA <<- 'EOM'
		#!/bin/bash
		
		sudo apt-get install zenity curl megatools p7zip-full -y &
		sudo rm -rf ~/vara_update_files 2>/dev/null # remove any failed vara update attempts
		
		if zenity --question --height 150 --width 500 --text="Would you like to update VARA HF, VARA FM, and VARA Chat?\\n\\n(RMS Express already checks for updates on its own)" --title="Update VARA Suite?"
		then
			zenity --warning --timeout=16 --height 150 --width 500 --text="Updating VARA HF, VARA FM, and VARA Chat now ...\\n\\nThis may take a moment." --title="Updating VARA Suite" &
			mkdir ~/vara_update_files 2>/dev/null; cd ~/vara_update_files # start new vara update
				# Download / extract VARA HF
					# files: VARA HF v4.4.3 Setup > VARA setup (Run as Administrator).exe > /SILENT install has an OK button at end
					echo -e "\n${GREENTXT}Downloading VARA HF . . .${NORMTXT}\n"
					VARAHFLINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA HF v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
					megadl ${VARAHFLINK} || zenity --warning --timeout=8 --height 150 --width 500 --text="VARA HF download failed ..." --title="Download failed"
					7z x VARA\ HF*.zip -o"VARAHFInstaller"
					cp VARAHFInstaller/VARA\ setup*.exe ~/.wine/drive_c/ # move VARA installer here (so AHK can find it later)
					# VARA HF will be installed with an AHK script later

				# Download / extract VARA FM
					# files: VARA FM v4.1.3 Setup.zip > VARA FM setup (Run as Administrator).exe > /SILENT install has an OK button at end
					echo -e "\n${GREENTXT}Downloading VARA FM . . .${NORMTXT}\n"
					VARAFMLINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA FM v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
					megadl ${VARAFMLINK} || zenity --warning --timeout=8 --height 150 --width 500 --text="VARA FM download failed ..." --title="Download failed"
					7z x VARA\ FM*.zip -o"VARAFMInstaller"
					cp VARAFMInstaller/VARA\ FM\ setup*.exe ~/.wine/drive_c/ # move VARA installer here (so AHK can find it later)
					# VARA FM will be installed with an AHK script later

				mkdir ahk; cd ahk
					# Download AutoHotKey
						wget -q https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.0.48.05/AutoHotkey104805_Install.exe  || zenity --warning --timeout=8 --height 150 --width 500 --text="AHK download failed ..." --title="Download failed"
						7z x AutoHotkey104805_Install.exe AutoHotkey.exe
						sudo chmod +x AutoHotkey.exe

					# Install VARA HF silently
						# Create varahf_install.ahk
						# The VARA installer prompts the user to hit 'OK' even during silent install (due to a secondary installer).  We will suppress this prompt with AHK.
						echo '; AHK script to make VARA installer run completely silent'						>> varahf_install.ahk
						echo 'SetTitleMatchMode, 2'																>> varahf_install.ahk
						echo 'SetTitleMatchMode, slow'															>> varahf_install.ahk
						echo '		Run, VARA setup (Run as Administrator).exe /SILENT, C:\'					>> varahf_install.ahk
						echo '		WinWait, VARA Setup ; Wait for the "VARA installed successfully" window'	>> varahf_install.ahk
						echo '		ControlClick, Button1, VARA Setup ; Click the OK button'					>> varahf_install.ahk
						echo '		WinWaitClose'																>> varahf_install.ahk

						# Run varahf_install.ahk
						echo -e "\n${GREENTXT}Installing VARA HF . . .${NORMTXT}\n"
						BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 wine AutoHotkey.exe varahf_install.ahk # install VARA silently using AHK
						rm ~/.wine/drive_c/VARA\ setup*.exe # clean up

						# Make a VARA HF desktop shortcut
						echo '[Desktop Entry]'																	>> ~/Desktop/VARA.desktop
						echo 'Name=VARA'																		>> ~/Desktop/VARA.desktop
						echo 'Exec=wine '$HOME'/.wine/drive_c/VARA/VARA.exe'									>> ~/Desktop/VARA.desktop
						echo 'Type=Application'																	>> ~/Desktop/VARA.desktop
						echo 'StartupNotify=true'																>> ~/Desktop/VARA.desktop
						echo 'Icon=F302_VARA.0'																	>> ~/Desktop/VARA.desktop
						echo 'StartupWMClass=vara.exe'															>> ~/Desktop/VARA.desktop
						#cp ~/.local/share/applications/wine/Programs/VARA/VARA.desktop ~/Desktop/ # wine makes broken shortcuts sometimes
						sudo chmod +x ~/Desktop/VARA.desktop

					# Install VARA FM silently
						# Create/run varafm_install.ahk
						# The VARA installer prompts the user to hit 'OK' even during silent install (due to a secondary installer).  We will suppress this prompt with AHK.
						echo '; AHK script to make VARA installer run completely silent'						>> varafm_install.ahk
						echo 'SetTitleMatchMode, 2'																>> varafm_install.ahk
						echo 'SetTitleMatchMode, slow'															>> varafm_install.ahk
						echo '		Run, VARA FM setup (Run as Administrator).exe /SILENT, C:\'					>> varafm_install.ahk
						echo '		WinWait, VARA Setup ; Wait for the "VARA installed successfully" window'	>> varafm_install.ahk
						echo '		ControlClick, Button1, VARA Setup ; Click the OK button'					>> varafm_install.ahk
						echo '		WinWaitClose'																>> varafm_install.ahk

						# Run varafm_install.ahk
						echo -e "\n${GREENTXT}Installing VARA FM . . .${NORMTXT}\n"
						BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 wine AutoHotkey.exe varafm_install.ahk # install VARA silently using AHK
						rm ~/.wine/drive_c/VARA\ FM\ setup*.exe # clean up
				cd ..

				# Download / extract / install VARA Chat
					# files: VARA Chat v1.2.5 Setup.zip > VARA Chat setup (Run as Administrator).exe > /SILENT install is silent
					echo -e "\n${GREENTXT}Downloading VARA Chat . . .${NORMTXT}\n"
					VARACHATLINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA Chat v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
					megadl ${VARACHATLINK} || zenity --warning --timeout=8 --height 150 --width 500 --text="VARA Chat download failed ..." --title="Download failed"
					7z x VARA\ Chat*.zip -o"VARAChatInstaller"

					echo -e "\n${GREENTXT}Installing VARA Chat . . .${NORMTXT}\n"
					wine VARAChatInstaller/VARA\ Chat\ setup*.exe /SILENT # install VARA Chat
			cd ..
			sudo rm -rf ~/vara_update_files
		else
			: # do nothing
		fi
	EOM
	sudo chmod +x ~/Desktop/Update\ VARA
}

function run_detect_arch()  # Finds what kind of processor we're running (aarch64, armv8l, armv7l, x86_64, x86, etc)
{
    KARCH=$(uname -m) # don't use 'arch' since it is not supported by Termux
    
    if [ "$KARCH" = "aarch64" ] || [ "$KARCH" = "aarch64-linux-gnu" ] || [ "$KARCH" = "arm64" ] || [ "$KARCH" = "aarch64_be" ]; then
        ARCH=ARM64
        #echo -e "\nDetected an ARM processor running in 64-bit mode (detected ARM64)."
    elif [ "$KARCH" = "armv8r" ] || [  "$KARCH" = "armv8l" ] || [  "$KARCH" = "armv7l" ] || [  "$KARCH" = "armhf" ] || [  "$KARCH" = "armel" ] || [  "$KARCH" = "armv8l-linux-gnu" ] || [  "$KARCH" = "armv7l-linux-gnueabi" ] || [  "$KARCH" = "armv7l-linux-gnueabihf" ] || [  "$KARCH" = "armv7a-linux-gnueabi" ] || [  "$KARCH" = "armv7a-linux-gnueabihf" ] || [  "$KARCH" = "armv7-linux-androideabi" ] || [  "$KARCH" = "arm-linux-gnueabi" ] || [  "$KARCH" = "arm-linux-gnueabihf" ] || [  "$KARCH" = "arm-none-eabi" ] || [  "$KARCH" = "arm-none-eabihf" ]; then
        ARCH=ARM32
        #echo -e "\nDetected an ARM processor running in 32-bit mode (detected ARM32)."
    elif [ "$KARCH" = "x86_64" ]; then
        ARCH=x64
        #echo -e "\nDetected an x86_64 processor running in 64-bit mode (detected x64)."
    elif [ "$KARCH" = "x86" ] || [ "$KARCH" = "i386" ] || [ "$KARCH" = "i686" ]; then
        ARCH=x86
        #echo -e "\nDetected an x86 (or x86_64) processor running in 32-bit mode (detected x86)."
    else
        echo "Error: Could not identify processor architecture.">&2
        run_giveup
    fi
    
    # References:
    #   https://unix.stackexchange.com/questions/136407/is-my-linux-arm-32-or-64-bit
    #   https://bgamari.github.io/posts/2019-06-12-arm-terminology.html
    #   https://superuser.com/questions/208301/linux-command-to-return-number-of-bits-32-or-64/208306#208306
    #   https://stackoverflow.com/questions/45125516/possible-values-for-uname-m

    # Testing:
    #   RPi4B 64-bit OS: aarch64 (if I remember correctly)
    #   RPi4B & RPi3B+ 32-bit: armv7l
    #   Termux 64-bit with 64-bit proot: aarch64 (if I remember correctly)
    #   Termux 64-bit with 32-bit proot: armv8l
    #   Exagear RPi3/4 (32bit modified qemu chroot): i686 (if I remember correctly)
}

function run_gather_os_info()
{
    # To my knowledge . . .
    #    Most post-2012 distros should have a standard '/etc/os-release' file for finding OS
    #    Pre-2012 distros (& small distros) may not have a canonical way of finding OS.
    #
    # Each release file has its own 'standard' vars, but five highly-conserved vars in all(?) os-release files are ...
    #    NAME="Alpine Linux"
    #    ID=alpine
    #    VERSION_ID=3.8.1
    #    PRETTY_NAME="Alpine Linux v3.8"
    #    HOME_URL="http://alpinelinux.org"
    #
    # Other known os-release file vars are listed here: https://docs.google.com/spreadsheets/d/1ixz0PfeWJ-n8eshMQN0BVoFAFnUmfI5HIMyBA0uK43o/edit#gid=0
    #
    # In general, we need to know: $ID (distro) & $VERSION_ID (distro version) into order to add Wine repo's for certain distro's/versions.
    # If $VERSION_CODENAME is available then we should probably use this for figuring out which repo to use
    #
    # We will also have to determine package manager later, which we might try to do multiple ways (whitelist based on distro/version vs runtime detection)

    # Try to find the os-release file on Linux systems
    if [ -e /etc/os-release ];       then OS_INFOFILE='/etc/os-release'     && echo "Found an OS info file located at ${OS_INFOFILE}"
    elif [ -e /usr/lib/os-release ]; then OS_INFOFILE='/usr/lib/os-release' && echo "Found an OS info file located at ${OS_INFOFILE}"
    elif [ -e /etc/*elease ];        then OS_INFOFILE='/etc/*elease'        && echo "Found an OS info file located at ${OS_INFOFILE}"
    # Add mac OS  https://apple.stackexchange.com/questions/255546/how-to-find-file-release-in-os-x-el-capitan-10-11-6
    # Add chrome OS
    # Add chroot Android? (uname -o  can be used to find "Android")
    else OS_INFOFILE='' && echo "No Linux OS info files could be found!">&2 && run_giveup;
    fi
    
    # Load OS-Release File vars into memory (reads vars like "NAME", "ID", "VERSION_ID", "PRETTY_NAME", and "HOME_URL")
    source "${OS_INFOFILE}"
}

function run_giveup()  # If our script failed at any critical stages, notify the user and quit
{
     echo ""
     echo "Installation failed."
     echo ""
     echo "For help, please reference the 'winelink.log' file"
     echo "You can also open an issue on github.com/WheezyE/Winelink/"
     echo ""
     read -n 1 -s -r -p "Press any key to quit . . ."
     echo ""
     exit
}

# Set optional text colors
GREENTXT='\e[32m' # Green
NORMTXT='\e[0m' # Normal
BRIGHT='\e[7m' # Highlighted
NORMAL='\e[0m' # Non-highlighted

run_main "$@"; exit # Run the "run_main" function after all other functions have been defined in bash.  This allows us to keep our main code at the top of the script.
