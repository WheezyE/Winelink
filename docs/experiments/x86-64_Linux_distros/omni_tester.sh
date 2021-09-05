#!/bin/bash
#Winelink installer for Linux Mint 20.2 x64 & Debian 10 x64 (first rough draft for universalizing Winelink's functions)
# Notes: PC (non-ARM) Linux doesn't care if BOX86_NOBANNER=1 is run, so we can probably just keep it in here for all cases

function run_greeting_Universal()  # Splash screen
{
    clear
    echo ""
    echo "########### Winlink & VARA Installer Script for Linux Mint 20.2 x64 ###########"
    echo "# Author: Eric Wiessner (KI7POL)                                              #"
    echo "# Version: 0.002a (Work in progress - lots of bugs!)                          #"
    echo "# Credits:                                                                    #"
    echo "#   The Box86 team                                                            #"
    echo "#      (ptitSeb, pale, chills340, Itai-Nelken, Heasterian, phoenixbyrd,       #"
    echo "#       monkaBlyat, lowspecman420, epychan, !FlameKat53, #lukefrenner,        #"
    echo "#       icecream95, SpacingBat3, Botspot, Icenowy, Longhorn, et.al.)          #"
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
        ### Pre-installation
        #export SUDO_ASKPASS="$(zenity --password)" #Consider doing this for systems that ask the user for sudo password - this way script won't appear to freeze
        exec > >(tee "../winelink.log") 2>&1 # Start logging this script's output
        local ARG="$1" # Store the first argument passed to the script file as a variable here (i.e. 'bash install_winelink.sh vara_only')
        run_checkpermissions_OMNI
        rm -rf Winelink-tmp; mkdir Winelink-tmp && cd Winelink-tmp; rm ~/Desktop/Reset\ Wine; rm ../winelink.log # Clean up any failed past runs of this script
        run_greeting_Universal # Hello world
        
        run_osdetect # should probably rename this - its purpose is to set up our OS with Wine, winetricks, any programs we need like megatools
        
             # NOTE: Our OS should now be set up with Wine and everything else it needs. The rest of this function runs programs within wine so commands should be universal.
        
        rm -rf ~/.cache/wine # Before initializing a new wineprefix, delete wine cache (ensures we don't install mono or gecko - saves time)
        
        
        ### Silently make and configure a new wineprefix
        if [ "${ARG}" = "vara_only" ]; then
        #    run_downloadbox86_Pi4 30_Jan_21 # box86 for wine & RMS/VARA (doesn't install dotnet35sp1) ### KLUDGE
            echo -e "\n${GREENTXT}Creating a new wineprefix.  This may take a moment . . .${NORMTXT}\n"
            DISPLAY=0 WINEARCH=win32 wine wineboot # Initialize Wine silently - silently makes a fresh wineprefix in ~/.wine and skips installation of mono & gecko
            
            echo -e "\n${GREENTXT}Setting up your wineprefix for VARA.  This will take about 10 minutes on an RPi 4 . . .${NORMTXT}\n"
            BOX86_NOBANNER=1 winetricks -q vb6run pdh_nt4 win7 sound=alsa # for VARA (win7 optional)
            
            else
            
            echo -e "\n${GREENTXT}Creating a new wineprefix.  This may take a moment . . .${NORMTXT}\n"
            DISPLAY=0 WINEARCH=win32 wine wineboot # Initialize Wine silently - silently makes a fresh wineprefix in ~/.wine and skips installation of mono & gecko
            
            echo -e "\n${GREENTXT}Setting up your wineprefix for RMS Express & VARA . . .\n(this will take about 70 minutes on an RPi 4)${NORMTXT}\n"
            BOX86_NOBANNER=1 winetricks -q dotnet35sp1 win7 sound=alsa # for RMS Express (corefonts & vcrun2015 do not appear to be needed)
            BOX86_NOBANNER=1 winetricks -q vb6run pdh_nt4 win7 sound=alsa # for VARA
        fi
        
        rm -rf ~/.cache/winetricks/ # clean up cached Microsoft installers now that we're done setting up Wine
        
        # We will then guide the user to the Wine audio setup menu to configure soundcard input/output
        sudo apt-get install zenity -y
        clear
        echo ""
        echo -e "\n${GREENTXT}In winecfg, go to the Audio tab to set up your system's in/out soundcards.\n(please click 'Ok' on the user prompt textbox to continue)${NORMTXT}"
        zenity --info --height 100 --width 350 --text="We will now setup your soundcards for Wine. \n\nPlease navigate to the Audio tab and choose your systems soundcards \n\nInstall will continue once you have closed the winecfg menu." --title="Wine Soundcard Setup"
        echo -e "${GREENTXT}Loading winecfg now . . .${NORMTXT}\n"
        echo ""
        BOX86_NOBANNER=1 winecfg # (nobanner option here just to make the console look prettier)
        clear
        
        
        ### Install Winlink & VARA into our configured wineprefix
        if [ "${ARG}" = "vara_only" ]; then
            run_installvara
            run_installvarachat
            else
            #run_downloadbox86_Pi4 30_Jan_21 ### KLUDGE: box86 for wine & RMS/VARA (doesn't install dotnet35sp1) aiming for commit cad16020
            run_installrms
            run_installvara
            run_installvarachat
        fi
        
        
        ### Post-install
        run_makewineserverkscript
        
        if [ "${ARG}" = "vara_only" ]; then
            : # do nothing
            else
            # Guide the user in setting up & using RMS Express
            sudo apt-get install zenity -y
            clear
            echo -e "\n${GREENTXT}Please enter your callsign and Winlink password, click 'Update', then let${NORMTXT}"
            echo -e "${GREENTXT}RMS Express run for a few moments before closing the program.${NORMTXT}"
            echo ""
            echo -e "${BRIGHT}If you click any error pop-up buttons, RMS Express will crash.${NORMAL}"
            echo -e "${BRIGHT}Just ignore any error pop-ups. Minimize them or move them out of the way.${NORMAL}"
            echo ""
            echo -e "${BRIGHT}If RMS Express freezes or won't re-open, click 'Wine Restart' on the desktop${NORMAL}"
            echo -e "${BRIGHT}and try running RMS Express again.${NORMAL}"
            echo ""
            echo -e "${GREENTXT}(please click 'Ok' on the user prompt textbox to continue)${NORMTXT}"
            zenity --info --height 100 --width 400 --text="Please set up RMS Express with your callsign, gridsquare, and email. \n\nIgnore any error messages that pop-up. Don't click on their buttons. \n\nInstall will continue once you have closed RMS Express." --title="RMS Express First Run Setup"
            echo -e "${GREENTXT}Loading RMS Express now . . .${NORMTXT}"
            wine ~/.wine/drive_c/RMS\ Express/RMS\ Express.exe  
        fi
        
        clear
        echo -e "\n${GREENTXT}Setup complete.${NORMTXT}\n"
        wineserver -k
        cd .. && rm -rf Winelink-tmp winelink.log
        exit # not sure if this exit is needed since there's one at the very end of the script too
} # end of main script




############################################# Subroutines below #############################################

function run_osdetect()
{
    # Detect system specs (attempt to read a Linux OS info file).
    # In general, we need to know: package manager (to install packages), $ID & $VERSION_ID (to download specific wine distro repos)
    
    # - other functions in this script depend on these being run first
    run_osdetect_arch # sets the $ARCH variable (to x86, x86_64, ARM32, or ARM64)
    run_osdetect_info # sets many os-release variables (see below)
    
    # Some variables we now have at our disposal are
    echo ""
    echo "${OS_INFOFILE} file variables:"
    echo "Name =" $NAME
    echo "Distro =" $ID
    echo "Version ID =" $VERSION_ID
    echo "Version codename =" $VERSION_CODENAME # is only set for some Linux distro's
    echo "Pretty name =" $PRETTY_NAME
    echo "Home URL =" $HOME_URL
    echo ""
    
    # Now run the proper system setup script depending on processor OS & kernel architecture
    if [[ "${ARCH}" = "ARM64" ]]; then
                if [[ "${FAMILY_IS}" = "termux" ]]; then
                    echo "64-bit Android Termux detected"
                    # Install AnBox86 for aarch64
                    pkg update -y; pkg install wget -y  < "/dev/null"
                    wget https://raw.githubusercontent.com/lowspecman420/AnBox86/main/AnBox86.sh
                    bash AnBox86.sh
                elif [[ "${ID}" = "raspbian" ]]; then
                    echo "64-bit Raspberry Pi (ARM) detected"
                    echo "Winelink does not currenly support 64bit Raspberry Pi OS, but it is planned."
                    # To-do: Need botspot code to install Winelink for RPi4B with multiarch
                    run_giveup
                else
                    run_giveup
                    # To-do: Consider warning the user and then trying a generic install method
                fi

    elif [[ "${ARCH}" = "ARM32" ]]; then
                if [[ "${ID}" = "raspbian" ]]; then
                    echo "32-bit Raspberry Pi (ARM) detected"
                    run_osdetect_raspver
                    run_osdetect_raspmodel
                    pause
                    # Install Winelink for RPi4B (will also attempt on earlier models but will crash for now)
                    run_installwine_Pi4_ARMhf # Download and install i386-Wine 5.21 devel buster
                    bash install_winelink.sh
                else
                    run_giveup
                    # To-do: Consider warning the user and then trying a generic install method
                fi

    elif [[ "${ARCH}" = "x64" ]]; then
        echo "64-bit PC detected"
        run_osdetect_info_announce # sets the $FAMILY_IS var
        echo "Inferred variables:"
        echo "OS Family =" $FAMILY_IS
        echo "Distro =" $DISTRO # This is redundant with $ID, but we could make the ID name look better with this var if we wanted to
        echo "Default package manager =" $PACKAGES
        echo ""
                if [[ "${FAMILY_IS}" = "debian" ]]; then
                    run_installwine_PCLinux_Debian_x64 #To-do: make these suffixes inputs for these functions. Also pass codename.
                    run_installwinetricks_APT
                fi
        
    elif [[ "${ARCH}" = "x86" ]]; then
        echo "32-bit PC detected"
        run_osdetect_info_announce
            echo "Inferred variables:"
            echo "OS Family =" $FAMILY_IS
            echo "Distro =" $DISTRO # This is redundant with $ID, but we could make the ID name look better with this var if we wanted to
            echo "Default package manager =" $PACKAGES
            echo ""
        
    else
        echo "Your operating system and kernel architecture may not be compatable with Winelink.">&2
        run_giveup
        
    fi
}

        # ============================================== sub-routines of run_os_detect ==============================================

        function run_osdetect_arch()
        { # Finds what kind of processor we're running (arm64, arm32, x64, or x86)
            KARCH="$(uname -m)" # Don't use 'arch' since it is not supported by Termux

            if [[ "$KARCH" = aarch64* ]] || [[ "$KARCH" = arm64* ]]; then
                ARCH=ARM64
                echo -e "\nDetected an ARM64 processor running in 64-bit mode (detected ARM64)."
            elif [[ "$KARCH" = arm* ]]; then
                ARCH=ARM32
                echo -e "\nDetected an ARM (or ARM64) processor running in 32-bit mode (detected ARM32)."
            elif [[ "$KARCH" = x86_64* ]] || [[ "$KARCH" = i?86_64* ]] || [[ "$KARCH" = amd64* ]]; then
                ARCH=x64
                echo -e "\nDetected an x64 processor running in 64-bit mode (detected x64)."
            elif [[ "$KARCH" = i?86* ]]; then
                ARCH=x86
                echo -e "\nDetected an x86 (or x64) processor running in 32-bit mode (detected x86)."
            else
                echo "Error: Could not identify processor architecture.">&2
                run_giveup
            fi
            # Credits: Kubernetes - I designed my own function initially, but found that Kubernetes also had a very similar-looking one.
            #          I was able to reference their string matches with mine to make a more robust architecture detector.
            #          Thank you! https://github.com/kubernetes/kubernetes/blob/34fb61beba52d9e1ab3f044a7be8b9f49d99534e/hack/local-up-cluster.sh#L306

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

        function run_osdetect_info()
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

        function run_osdetect_info_announce() # depends on function run_osdetect_info
        {
            # Full disclosure, this entire function might just be a database to help my own head not explode. It might not actually do anything useful.

            # We could just rely on the os-release file vars.  This whitelist database ...
            #    1. Lists distros which have been tested with our script
            #    2. Might supply extra information to the script if info to our script if needed later
            #    3. Announces to the user (and the log file) with what level of certainty the OS has been detected
            # This function might become defunct later if a more robust detection is found, or if this method is found to be superfluous

            if [ "${PREFIX}" = "/data/data/com.termux/files/usr" ];      then echo "Termux detected"                           && FAMILY_IS=termux && DISTRO=termux && PACKAGES=pkg
            # [[ $PREFIX =~ /data/data/[^/]+/files/usr ]] && echo IN_TERMUX # for use with termux forks (where [^/]+ means one or more characters that are not a forward slash /)

            elif [ "${ID}" = "linuxmint" ];                              then echo "Linux Mint (Ubuntu/Debian) detected"       && FAMILY_IS=debian && DISTRO=linuxmint && PACKAGES=apt   # Mint also has ID_LIKE=ubuntu
            elif [ "${ID}" = "elementary" ];                             then echo "Elementary OS (Ubuntu/Debian) detected"    && FAMILY_IS=debian && DISTRO=elementary && PACKAGES=apt  # elementary OS also has ID_LIKE=ubuntu
            elif [ "${ID}" = "ubuntu" ] || [ "${ID_LIKE}" = "ubuntu" ];  then echo "Looks like Ubuntu (Debian)"                && FAMILY_IS=debian && DISTRO=ubuntu && PACKAGES=apt      # Ubuntu also has ID_LIKE=debian

            elif [ "${ID}" = "kali" ];                                   then echo "Kali (Debian) detected"                    && FAMILY_IS=debian && DISTRO=kali && PACKAGES=apt        # Kali also has ID_LIKE=debian
            elif [ "${ID}" = "raspbian" ];                               then echo "Raspberry Pi OS (Debian) detected"         && FAMILY_IS=debian && DISTRO=raspbian && PACKAGES=apt    # RPi OS also has ID_LIKE=debian - NOTE raspbian can also run on PC's!
            elif [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ];  then echo "Looks like Debian"                         && FAMILY_IS=debian && DISTRO=debian && PACKAGES=apt

            elif [ "${ID}" = "rhel" ];                                   then echo "Red Hat (Fedora) detected"                 && FAMILY_IS=fedora && DISTRO=rhel && PACKAGES=yum        # Red Hat also has ID_LIKE=fedora
            elif [ "${ID}" = "centos" ];                                 then echo "CentOS (Fedora) detected"                  && FAMILY_IS=fedora && DISTRO=centos && PACKAGES=yum      # CentOS also has "ID_LIKE=rhel fedora"
            elif [ "${ID}" = "fedora" ] || [ "${ID_LIKE}" = "fedora" ];  then echo "Looks like Fedora"                         && FAMILY_IS=fedora && DISTRO=fedora && PACKAGES=yum

            elif [ "${ID}" = "manjaro" ];                                then echo "Manjaro (Arch Linux) detected"             && FAMILY_IS=arch   && DISTRO=manjaro && PACKAGES=pacman  # Manjaro also has ID_LIKE=arch
            elif [ "${ID}" = "arch" ] || [ "${ID_LIKE}" = "archlinux" ]; then echo "Looks like Arch Linux"                     && FAMILY_IS=arch   && DISTRO=arch && PACKAGES=pacman

            elif [ "${ID}" = "opensuse" ];                               then echo "openSUSE detected"                         && FAMILY_IS=suse   && DISTRO=opensuse && PACKAGES=zypper # openSuSe also has ID_LIKE="suse"
            elif [ "${ID}" = "sles" ];                                   then echo "SUSE Linux Enterprise Server detected"     && FAMILY_IS=suse   && DISTRO=sles && PACKAGES=zypper     # SLES also has ID_LIKE="suse" (though old SLES doesn't)

            elif [ "${ID}" = "slackware" ];                              then echo "Slackware detected"                        && FAMILY_IS=slack  && DISTRO=slackware && PACKAGES=slackpkg
            elif [ "${ID}" = "ol" ];                                     then echo "Oracle detected"                           && FAMILY_IS=oracle && DISTRO=ol && PACKAGES=yum
            elif [ "${ID}" = "gentoo" ];                                 then echo "Gentoo detected"                           && FAMILY_IS=gentoo && DISTRO=gentoo && PACKAGES=emerge   # Portage = emerge
            elif [ "${ID}" = "alpine" ];                                 then echo "Alpine Linux detected"                     && FAMILY_IS=alpine && DISTRO=alpine && PACKAGES=apk

            else FAMILY_IS=unknown && PACKAGES=unknown && echo "Error: Could not identify operating system.">&2 && run_giveup;
            fi
        }

        function run_osdetect_raspver() # depends on function run_osdetect_info
        {
            if [[ "$VERSION_CODENAME" = "stretch" ]]; then
                echo -e "\nYou are running Raspberry Pi OS Stretch."
            elif [[ "$VERSION_CODENAME" = "buster" ]]; then
                echo -e "\nYou are running Raspberry Pi OS Buster."
            else
                echo "Your version of Raspberry Pi OS is too old. Please run 'sudo apt-get update && sudo apt-get upgrade -y'"
                run_giveup
            fi
        }

        function run_osdetect_raspmodel() # depends on function run_osdetect_info
        {
            TMPVAR1=$(tr -d '\0' </sys/firmware/devicetree/base/model) # Store full name of Pi
            RPIHARDWARE=${TMPVAR1%" Rev"*} # Extract Pi's name before " Rev", so we don't store the Pi's revision name.

            if [[ "$RPIHARDWARE" = "Raspberry Pi 3 Model A+" ]] || [[ "$RPIHARDWARE" = "Raspberry Pi 2 Model B" ]] || [[ "$RPIHARDWARE" = "Raspberry Pi 3 Model B" ]] || [[ "$RPIHARDWARE" = "Raspberry Pi 3 Model B+" ]]; then
                run_giveup
            else # [[ "$RPIHARDWARE" = "Raspberry Pi 4 Model B" ]]
                : # echo "cool"
            fi
        }

        # ============================================== run_os_detect sub-sub-routines ==============================================

# ===================================================== Main Subroutines ==============================================

function run_checkpermissions_OMNI()  # Check to make sure that script is not run as root and that user account has sudo permission.
{
    # If user ran script as root, then exit (since wine should not be initialized as root)
    if [ "$(whoami)" = "root" ]; then
        echo -e "\n${GREENTXT}This script must not be run as root or sudo.${NORMTXT}\n"
        run_giveup
    fi
    
    # If user cannot run sudo commands, then exit (since we have lots of sudo commands in this script)
    sudo -l &> /dev/null || SUDOCHECK="no_sudo" # If an error returns from the command 'sudo -l' then set SUDOCHECK to "no_sudo".
    
    # TO-DO: Might have to do this a different way for mac?
    
    if [ "$SUDOCHECK" = "no_sudo" ]; then
        echo -e "\n${GREENTXT}Please give your user account sudoer access before running this script.${NORMTXT}\n"
        ## Future work: Ask user if they would like to set up sudoer access
            #su - # enter password to enter root account
            #echo "pi ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers # give the 'pi' user account sudo access
            #su - pi # change back to the 'pi' user account
            #sudo apt-get update
        run_giveup
    fi
}

function run_downloadbox86_Pi4()  # Download & install Box86. (This function needs a date passed to it)
{
    sudo apt-get install p7zip-full -y
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

function run_buildbox86_Pi4()  # Build & install Box86. (This function needs a commit hash passed to it)
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

function run_installwine_PCLinux_Debian_x64()  # Download and install wine
{
    FAMILY=ubuntu # debian or ubuntu
    DIST=focal #buster, hirsute, groovy, focal, bionic
    
    #sudo apt-get upgrade -y
    wget -O - https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -
    sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/debian/ buster main'
    sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ hirsute main' #Ubuntu 21.04
    sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ groovy main' #Ubuntu 20.10
    sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main' #Ubuntu 20.04, Linux Mint 20.x
    sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ bionic main' #Ubuntu 18.04, Linux Mint 19.x
    sudo apt-get update
    
    # Install wine 5.21
    #   Note: wine-staging 4.5+ (but not wine-devel nor wine-stable) depends on libfaudio0
    sudo apt-get install --install-recommends wine-devel-amd64=5.21~$DIST --allow-downgrades -y # 64bit wine
    sudo dpkg --add-architecture i386 && sudo apt-get update # If using a 64-bit OS, then ensure we are installing wine32 (apx 700MB extra) using multi-arch
    sudo apt-get install --install-recommends wine-devel-i386=5.21~$DIST wine-devel=5.21~$DIST winehq-devel=5.21~$DIST --allow-downgrades -y # 32bit wine?
        #sudo apt-get install wine wine32 -y # Installs the latest version of wine for our distro
        #sudo apt-get install winbind -y # Optional package for putting Wine on a Windows PC local network
}

function run_installwine_Pi4_ARMhf()  # Download and install wine (and box86) for ARM-hf systems
{ # NOTE: Function run_downloadbox86_Pi4() must be loaded into bash before this function is loaded into bash!
    mkdir downloads; cd downloads
        wineserver -k &> /dev/null # stop any old wine installations from running
        
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
        echo -e "\n${GREENTXT}Downloading wine . . .${NORMTXT}"
        wget -q https://dl.winehq.org/wine-builds/debian/dists/buster/main/binary-i386/wine-devel-i386_5.21~buster_i386.deb || { echo "wine-devel-i386_5.21~buster_i386.deb download failed!" && run_giveup; } # NOTE: Replace this link with the version you want
        wget -q https://dl.winehq.org/wine-builds/debian/dists/buster/main/binary-i386/wine-devel_5.21~buster_i386.deb || { echo "wine-devel_5.21~buster_i386.deb download failed!" && run_giveup; } # NOTE: Also replace this link with the version you want
        echo -e "${GREENTXT}Extracting wine . . .${NORMTXT}"
        dpkg-deb -x wine-devel-i386_5.21~buster_i386.deb wine-installer # NOTE: Make sure these dpkg command matches the filename of the deb package you just downloaded
        dpkg-deb -x wine-devel_5.21~buster_i386.deb wine-installer
        echo -e "${GREENTXT}Installing wine . . .${NORMTXT}\n"
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
        #wget -q http://ftp.us.debian.org/debian/pool/main/f/faudio/libfaudio0_20.11-1~bpo10+1_i386.deb || { echo "libfaudio0_20.11-1~bpo10+1_i386.deb download failed!" && run_giveup; }
        #wget -q -r -l1 -np -nd -A "libfaudio0_*~bpo10+1_i386.deb" http://ftp.us.debian.org/debian/pool/main/f/faudio/ || { echo "libfaudio0_\*~bpo10+1_i386.deb download failed!" && run_giveup; } # Download libfaudio i386 no matter its version number
        #dpkg-deb -xv libfaudio0_*~bpo10+1_i386.deb libfaudio
        #sudo cp -TRv libfaudio/usr/ /usr/
    cd ..
    
    # Box86 (ARM-x86 emulator) allows i386-wine to run on ARM processors
    run_downloadbox86_Pi4 1_Jan_21 # (aiming for commit db5efa89) - NOTE: Doesn't run RMS/VARA, but does install dotnet35sp1. We'll have to kludge later by installing another box86 for RMS/VARA.
}

function run_installwinetricks_APT() # Download and install winetricks
{
    sudo apt-get remove winetricks -y
    sudo apt-get install cabextract -y # winetricks needs this
    #sudo apt-get install winetricks -y; sudo winetricks --self-update # repo method for installing latest winetricks
    mkdir downloads; cd downloads
        # Download & install winetricks
        echo -e "\n${GREENTXT}Downloading and installing winetricks . . .${NORMTXT}\n"
        sudo mv /usr/local/bin/winetricks /usr/local/bin/winetricks-old # backup old winetricks
        wget -q https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks || { echo "winetricks download failed!" && run_giveup; } # download
        sudo chmod +x winetricks
        sudo mv winetricks /usr/local/bin # install
    cd ..
}

function run_installrms()  # Download and install RMS Express
{
    mkdir downloads; cd downloads
        # Download/extract/install Winlink Express (formerly RMS Express) [https://downloads.winlink.org/User%20Programs/]
        echo -e "\n${GREENTXT}Downloading and installing RMS Express . . .${NORMTXT}\n"
        wget -q -r -l1 -np -nd -A "Winlink_Express_install_*.zip" https://downloads.winlink.org/User%20Programs || { echo "RMS Express download failed!" && run_giveup; } # Download Winlink no matter its version number
        
        #We could also use curl if we don't want to use wget to find the link . . .
        #RMSLINKPREFIX="https://downloads.winlink.org"
        #RMSLINKSUFFIX=$(curl -s https://downloads.winlink.org/User%20Programs/ | grep -oP '(?=/User%20Programs/Winlink_Express_install_).*?(\.zip).*(?=">Winlink_Express_install_)')
        #RMSLINK=$RMSLINKPREFIX$RMSLINKSUFFIX
        #wget -q $RMSLINK || { echo "RMS Express download failed!" && run_giveup; }

        7z x Winlink_Express_install_*.zip -o"WinlinkExpressInstaller"
        wine WinlinkExpressInstaller/Winlink_Express_install.exe /SILENT
        cp ~/.local/share/applications/wine/Programs/RMS\ Express/Winlink\ Express.desktop ~/Desktop/ # Make desktop shortcut.  FIX ME: Run a script instead with wineserver -k in front of it
    cd ..
}

function run_installvara()  # Download and install VARA HF/FM, then configure them with AutoHotKey scripts
{
    sudo apt-get install curl megatools p7zip-full -y
    
    mkdir downloads; cd downloads
        # Download / extract / install VARA HF
        echo -e "\n${GREENTXT}Downloading and installing VARA HF . . .${NORMTXT}\n"
        # Files: VARA HF v4.4.3 Setup > VARA setup (Run as Administrator).exe > /SILENT install has an OK button at end
        VARAHFLINK1=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA HF v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
        megadl ${VARAHFLINK1} # link
        if ! compgen -G "VARA\ HF*.zip" > /dev/null; then # If VARA HF download doesn't exist, then try downloading it again with old mega link format
            VARAHFLINK2=${VARAHFLINK1/\#/\!} && VARAHFLINK2=${VARAHFLINK2/\/file\///\#\!} # Replace '#' with '!', then Replace '/file/' with '/#!'
            megadl ${VARAHFLINK2} # old link format
        fi
        7z x VARA\ HF*.zip -o"VARAHFInstaller"
        cp VARAHFInstaller/VARA\ setup*.exe ~/.wine/drive_c/ # Move VARA installer here so AHK can find it later
        
        # Download / extract / install VARA FM
        echo -e "\n${GREENTXT}Downloading and installing VARA FM . . .${NORMTXT}\n"
        # Files: VARA FM v4.1.3 Setup.zip > VARA FM setup (Run as Administrator).exe > /SILENT install has an OK button at end
        VARAFMLINK1=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA FM v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
        megadl ${VARAFMLINK1} # link
        if ! compgen -G "VARA\ FM*.zip" > /dev/null; then # If VARA FM download doesn't exist, then try downloading it again with old mega link format
            VARAFMLINK2=${VARAFMLINK1/\#/\!} && VARAFMLINK2=${VARAFMLINK2/\/file\///\#\!} # Replace '#' with '!', then Replace '/file/' with '/#!'
            megadl ${VARAFMLINK2} # try downloading using old mega link format
        fi
        7z x VARA\ FM*.zip -o"VARAFMInstaller"
        cp VARAFMInstaller/VARA\ FM\ setup*.exe ~/.wine/drive_c/ # Move VARA installer here so AHK can find it later ## "VARA FM setup (Run as Administrator).exe" /SILENT
    cd ..
        
    mkdir ahk; cd ahk
        # Download AutoHotKey
        wget -q https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.0.48.05/AutoHotkey104805_Install.exe || echo "AutoHotKey download failed!"
        7z x AutoHotkey104805_Install.exe AutoHotkey.exe
        sudo chmod +x AutoHotkey.exe
        
        # The VARA installer prompts the user to hit 'OK' even during silent install (due to a secondary installer).  We will suppress this prompt with AHK.
        #Create varahf_install.ahk
        echo '; AHK script to make VARA installer run completely silent'                       >> varahf_install.ahk
        echo 'SetTitleMatchMode, 2'                                                            >> varahf_install.ahk
        echo 'SetTitleMatchMode, slow'                                                         >> varahf_install.ahk
        echo '        Run, VARA setup (Run as Administrator).exe /SILENT, C:\'                 >> varahf_install.ahk
        echo '        WinWait, VARA Setup ; Wait for the "VARA installed successfully" window' >> varahf_install.ahk
        echo '        ControlClick, Button1, VARA Setup ; Click the OK button'                 >> varahf_install.ahk
        echo '        WinWaitClose'                                                            >> varahf_install.ahk
        BOX86_NOBANNER=1 wine AutoHotkey.exe varahf_install.ahk # Install VARA silently using AHK
        cp ~/.local/share/applications/wine/Programs/VARA/VARA.desktop ~/Desktop/ # Make desktop shortcut.
        rm ~/.wine/drive_c/VARA\ setup*.exe # clean up
        
        # The VARA installer prompts the user to hit 'OK' even during silent install (due to a secondary installer).  We will suppress this prompt with AHK.
        #Create varafm_install.ahk
        echo '; AHK script to make VARA installer run completely silent'                       >> varafm_install.ahk
        echo 'SetTitleMatchMode, 2'                                                            >> varafm_install.ahk
        echo 'SetTitleMatchMode, slow'                                                         >> varafm_install.ahk
        echo '        Run, VARA FM setup (Run as Administrator).exe /SILENT, C:\'                 >> varafm_install.ahk
        echo '        WinWait, VARA Setup ; Wait for the "VARA installed successfully" window' >> varafm_install.ahk
        echo '        ControlClick, Button1, VARA Setup ; Click the OK button'                 >> varafm_install.ahk
        echo '        WinWaitClose'                                                            >> varafm_install.ahk
        BOX86_NOBANNER=1 wine AutoHotkey.exe varafm_install.ahk # Install VARA silently using AHK
        cp ~/.local/share/applications/wine/Programs/VARA\ FM/VARA\ FM.desktop ~/Desktop/ # Make desktop shortcut.
        rm ~/.wine/drive_c/VARA\ FM\ setup*.exe # clean up
        
        echo -e "\n${GREENTXT}Configuring VARA HF/FM . . .${NORMTXT}\n"
        # We will then guide the user to the VARA audio setup menu to configure soundcard input/output
        sudo apt-get install zenity -y
        clear
        echo -e "\n${GREENTXT}Please set up your soundcard input/output for VARA HF\n(please click 'Ok' on the user prompt textbox to continue)${NORMTXT}\n"
        zenity --info --height 100 --width 350 --text="We will now setup your soundcards for VARA HF. \n\nInstall will continue once you have closed the VARA Settings menu." --title="VARA HF Soundcard Setup"
        echo -e "\n${GREENTXT}Loading VARA HF now . . .${NORMTXT}\n"

        #Create varahf_configure.ahk
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
        BOX86_NOBANNER=1 wine AutoHotkey.exe varahf_configure.ahk # Nobanner option to make console prettier
        sleep 5
        sed -i 's+View\=1+View\=3+g' ~/.wine/drive_c/VARA/VARA.ini # Turn off VARA HF's waterfall (change 'View=1' to 'View=3' in VARA.ini). INI file shows up after first run of VARA HF.
        
        # We will then guide the user to the VARA FM audio setup menu to configure soundcard input/output
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
        BOX86_NOBANNER=1 wine AutoHotkey.exe varafm_configure.ahk # Nobanner option to make console prettier
        sleep 5
        sed -i 's+View\=1+View\=3+g' ~/.wine/drive_c/VARA\ FM/VARAFM.ini # Turn off VARA FM's graphics (change 'View=1' to 'View=3' in VARAFM.ini). INI file shows up after first run of VARA FM.
        
    cd ..
    
    ### Fix some VARA graphics glitches caused by Wine's (winecfg) window manager (otherwise VARA appears as a black screen when auto-run by RMS Express)
    ## NOTE: Only run this for non-Pi setups: It's actually better to keep VARA as a black screen for RPi4 and weaker CPU's to prevent freezes.
    ##Create override-x11.reg
    #echo 'REGEDIT4'                                      >> override-x11.reg
    #echo ''                                              >> override-x11.reg
    #echo '[HKEY_CURRENT_USER\Software\Wine\X11 Driver]'  >> override-x11.reg
    #echo '"Decorated"="Y"'                               >> override-x11.reg
    #echo '"Managed"="N"'                                 >> override-x11.reg
    #wine cmd /c regedit /s override-x11.reg
}

function run_installvarachat()  # Download and install stand-alone interfaces for VARA
{
    ## VARA Chat (Text and File transfer P2P app) - CURRENTLY BROKEN IN WINE/BOX86
    # Download / extract / install VARA Chat
    #     Files: VARA Chat v1.2.5 Setup.zip > VARA Chat setup (Run as Administrator).exe > /SILENT install is silent
    VARACHATLINK1=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA Chat v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
    megadl ${VARACHATLINK1} # link
    if ! compgen -G "VARA\ Chat*.zip" > /dev/null; then # If VARA Chat download doesn't exist, then try downloading it again with old mega link format
        VARACHATLINK2=${VARACHATLINK1/\#/\!} && VARACHATLINK2=${VARACHATLINK2/\/file\///\#\!} # Replace '#' with '!', then Replace '/file/' with '/#!'
        megadl ${VARACHATLINK2} # old link format
    fi
    7z x VARA\ Chat*.zip -o"VARAChatInstaller"
    wine VARAChatInstaller/VARA\ Chat\ setup*.exe /SILENT
    cp ~/.local/share/applications/wine/Programs/VARA\ Chat/VARA.desktop ~/Desktop/VARA\ Chat.desktop # Make desktop shortcut
}

function run_makewineserverkscript()  # Make a script for the desktop that will rest wine in case it freezes/crashes
{
    sudo apt-get install zenity -y
    # RMS Express & VARA crash or freeze often. It would help users to have a 'rest button' on their desktop for these crashes.
    #Create Reset\ Wine.sh
    echo '#!/bin/bash'   >> ~/Desktop/Reset\ Wine
    echo ''              >> ~/Desktop/Reset\ Wine
    echo 'wineserver -k' >> ~/Desktop/Reset\ Wine
    echo 'zenity --info --timeout=8 --height 150 --width 500 --text="Wine has been reset so that Winlink Express and VARA will run again.\\n\\nIf you try to run RMS Express again and it crashes or doesn'\''t open, just keep trying to run it.  It should open eventually after enough tries." --title="Wine has been reset"'          >> ~/Desktop/Reset\ Wine
    sudo chmod +x ~/Desktop/Reset\ Wine
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
