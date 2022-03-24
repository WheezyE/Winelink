#!/bin/bash

function run_greeting()
{
    clear
    echo ""
    echo "########### Winlink & VARA Installer Script for the Raspberry Pi 4B ###########"
    echo "# Author: Eric Wiessner (KI7POL)                    Install time: apx 10 min  #"
    echo "# Version: 0.0090a                                                            #"
    echo "# Credits:                                                                    #"
    echo "#   The Box86 team (ptitSeb, pale, chills340, Itai-Nelken, Heasterian, et al) #"
    echo "#   Esme 'madewokherd' Povirk (CodeWeavers) for wine-mono debugging/support   #"
    echo "#   N7ACW, AD7HE, & KK6FVG for getting me started in ham radio                #"
    echo "#   K6ETA & DCJ21's Winlink on Linux guides                                   #"
    echo "#   KM4ACK & OH8STN for inspiration                                           #"
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
#    This installer should take about 10 minutes on a Raspberry Pi 4B.
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
    export WINEDEBUG=-all # silence winedbg for this instance of the terminal
    local ARG="$1" # store the first argument passed to the script file as a variable here (i.e. 'bash install_winelink.sh vara_only')
    
    ### Clean up previous runs (or failed runs) of this script
        sudo rm install_winelink.sh 2>/dev/null # silently remove this script so it cannot be re-run by accident
        sudo rm -rf ${HOME}/winelink 2>/dev/null # silently clean up any failed past runs of this script
        sudo rm ${STARTMENU}/winlinkexpress.desktop ${STARTMENU}/vara.desktop ${STARTMENU}/vara-fm.desktop \
                ${STARTMENU}/vara-sat.desktop ${STARTMENU}/vara-chat.desktop ${STARTMENU}/vara-soundcardsetup.desktop \
                ${STARTMENU}/vara-update.desktop ${STARTMENU}/resetwine.desktop 2>/dev/null # remove old shortcuts
		 
        
    ### Create winelink directory
        mkdir ${HOME}/winelink && cd ${HOME}/winelink # store all downloaded/installed files in their own directory
    
        ### Pre-installation
            exec > >(tee "winelink.log") 2>&1 # start logging
            run_checkpermissions
            run_checkxhost
            run_gather_os_info
            #run_detect_arch # TODO: Customize this section to install wine for different operating systems.
            
            # Greet the user
            run_greeting
            if [ "$ARG" = "bap" ]; then
                sleep 10 # If using Build-a-Pi (if 'bap' was passed to the script) then let greeting run without user intervention.
		echo "Install will begin in 10 seconds"
            else
                read -n 1 -s -r -p "Press any key to continue . . ."
            fi
            clear
            
        ### Install Wine, winetricks, autohotkey, and box86
            run_installwine "pi4" "devel" "7.1" "debian" "${VERSION_CODENAME}" "-1" # windows API-call interperter for non-windows OS's - freeze version to ensure compatability
            run_installwinetricks # software installer script for wine
            run_installahk
            run_downloadbox86 10_Dec_21 # emulator to run wine-i386 on ARM - freeze version to ensure compatability
        
        ### Set up Wine (silently make & configure a new wineprefix)
            run_setupwineprefix $ARG # if 'vara_only' was passed to the winelink script, then pass 'vara_only' to this subroutine function too
	
        ### Install Winlink & VARA into our configured wineprefix
            if [ "$ARG" = "vara_only" ] || [ "$ARG" = "bap" ]; then
                run_installvara
            else
                run_installrms
                run_installvara
            fi
        
        ### Post-installation
            run_makewineserverkscript
            run_makevarasoundcardsetupscript
            if [ "$ARG" = "bap" ]; then
                : # If 'bap' is passed to this script, then don't run run_varasoundcardsetup
            else
                run_varasoundcardsetup
            fi
	    run_makeuninstallscript
            clear
            echo -e "\n${GREENTXT}Setup complete.${NORMTXT}\n"
	    
	    # cleanup
	    rm -rf ${HOME}/winelink/downloads
	    rm ${HOME}/winelink/winelink.log
        cd ..
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
    mkdir downloads 2>/dev/null; cd downloads
        mkdir box86; cd box86
            sudo rm /usr/local/bin/box86 2>/dev/null # in case box86 is already installed and running
            wget -q https://archive.org/download/box86.7z_20200928/box86_"$date".7z || { echo "box86_$date download failed! Please check your internet connection and re-run the script." && run_giveup; }
            7z x box86_"$date".7z -y -bsp0 -bso0
            sudo cp box86_"$date"/build/system/box86.conf /etc/binfmt.d/
            sudo cp box86_"$date"/build/box86 /usr/local/bin/box86
            sudo cp box86_"$date"/x86lib/* /usr/lib/i386-linux-gnu/
            sudo systemctl restart systemd-binfmt # must be run after first installation of box86 (initializes binfmt configs so any encountered i386 binaries are sent to box86)
        cd ..
    cd ..
}

function run_buildbox86()  # Build & install Box86. (This function needs a commit hash passed to it)
{
    sudo apt-get install cmake git -y
    local commit="$1"
    
    echo -e "\n${GREENTXT}Building and installing Box86 . . .${NORMTXT}\n"
    mkdir downloads 2>/dev/null; cd downloads
        mkdir box86; cd box86
            rm -rf box86-builder; mkdir box86-builder && cd box86-builder/
                git clone https://github.com/ptitSeb/box86 && cd box86/
                    git checkout "$commit"
                    mkdir build; cd build
                        cmake .. -DRPI4=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
                        make #-j4 may cause crashes in some builds of box86 due to high cpu load
                        sudo make install # copies box86 files into their directories (/usr/local/bin/box86, /usr/lib/i386-linux-gnu/, /etc/binfmt.d/)
                        sudo systemctl restart systemd-binfmt # must be run after first installation of box86 (initializes binfmt configs so any encountered i386 binaries are sent to box86)
                    cd ..
                cd ..
            cd ..
        cd ..
    cd ..
}
function run_installwinemono()  # Wine-mono replaces MS.NET 4.6 and earlier.
{
    # MS.NET 4.6 takes a very long time to install on RPi4 in Wine and runs slower than wine-mono
    sudo apt-get install p7zip-full -y
    mkdir ~/.cache/wine 2>/dev/null
    echo -e "\n${GREENTXT}Downloading and installing wine-mono . . .${NORMTXT}\n"
    wget -q -P ~/.cache/wine https://github.com/madewokherd/wine-mono/releases/download/wine-mono-7.1.3/wine-mono-7.1.3-x86.msi || { echo "wine-mono .msi install file download failed! Please check your internet connection and try again." && run_giveup; }
    wine msiexec /i ~/.cache/wine/wine-mono-7.1.3-x86.msi
    rm -rf ~/.cache/wine # clean up to save disk space
}

function run_installwine()  # Download and install Wine for i386 Debian Buster (This function needs variables passed to it)
                            #   (Example function variables: run_installwine "pi4" "devel" "7.1" "debian" "${VERSION_CODENAME}" "-1")
{
    # Store first six strings passed to this function as variables
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
            wget -q https://dl.winehq.org/wine-builds/debian/dists/${dist}/main/binary-i386/wine-${branch}-i386_${version}~${dist}${tag}_i386.deb || { echo "wine-${branch}-i386_${version}_i386.deb download failed! Please check your internet connection and re-run the script." && run_giveup; }
            wget -q https://dl.winehq.org/wine-builds/debian/dists/${dist}/main/binary-i386/wine-${branch}_${version}~${dist}${tag}_i386.deb || { echo "wine-${branch}_${version}_i386.deb download failed! Please check your internet connection and re-run the script." && run_giveup; }
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
        wget -q https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks || { echo "winetricks download failed! Please check your internet connection and re-run the script." && run_giveup; } # download
        sudo chmod +x winetricks
        sudo mv winetricks /usr/local/bin # install
    cd ..
}

function run_setupwineprefix()  # Set up a new wineprefix silently.  A wineprefix is kind of like a virtual harddrive for wine
{
    # Store first string passed to this function as a variable
    local varaonly="$1"
    
    # Silently create a new wineprefix
        echo -e "\n${GREENTXT}Creating a new wineprefix.  This may take a moment . . .${NORMTXT}\n" 
        rm -rf ~/.cache/wine # make sure no old wine-mono files are in wine's cache, or else they will be auto-installed on first wineboot
        DISPLAY=0 WINEARCH=win32 wine wineboot # initialize Wine silently (silently makes a fresh wineprefix in `~/.wine`)

    # Install pre-requisite software into the wineprefix for RMS Express and VARA
        if [ "$varaonly" = "vara_only" ]; then
	    echo -e "\n${GREENTXT}Setting up your wineprefix for VARA . . .${NORMTXT}\n"
	    BOX86_NOBANNER=1 winetricks -q vb6run pdh_nt4 win7 sound=alsa # for VARA
	else
	    echo -e "\n${GREENTXT}Setting up your wineprefix for RMS Express & VARA . . .${NORMTXT}\n"
	    run_installwinemono # for RMS Express - wine-mono replaces dotnet46
	    #BOX86_NOBANNER=1 winetricks -q dotnet46 win7 sound=alsa # for RMS Express
	    BOX86_NOBANNER=1 winetricks -q vb6run pdh_nt4 win7 sound=alsa # for VARA
	fi
	# TODO: Check to see if 'winetricks -q corefonts riched20' would make text look nicer
}

function run_installahk()
{
    mkdir downloads 2>/dev/null; cd downloads
        # Download AutoHotKey
	echo -e "\n${GREENTXT}Downloading AutoHotkey . . .${NORMTXT}\n"
        wget -q https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.0.48.05/AutoHotkey104805_Install.exe || { echo "AutoHotkey download failed! Please check your internet connection and re-run the script." && run_giveup; }
        7z x AutoHotkey104805_Install.exe AutoHotkey.exe -y -bsp0 -bso0
	mkdir ${HOME}/winelink 2>/dev/null
	mkdir ${AHK}
	sudo mv AutoHotkey.exe ${AHK}/AutoHotkey.exe
	sudo chmod +x ${AHK}/AutoHotkey.exe
    cd ..
}

function run_installrms()  # Download/extract/install RMS Express
{
    mkdir downloads 2>/dev/null; cd downloads
        # Download RMS Express (no matter its version number) [https://downloads.winlink.org/User%20Programs/]
            echo -e "\n${GREENTXT}Downloading and installing RMS Express . . .${NORMTXT}\n"
            wget -q -r -l1 -np -nd -A "Winlink_Express_install_*.zip" https://downloads.winlink.org/User%20Programs || { echo "RMS Express download failed! Please check your internet connection and re-run the script." && run_giveup; }
        
        # We could also use curl if we don't want to use wget to find the link . . .
            #RMSLINKPREFIX="https://downloads.winlink.org"
            #RMSLINKSUFFIX=$(curl -s https://downloads.winlink.org/User%20Programs/ | grep -oP '(?=/User%20Programs/Winlink_Express_install_).*?(\.zip).*(?=">Winlink_Express_install_)')
            #RMSLINK=$RMSLINKPREFIX$RMSLINKSUFFIX
            #wget -q $RMSLINK || { echo "RMS Express download failed!" && run_giveup; }

        # Extract/install RMS Express
            7z x Winlink_Express_install_*.zip -o"WinlinkExpressInstaller" -y -bsp0 -bso0
            wine WinlinkExpressInstaller/Winlink_Express_install.exe /SILENT
	    
	# Clean up
            rm -rf WinlinkExpressInstaller
	    sleep 3; sudo rm -rf ~/.local/share/applications/wine/Programs/RMS\ Express/ # Remove wine's auto-generated program icon from the start menu
            
        # Make a RMS Express desktop shortcut
            echo '[Desktop Entry]'                                                                             | sudo tee ${STARTMENU}/winlinkexpress.desktop > /dev/null
            echo 'Name=Winlink Express'                                                                        | sudo tee -a ${STARTMENU}/winlinkexpress.desktop > /dev/null
            echo 'GenericName=Winlink Express'                                                                 | sudo tee -a ${STARTMENU}/winlinkexpress.desktop > /dev/null
            echo 'Comment=RMS Express emulated with Box86/Wine'                                                | sudo tee -a ${STARTMENU}/winlinkexpress.desktop > /dev/null
            echo 'Exec=env BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine '$HOME'/.wine/drive_c/RMS\ Express/RMS\ Express.exe'  | sudo tee -a ${STARTMENU}/winlinkexpress.desktop > /dev/null
            #echo 'Exec=env BOX86_DYNAREC_BIGBLOCK=0 BOX86_DYNAREC_STRONGMEM=1 WINEDEBUG=-all wine '$HOME'/.wine/drive_c/RMS\ Express/RMS\ Express.exe'  | sudo tee -a ${STARTMENU}/winlinkexpress.desktop > /dev/null # TODO: Does this improve stability or cost speed?
            echo 'Type=Application'                                                                            | sudo tee -a ${STARTMENU}/winlinkexpress.desktop > /dev/null
            echo 'StartupNotify=true'                                                                          | sudo tee -a ${STARTMENU}/winlinkexpress.desktop > /dev/null
            echo 'Icon=219D_RMS Express.0'                                                                     | sudo tee -a ${STARTMENU}/winlinkexpress.desktop > /dev/null
            echo 'StartupWMClass=rms express.exe'                                                              | sudo tee -a ${STARTMENU}/winlinkexpress.desktop > /dev/null
            echo 'Categories=HamRadio;'                                                                        | sudo tee -a ${STARTMENU}/winlinkexpress.desktop > /dev/null
    cd ..
}

function run_installvara()  # Download / extract / install VARA HF/FM/Chat
{
    sudo apt-get install curl megatools p7zip-full -y
    
    # Make the VARA Update script, then run it in silent mode (to install VARA Suite)
        run_makevaraupdatescript
        bash "${HOME}/winelink/Update VARA" silent
        
    # In older versions of wine, this fixed graphics glitches caused by Wine's (winecfg) window manager (VARA appeared as a black screen when auto-run by RMS Express)
        # NOTE: If using dotnet (instead of wine-mono) on Pi, this will slow things down a lot
        # Create override-x11.reg
        echo 'REGEDIT4'                                        > ${HOME}/winelink/override-x11.reg
        echo ''                                                >> ${HOME}/winelink/override-x11.reg
        echo '[HKEY_CURRENT_USER\Software\Wine\X11 Driver]'    >> ${HOME}/winelink/override-x11.reg
        echo '"Decorated"="Y"'                                 >> ${HOME}/winelink/override-x11.reg
        echo '"Managed"="N"'                                   >> ${HOME}/winelink/override-x11.reg
        wine cmd /c regedit /s override-x11.reg
	rm ${HOME}/winelink/override-x11.reg

    # Install dll's needed by users of "RA-boards," like the DRA-50
    #  https://masterscommunications.com/products/radio-adapter/dra/dra-index.html
       #BOX86_NOBANNER=1 winetricks -q hid # unsure if this is needed...
       ##sudo apt-get install p7zip-full -y
       ##wget http://uz7.ho.ua/modem_beta/ptt-dll.zip
       ##7z x ptt-dll.zip -o"$HOME/.wine/drive_c/VARA/" -y -bsp0 -bso0 # For VARA HF & VARAChat
       ##7z x ptt-dll.zip -o"$HOME/.wine/drive_c/VARA FM/" -y -bsp0 -bso0 # For VARA FM
}

function run_makevaraupdatescript()
{
	# Create 'Update\ VARA.sh'

	# Inject code into a new script that can be run later from the desktop by users who wish to update VARA HF, VARA FM, and VARAChat
	#   Note that this script uses tabs (	) instead of spaces ( ) for formatting since it relies on heredoc (i.e. eom & eot).
	#   Also note that none of this code gets run right now.
	cat > ${HOME}/winelink/Update\ VARA <<- 'EOM'
		#!/bin/bash
		
		export WINEDEBUG=-all # silence winedbg for this instance of the terminal
		sudo apt-get install zenity curl megatools p7zip-full -y
		SILENT="$1"
		
		# Create directories (in case they don't already exist)
			mkdir ${HOME}/winelink 2>/dev/null
			mkdir ${HOME}/winelink/ahk 2>/dev/null
			mkdir ${HOME}/winelink/varaupdatefiles 2>/dev/null
		# Set optional text colors
			GREENTXT='\e[32m' # Green
			NORMTXT='\e[0m' # Normal
		# Set location variables
			AHK="${HOME}/winelink/ahk"
			VARAUPDATE="${HOME}/winelink/varaupdatefiles"
			STARTMENU="/usr/share/applications" # Program shortcuts/icons can go here
		
		sudo rm -rf $VARAUPDATE 2>/dev/null # remove any failed vara update attempts
		mkdir $VARAUPDATE
		
		if [ "$SILENT" != "silent" ]; then
			# Ask user if they would like to update the VARA Suite
			zenity --question --height 150 --width 500 --text="Would you like to update VARA HF, VARA FM, and VARA Chat?\\n\\n(RMS Express already checks for updates on its own)" --title="Update VARA Suite?"
			ZENRESULT=$? # the answer of the yes/no questions is stored in the $? variable ( 0 = yes, 1 = no ).
		else
			: # If 'silent' was passed to the 'Update VARA' script, then continue without asking the user any questions
		fi
		
		# Run VARA Suite update if user responded with 'yes', or if the user runs this script with 'silent' passed to it
		if	[ "$ZENRESULT" = 0 ] || [ "$SILENT" = "silent" ]; # If user answered 'yes' or if 'silent' was passed to the 'Update VARA' script, then ...
		then
			if [ "$SILENT" != "silent" ]; then
				zenity --warning --timeout=12 --height 150 --width 500 --text="Updating VARA HF, VARA FM, and VARA Chat now ...\\n\\nThis may take a moment." --title="Updating VARA Suite" &
			fi
			
			# Download / extract / silently install VARA HF
				# Search the rosmodem website for a VARA HF mega.nz link of any version, then download it
					echo -e "\n${GREENTXT}Downloading VARA HF . . .${NORMTXT}\n"
					VARAHFLINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA HF v)')
					megadl ${VARAHFLINK} --path=${VARAUPDATE} || { echo "VARA HF download failed! Please check your internet connection and re-run the script." && run_giveup; }
					7z x ${VARAUPDATE}/VARA\ HF*.zip -o"${VARAUPDATE}/VARAHFInstaller" -y -bsp0 -bso0
					mv ${VARAUPDATE}/VARAHFInstaller/VARA\ setup*.exe ~/.wine/drive_c/ # move VARA installer into wineprefix (so AHK can find it)

				# Create varahf_install.ahk autohotkey script
					# The VARA installer prompts the user to hit 'OK' even during silent install (due to a secondary installer).  We will suppress this prompt with AHK.
					echo '; AHK script to make VARA installer run completely silent'                       > ${AHK}/varahf_install.ahk
					echo 'SetTitleMatchMode, 2'                                                            >> ${AHK}/varahf_install.ahk
					echo 'SetTitleMatchMode, slow'                                                         >> ${AHK}/varahf_install.ahk
					echo '        Run, VARA setup (Run as Administrator).exe /SILENT, C:\'                 >> ${AHK}/varahf_install.ahk
					echo '        WinWait, VARA Setup ; Wait for the "VARA installed successfully" window' >> ${AHK}/varahf_install.ahk
					echo '        ControlClick, Button1, VARA Setup ; Click the OK button'                 >> ${AHK}/varahf_install.ahk
					echo '        WinWaitClose'                                                            >> ${AHK}/varahf_install.ahk
					
				# Run varahf_install.ahk
					echo -e "\n${GREENTXT}Installing VARA HF . . .${NORMTXT}\n"
					BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 wine ${AHK}/AutoHotkey.exe ${AHK}/varahf_install.ahk # install VARA silently using AHK
				
				# Clean up the installation
					rm ~/.wine/drive_c/VARA\ setup*.exe
					rm ${AHK}/varahf_install.ahk
					sleep 3; sudo rm -rf ${HOME}/.local/share/applications/wine/Programs/VARA/ # Remove wine's auto-generated VARA HF program icon from the start menu

				# Make a custom VARA HF desktop shortcut
					echo '[Desktop Entry]'                                                                 | sudo tee ${STARTMENU}/vara.desktop > /dev/null
					echo 'Name=VARA'                                                                       | sudo tee -a ${STARTMENU}/vara.desktop > /dev/null
					echo 'GenericName=VARA'                                                                | sudo tee -a ${STARTMENU}/vara.desktop > /dev/null
					echo 'Comment=VARA HF TNC emulated with Box86/Wine'                                    | sudo tee -a ${STARTMENU}/vara.desktop > /dev/null
					echo 'Exec=env WINEDEBUG=-all wine '$HOME'/.wine/drive_c/VARA/VARA.exe'                | sudo tee -a ${STARTMENU}/vara.desktop > /dev/null
					echo 'Type=Application'                                                                | sudo tee -a ${STARTMENU}/vara.desktop > /dev/null
					echo 'StartupNotify=true'                                                              | sudo tee -a ${STARTMENU}/vara.desktop > /dev/null
					echo 'Icon=F302_VARA.0'                                                                | sudo tee -a ${STARTMENU}/vara.desktop > /dev/null
					echo 'StartupWMClass=vara.exe'                                                         | sudo tee -a ${STARTMENU}/vara.desktop > /dev/null
					echo 'Categories=HamRadio'                                                             | sudo tee -a ${STARTMENU}/vara.desktop > /dev/null

			# Download / extract / silently install VARA FM
				# Search the rosmodem website for a VARA FM mega.nz link of any version, then download it
					echo -e "\n${GREENTXT}Downloading VARA FM . . .${NORMTXT}\n"
					VARAFMLINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA FM v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
					megadl ${VARAFMLINK} --path=${VARAUPDATE} || { echo "VARA FM download failed! Please check your internet connection and re-run the script." && run_giveup; }
					7z x ${VARAUPDATE}/VARA\ FM*.zip -o"${VARAUPDATE}/VARAFMInstaller" -y -bsp0 -bso0
					mv ${VARAUPDATE}/VARAFMInstaller/VARA\ FM\ setup*.exe ~/.wine/drive_c/ # move VARA installer here (so AHK can find it later)

				# Create varafm_install.ahk autohotkey script
					# The VARA installer prompts the user to hit 'OK' even during silent install (due to a secondary installer).  We will suppress this prompt with AHK.
					echo '; AHK script to make VARA installer run completely silent'                       > ${AHK}/varafm_install.ahk
					echo 'SetTitleMatchMode, 2'                                                            >> ${AHK}/varafm_install.ahk
					echo 'SetTitleMatchMode, slow'                                                         >> ${AHK}/varafm_install.ahk
					echo '        Run, VARA FM setup (Run as Administrator).exe /SILENT, C:\'              >> ${AHK}/varafm_install.ahk
					echo '        WinWait, VARA Setup ; Wait for the "VARA installed successfully" window' >> ${AHK}/varafm_install.ahk
					echo '        ControlClick, Button1, VARA Setup ; Click the OK button'                 >> ${AHK}/varafm_install.ahk
					echo '        WinWaitClose'                                                            >> ${AHK}/varafm_install.ahk

				# Run varafm_install.ahk
					echo -e "\n${GREENTXT}Installing VARA FM . . .${NORMTXT}\n"
					BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 wine ${AHK}/AutoHotkey.exe ${AHK}/varafm_install.ahk # install VARA silently using AHK

				# Clean up the installation
					rm ~/.wine/drive_c/VARA\ FM\ setup*.exe
					rm ${AHK}/varafm_install.ahk
					sleep 3; sudo rm -rf ${HOME}/.local/share/applications/wine/Programs/VARA\ FM/ # Remove wine's auto-generated VARA FM program icon from the start menu

				# Make a VARA FM desktop shortcut
					echo '[Desktop Entry]'                                                                 | sudo tee ${STARTMENU}/vara-fm.desktop > /dev/null
					echo 'Name=VARA FM'                                                                    | sudo tee -a ${STARTMENU}/vara-fm.desktop > /dev/null
					echo 'GenericName=VARA FM'                                                             | sudo tee -a ${STARTMENU}/vara-fm.desktop > /dev/null
					echo 'Comment=VARA FM TNC emulated with Box86/Wine'                                    | sudo tee -a ${STARTMENU}/vara-fm.desktop > /dev/null
					echo 'Exec=env WINEDEBUG=-all wine '$HOME'/.wine/drive_c/VARA\ FM/VARAFM.exe'          | sudo tee -a ${STARTMENU}/vara-fm.desktop > /dev/null
					echo 'Type=Application'                                                                | sudo tee -a ${STARTMENU}/vara-fm.desktop > /dev/null
					echo 'StartupNotify=true'                                                              | sudo tee -a ${STARTMENU}/vara-fm.desktop > /dev/null
					echo 'Icon=C497_VARAFM.0'                                                              | sudo tee -a ${STARTMENU}/vara-fm.desktop > /dev/null
					echo 'StartupWMClass=varafm.exe'                                                       | sudo tee -a ${STARTMENU}/vara-fm.desktop > /dev/null
					echo 'Categories=HamRadio'                                                             | sudo tee -a ${STARTMENU}/vara-fm.desktop > /dev/null

			# Download / extract / silently install VARA SAT
				# Search the rosmodem website for a VARA SAT mega.nz link of any version, then download it
					echo -e "\n${GREENTXT}Downloading VARA SAT . . .${NORMTXT}\n"
					VARAFMLINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA SAT v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
					megadl ${VARAFMLINK} --path=${VARAUPDATE} || { echo "VARA SAT download failed! Please check your internet connection and re-run the script." && run_giveup; }
					7z x ${VARAUPDATE}/VARA\ SAT*.zip -o"${VARAUPDATE}/VARASATInstaller" -y -bsp0 -bso0
					mv ${VARAUPDATE}/VARASATInstaller/VARA\ SAT\ setup*.exe ~/.wine/drive_c/ # move VARA installer here (so AHK can find it later)

				# Create varafm_install.ahk autohotkey script
					# The VARA installer prompts the user to hit 'OK' even during silent install (due to a secondary installer).  We will suppress this prompt with AHK.
					echo '; AHK script to make VARA installer run completely silent'                       > ${AHK}/varasat_install.ahk
					echo 'SetTitleMatchMode, 2'                                                            >> ${AHK}/varasat_install.ahk
					echo 'SetTitleMatchMode, slow'                                                         >> ${AHK}/varasat_install.ahk
					echo '        Run, VARA SAT setup (Run as Administrator).exe /SILENT, C:\'             >> ${AHK}/varasat_install.ahk
					echo '        WinWait, VARA Setup ; Wait for the "VARA installed successfully" window' >> ${AHK}/varasat_install.ahk
					echo '        ControlClick, Button1, VARA Setup ; Click the OK button'                 >> ${AHK}/varasat_install.ahk
					echo '        WinWaitClose'                                                            >> ${AHK}/varasat_install.ahk

				# Run varafm_install.ahk
					echo -e "\n${GREENTXT}Installing VARA SAT . . .${NORMTXT}\n"
					BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 wine ${AHK}/AutoHotkey.exe ${AHK}/varasat_install.ahk # install VARA silently using AHK

				# Clean up the installation
					rm ~/.wine/drive_c/VARA\ SAT\ setup*.exe
					rm ${AHK}/varasat_install.ahk
					sleep 3; sudo rm -rf ${HOME}/.local/share/applications/wine/Programs/VARA # Remove wine's auto-generated VARA SAT program icon from the start menu

				# Make a VARA SAT desktop shortcut
					echo '[Desktop Entry]'                                                                 | sudo tee ${STARTMENU}/vara-sat.desktop > /dev/null
					echo 'Name=VARA SAT'                                                                   | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null
					echo 'GenericName=VARA SAT'                                                            | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null
					echo 'Comment=VARA SAT TNC emulated with Box86/Wine'                                   | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null
					echo 'Exec=env WINEDEBUG=-all wine '$HOME'/.wine/drive_c/VARA/VARASAT.exe'             | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null
					echo 'Type=Application'                                                                | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null
					echo 'StartupNotify=true'                                                              | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null
					echo 'Icon=29B6_VARASAT.0'                                                             | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null
					echo 'StartupWMClass=varasat.exe'                                                      | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null
					echo 'Categories=HamRadio'                                                             | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null

			# Download / extract / silently install VARA Chat
				# Search the rosmodem website for a VARA Chat mega.nz link of any version, then download it
					echo -e "\n${GREENTXT}Downloading VARA Chat . . .${NORMTXT}\n"
					VARACHATLINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA Chat v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
					megadl ${VARACHATLINK} --path=${VARAUPDATE} || { echo "VARA Chat download failed! Please check your internet connection and re-run the script." && run_giveup; }
					7z x ${VARAUPDATE}/VARA\ Chat*.zip -o"${VARAUPDATE}/VARAChatInstaller" -y -bsp0 -bso0

				# Run the VARA Chat installer silently
					echo -e "\n${GREENTXT}Installing VARA Chat . . .${NORMTXT}\n"
					wine ${VARAUPDATE}/VARAChatInstaller/VARA\ Chat\ setup*.exe /SILENT # install VARA Chat
				
				# Clean up the installer
					rm ${VARAUPDATE}/VARAChatInstaller/VARA\ Chat\ setup*.exe
					sleep 3; sudo rm -rf ${HOME}/.local/share/applications/wine/Programs/VARA\ Chat/ # Remove VARA FM's auto-generated program icon from the start menu

				# Make a VARA Chat desktop shortcut
					echo '[Desktop Entry]'                                                                 | sudo tee ${STARTMENU}/vara-chat.desktop > /dev/null
					echo 'Name=VARA Chat'                                                                  | sudo tee -a ${STARTMENU}/vara-chat.desktop > /dev/null
					echo 'GenericName=VARA Chat'                                                           | sudo tee -a ${STARTMENU}/vara-chat.desktop > /dev/null
					echo 'Comment=VARA Chat emulated with Box86/Wine'                                      | sudo tee -a ${STARTMENU}/vara-chat.desktop > /dev/null
					echo 'Exec=env WINEDEBUG=-all wine '$HOME'/.wine/drive_c/VARA/VARA\ Chat.exe'          | sudo tee -a ${STARTMENU}/vara-chat.desktop > /dev/null
					echo 'Type=Application'                                                                | sudo tee -a ${STARTMENU}/vara-chat.desktop > /dev/null
					echo 'StartupNotify=true'                                                              | sudo tee -a ${STARTMENU}/vara-chat.desktop > /dev/null
					echo 'Icon=DF53_VARA Chat.0'                                                           | sudo tee -a ${STARTMENU}/vara-chat.desktop > /dev/null
					echo 'StartupWMClass=vara chat.exe'                                                    | sudo tee -a ${STARTMENU}/vara-chat.desktop > /dev/null
					echo 'Categories=HamRadio'                                                             | sudo tee -a ${STARTMENU}/vara-chat.desktop > /dev/null

			sudo rm -rf $VARAUPDATE
			if [ "$SILENT" != "silent" ]; then
				echo -e "\n${GREENTXT}Update complete . . .${NORMTXT}\n"
			fi
			sleep 5
		else
			: # If user selected not to update, then do nothing
		fi
	EOM
	sudo chmod +x ${HOME}/winelink/Update\ VARA
        
        # Make a start menu shortcut for the Reset Wine script
            echo '[Desktop Entry]'                                                                 | sudo tee ${STARTMENU}/vara-update.desktop > /dev/null
            echo 'Name=Update VARA'                                                                | sudo tee -a ${STARTMENU}/vara-update.desktop > /dev/null
            echo 'GenericName=Update VARA'                                                         | sudo tee -a ${STARTMENU}/vara-update.desktop > /dev/null
            echo 'Comment=This script updates VARA HF/FM & VARA Chat'                              | sudo tee -a ${STARTMENU}/vara-update.desktop > /dev/null
            echo 'Exec='$HOME'/winelink/Update\ VARA'                                              | sudo tee -a ${STARTMENU}/vara-update.desktop > /dev/null
            echo 'Type=Application'                                                                | sudo tee -a ${STARTMENU}/vara-update.desktop > /dev/null
            echo 'StartupNotify=true'                                                              | sudo tee -a ${STARTMENU}/vara-update.desktop > /dev/null
            echo 'Categories=HamRadio;'                                                            | sudo tee -a ${STARTMENU}/vara-update.desktop > /dev/null
}

function run_varasoundcardsetup()
{
    bash ${HOME}/winelink/VARA\ Soundcard\ Setup
}

function run_makevarasoundcardsetupscript()
{
	cat > ${HOME}/winelink/VARA\ Soundcard\ Setup <<- 'EOM'
		#!/bin/bash
		
		export WINEDEBUG=-all # silence winedbg for this instance of the terminal
		sudo apt-get install zenity -y
		
		# Create directories (in case they don't already exist)
			mkdir ${HOME}/winelink 2>/dev/null
			mkdir ${HOME}/winelink/ahk 2>/dev/null
		
		# Set optional text colors
    			GREENTXT='\e[32m' # Green
    			NORMTXT='\e[0m' # Normal
		
		# Set location variables
			AHK="${HOME}/winelink/ahk"
		
		# Guide the user to the wineconfig audio menu (configure hardware soundcard input/output)
			clear
			echo ""
			echo -e "\n${GREENTXT}In winecfg, go to the Audio tab to set up your system's in/out soundcards.\n(please click 'Ok' on the user prompt textbox to continue)${NORMTXT}"
			zenity --info --height 100 --width 350 --text="We will now setup your soundcards for Wine. \n\nPlease navigate to the Audio tab and choose your systems soundcards \n\nInstall will continue once you have closed the winecfg menu." --title="Wine Soundcard Setup"
			echo -e "${GREENTXT}Loading winecfg now . . .${NORMTXT}\n"
			echo ""
			BOX86_NOBANNER=1 winecfg # nobanner just for prettier terminal
		
		# Guide the user to the VARA HF audio setup menu (configure hardware soundcard input/output)
			clear
			echo -e "\n${GREENTXT}Configuring VARA HF . . .${NORMTXT}\n"
			echo -e "\n${GREENTXT}Please set up your soundcard input/output for VARA HF\n(please click 'Ok' on the user prompt textbox to continue)${NORMTXT}\n"
			zenity --info --height 100 --width 350 --text="We will now setup your soundcards for VARA HF. \n\nInstall will continue once you have closed the VARA Settings menu." --title="VARA HF Soundcard Setup"
			echo -e "\n${GREENTXT}Loading VARA HF now . . .${NORMTXT}\n"

		# Create/run varahf_configure.ahk
			# We will disable all graphics except gauges to help RPi4 CPU. Users can enable these if they have better CPU
			# We will then open the soundcard menu for users so that they can set up their sound cards
			# After the settings menu is closed, we will close VARA HF
			echo '; AHK script to assist users in setting up VARA on its first run'                > ${AHK}/varahf_configure.ahk
			echo 'SetTitleMatchMode, 2'                                                            >> ${AHK}/varahf_configure.ahk
			echo 'SetTitleMatchMode, slow'                                                         >> ${AHK}/varahf_configure.ahk
			echo '        Run, VARA.exe, C:\VARA'                                                  >> ${AHK}/varahf_configure.ahk
			echo '        WinActivate, VARA HF'                                                    >> ${AHK}/varahf_configure.ahk
			echo '        WinWait, VARA HF ; Wait for VARA HF to open'                             >> ${AHK}/varahf_configure.ahk
			echo '        Sleep 2500 ; If we dont wait at least 2000 for VARA then AHK wont work'  >> ${AHK}/varahf_configure.ahk
			echo '        Send, !{s} ; Open SoundCard menu for user to set up sound cards'         >> ${AHK}/varahf_configure.ahk
			echo '        Sleep 500'                                                               >> ${AHK}/varahf_configure.ahk
			echo '        Send, {Down}'                                                            >> ${AHK}/varahf_configure.ahk
			echo '        Sleep, 100'                                                              >> ${AHK}/varahf_configure.ahk
			echo '        Send, {Enter}'                                                           >> ${AHK}/varahf_configure.ahk
			echo '        Sleep 5000'                                                              >> ${AHK}/varahf_configure.ahk
			echo '        WinWaitClose, SoundCard ; Wait for user to finish setting up soundcard'  >> ${AHK}/varahf_configure.ahk
			echo '        Sleep 100'                                                               >> ${AHK}/varahf_configure.ahk
			echo '        WinClose, VARA HF ; Close VARA'                                          >> ${AHK}/varahf_configure.ahk
			BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 wine ${HOME}/winelink/ahk/AutoHotkey.exe ${AHK}/varahf_configure.ahk # nobanner option to make console prettier
			rm ${AHK}/varahf_configure.ahk
			sleep 5
		
		# Turn off VARA HF's waterfall (change 'View=1' to 'View=3' in VARA.ini). INI file shows up after first run of VARA HF.
			sed -i 's+View\=1+View\=3+g' ~/.wine/drive_c/VARA/VARA.ini
		
		# Guide the user to the VARA FM audio setup menu (configure hardware soundcard input/output)
			clear
			echo -e "\n${GREENTXT}Please set up your soundcard input/output for VARA FM\n(please click 'Ok' on the user prompt textbox to continue)${NORMTXT}\n"
			zenity --info --height 100 --width 350 --text="We will now setup your soundcards for VARA FM. \n\nInstall will continue once you have closed the VARA Settings menu." --title="VARA FM Soundcard Setup"
			echo -e "\n${GREENTXT}Loading VARA FM now . . .${NORMTXT}\n"
		
		#Create/run varafm_configure.ahk
			# We will disable all graphics except gauges to help RPi4 CPU. Users can enable these if they have better CPU
			# We will then open the soundcard menu for users so that they can set up their sound cards
			# After the settings menu is closed, we will close VARA FM
			echo '; AHK script to assist users in setting up VARA on its first run'                > ${AHK}/varafm_configure.ahk
			echo 'SetTitleMatchMode, 2'                                                            >> ${AHK}/varafm_configure.ahk
			echo 'SetTitleMatchMode, slow'                                                         >> ${AHK}/varafm_configure.ahk
			echo '        Run, VARAFM.exe, C:\VARA FM'                                             >> ${AHK}/varafm_configure.ahk
			echo '        WinActivate, VARA FM'                                                    >> ${AHK}/varafm_configure.ahk
			echo '        WinWait, VARA FM ; Wait for VARA FM to open'                             >> ${AHK}/varafm_configure.ahk
			echo '        Sleep 2000 ; If we dont wait at least 2000 for VARA then AHK wont work'  >> ${AHK}/varafm_configure.ahk
			echo '        Send, !{s} ; Open SoundCard menu for user to set up sound cards'         >> ${AHK}/varafm_configure.ahk
			echo '        Sleep 500'                                                               >> ${AHK}/varafm_configure.ahk
			echo '        Send, {Down}'                                                            >> ${AHK}/varafm_configure.ahk
			echo '        Sleep, 100'                                                              >> ${AHK}/varafm_configure.ahk
			echo '        Send, {Enter}'                                                           >> ${AHK}/varafm_configure.ahk
			echo '        Sleep 5000'                                                              >> ${AHK}/varafm_configure.ahk
			echo '        WinWaitClose, SoundCard ; Wait for user to finish setting up soundcard'  >> ${AHK}/varafm_configure.ahk
			echo '        Sleep 100'                                                               >> ${AHK}/varafm_configure.ahk
			echo '        WinClose, VARA FM ; Close VARA'                                          >> ${AHK}/varafm_configure.ahk
			BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 wine ${HOME}/winelink/ahk/AutoHotkey.exe ${AHK}/varafm_configure.ahk # Nobanner option to make console prettier
			rm ${AHK}/varafm_configure.ahk
			sleep 5
		
		# Turn off VARA FM's graphics (change 'View=1' to 'View=3' in VARAFM.ini). INI file shows up after first run of VARA FM
			sed -i 's+View\=1+View\=3+g' ~/.wine/drive_c/VARA\ FM/VARAFM.ini
			
		# Guide the user to the VARA SAT audio setup menu (configure hardware soundcard input/output)
			clear
			echo -e "\n${GREENTXT}Configuring VARA SAT . . .${NORMTXT}\n"
			echo -e "\n${GREENTXT}Please set up your soundcard input/output for VARA SAT\n(please click 'Ok' on the user prompt textbox to continue)${NORMTXT}\n"
			zenity --info --height 100 --width 350 --text="We will now setup your soundcards for VARA SAT. \n\nInstall will continue once you have closed the VARA Settings menu." --title="VARA SAT Soundcard Setup"
			echo -e "\n${GREENTXT}Loading VARA SAT now . . .${NORMTXT}\n"

		# Create/run varasat_configure.ahk
			# We will disable all graphics except gauges to help RPi4 CPU. Users can enable these if they have better CPU
			# We will then open the soundcard menu for users so that they can set up their sound cards
			# After the settings menu is closed, we will close VARA SAT
			echo '; AHK script to assist users in setting up VARA on its first run'                > ${AHK}/varasat_configure.ahk
			echo 'SetTitleMatchMode, 2'                                                            >> ${AHK}/varasat_configure.ahk
			echo 'SetTitleMatchMode, slow'                                                         >> ${AHK}/varasat_configure.ahk
			echo '        Run, VARASAT.exe, C:\VARA'                                               >> ${AHK}/varasat_configure.ahk
			echo '        WinActivate, VARA SAT'                                                   >> ${AHK}/varasat_configure.ahk
			echo '        WinWait, VARA SAT ; Wait for VARA HF to open'                            >> ${AHK}/varasat_configure.ahk
			echo '        Sleep 2500 ; If we dont wait at least 2000 for VARA then AHK wont work'  >> ${AHK}/varasat_configure.ahk
			echo '        Send, !{s} ; Open view menu for user to turn off waterfall'              >> ${AHK}/varasat_configure.ahk
			echo '        Sleep 100'                                                               >> ${AHK}/varasat_configure.ahk
			echo '        Send, {Right}'                                                           >> ${AHK}/varasat_configure.ahk
			echo '        Sleep, 100'                                                              >> ${AHK}/varasat_configure.ahk
			echo '        Send, {Right}'                                                           >> ${AHK}/varasat_configure.ahk
			echo '        Sleep, 100'                                                              >> ${AHK}/varasat_configure.ahk
			echo '        Send, {Down}'                                                            >> ${AHK}/varasat_configure.ahk
			echo '        Sleep, 100'                                                              >> ${AHK}/varasat_configure.ahk
			echo '        Send, {Down}'                                                            >> ${AHK}/varasat_configure.ahk
			echo '        Sleep, 100'                                                              >> ${AHK}/varasat_configure.ahk
			echo '        Send, {Down}'                                                            >> ${AHK}/varasat_configure.ahk
			echo '        Sleep, 100'                                                              >> ${AHK}/varasat_configure.ahk
			echo '        Send, {Enter}'                                                           >> ${AHK}/varasat_configure.ahk
			echo '        Send, !{s} ; Open SoundCard menu for user to set up sound cards'         >> ${AHK}/varasat_configure.ahk
			echo '        Sleep 500'                                                               >> ${AHK}/varasat_configure.ahk
			echo '        Send, {Down}'                                                            >> ${AHK}/varasat_configure.ahk
			echo '        Sleep, 100'                                                              >> ${AHK}/varasat_configure.ahk
			echo '        Send, {Enter}'                                                           >> ${AHK}/varasat_configure.ahk
			echo '        Sleep 5000'                                                              >> ${AHK}/varasat_configure.ahk
			echo '        WinWaitClose, SoundCard ; Wait for user to finish setting up soundcard'  >> ${AHK}/varasat_configure.ahk
			echo '        Sleep 100'                                                               >> ${AHK}/varasat_configure.ahk
			echo '        WinClose, VARA SAT ; Close VARA'                                         >> ${AHK}/varasat_configure.ahk
			BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 wine ${HOME}/winelink/ahk/AutoHotkey.exe ${AHK}/varasat_configure.ahk # nobanner option to make console prettier
			rm ${AHK}/varasat_configure.ahk
			sleep 5
		
		clear
	EOM
	sudo chmod +x ${HOME}/winelink/VARA\ Soundcard\ Setup
        
        # Make a start menu shortcut for the Soundcard Setup script
            echo '[Desktop Entry]'                                            | sudo tee ${STARTMENU}/vara-soundcardsetup.desktop > /dev/null
            echo 'Name=VARA Soundcard Setup'                                  | sudo tee -a ${STARTMENU}/vara-soundcardsetup.desktop > /dev/null
            echo 'GenericName=VARA Soundcard Setup'                           | sudo tee -a ${STARTMENU}/vara-soundcardsetup.desktop > /dev/null
            echo 'Comment=This script helps users set up soundcards for VARA' | sudo tee -a ${STARTMENU}/vara-soundcardsetup.desktop > /dev/null
            echo 'Exec='$HOME'/winelink/VARA\ Soundcard\ Setup'               | sudo tee -a ${STARTMENU}/vara-soundcardsetup.desktop > /dev/null
            echo 'Type=Application'                                           | sudo tee -a ${STARTMENU}/vara-soundcardsetup.desktop > /dev/null
            echo 'StartupNotify=true'                                         | sudo tee -a ${STARTMENU}/vara-soundcardsetup.desktop > /dev/null
            echo 'Categories=HamRadio;'                                       | sudo tee -a ${STARTMENU}/vara-soundcardsetup.desktop > /dev/null
}

function run_makewineserverkscript()  # Make a script for the desktop that will rest wine in case it freezes/crashes
{
    sudo apt-get install zenity -y
    # Create 'Reset\ Wine.sh'
        echo '#!/bin/bash'               > ${HOME}/winelink/Reset\ Wine
        echo ''                          >> ${HOME}/winelink/Reset\ Wine
        echo 'wineserver -k'             >> ${HOME}/winelink/Reset\ Wine
        echo 'zenity --info --timeout=8 --height 150 --width 500 --text="Wine has been reset so that Winlink Express and VARA will run again.\\n\\nIf you try to run RMS Express again and it crashes or doesn'\''t open, just keep trying to run it.  It should open eventually after enough tries." --title="Wine has been reset"'          >> ${HOME}/winelink/Reset\ Wine
        sudo chmod +x ${HOME}/winelink/Reset\ Wine
	
    # Make a start menu shortcut for the Reset Wine script
        echo '[Desktop Entry]'                                              | sudo tee ${STARTMENU}/resetwine.desktop > /dev/null
        echo 'Name=Reset Wine'                                              | sudo tee -a ${STARTMENU}/resetwine.desktop > /dev/null
        echo 'GenericName=Reset Wine'                                       | sudo tee -a ${STARTMENU}/resetwine.desktop > /dev/null
        echo 'Comment=A reset button in case VARA or RMS Express freeze'    | sudo tee -a ${STARTMENU}/resetwine.desktop > /dev/null
        echo 'Exec='$HOME'/winelink/Reset\ Wine'                            | sudo tee -a ${STARTMENU}/resetwine.desktop > /dev/null
        echo 'Type=Application'                                             | sudo tee -a ${STARTMENU}/resetwine.desktop > /dev/null
        echo 'StartupNotify=true'                                           | sudo tee -a ${STARTMENU}/resetwine.desktop > /dev/null
        echo 'Categories=HamRadio;'                                         | sudo tee -a ${STARTMENU}/resetwine.desktop > /dev/null
}

function run_makeuninstallscript()
{
	cat > ${HOME}/winelink/Uninstall\ Winelink <<- 'EOM'
		#!/bin/bash
		
		sudo apt-get install zenity -y
		STARTMENU="/usr/share/applications" # Program shortcuts/icons can go here
		
		zenity --question --height 150 --width 500 --text="Are you sure you would like to uninstall Winelink?\\n(Uninstall VARA HF/FM/Chat, &amp; RMS Express?)" --title="Uninstall Winelink?"
		UNWL=$? # the answer of the yes/no questions is stored in the $? variable ( 0 = yes, 1 = no ).
		if	[ "$UNWL" = 0 ]; # If user answered 'yes', then ...
		then
			sudo rm ${STARTMENU}/winlinkexpress.desktop ${STARTMENU}/vara.desktop ${STARTMENU}/vara-fm.desktop \
				${STARTMENU}/vara-sat.desktop ${STARTMENU}/vara-chat.desktop ${STARTMENU}/vara-soundcardsetup.desktop \
				${STARTMENU}/vara-update.desktop ${STARTMENU}/resetwine.desktop 2>/dev/null # remove old shortcuts
			sudo rm -rf ${HOME}/winelink 2>/dev/null

			# Ask user if they would like to remove wine & box86
				zenity --question --height 150 --width 500 --text="Winelink uninstalled\\n\\nWould you also like to remove Wine and Box86?" --title="Remove Wine & Box86?"
				UNWINE=$? # the answer of the yes/no questions is stored in the $? variable ( 0 = yes, 1 = no ).
				if	[ "$UNWINE" = 0 ]; # If user answered 'yes', then ...
				then
					sudo rm -rf ${HOME}/.wine ${HOME}/.wine-old ${HOME}/wine ${HOME}/wine-old 2>/dev/null
					sudo rm /usr/local/bin/wine /usr/local/bin/wineboot /usr/local/bin/winecfg /usr/local/bin/wineserver /usr/local/bin/winetricks 2>/dev/null
					sudo rm /usr/local/bin/wine-old /usr/local/bin/wineboot-old /usr/local/bin/winecfg-old /usr/local/bin/wineserver-old /usr/local/bin/winetricks-old 2>/dev/null

					sudo rm /usr/local/bin/box86 2>/dev/null
					sudo rm /etc/binfmt.d/box86.conf 2>/dev/null
					sudo systemctl restart systemd-binfmt # unregister box86 from binfmt-misc
				fi
			echo "Uninstall complete"
		fi
	EOM
	sudo chmod +x ${HOME}/winelink/Uninstall\ Winelink
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
    echo "Winelink installation failed."
    echo ""
    echo "For help, please reference the 'winelink.log' file"
    echo "You can also open an issue on github.com/WheezyE/Winelink/"
    echo ""
    exit
}

# Set optional text colors
    GREENTXT='\e[32m' # Green
    NORMTXT='\e[0m' # Normal
    BRIGHT='\e[7m' # Highlighted
    NORMAL='\e[0m' # Non-highlighted

# Set location variables (these also must be set separately within HEREDOC scripts)
    AHK="${HOME}/winelink/ahk"
    # - Start menu organization: https://specifications.freedesktop.org/menu-spec/menu-spec-1.0.html
    STARTMENU="/usr/share/applications" # Program shortcuts/icons can go here
    STARTMENU2="/usr/local/share/applications" # Program shortcuts/icons can go here
    FOLDERSMENU="/usr/share/desktop-directories" # Info about submenu's goes here (the submenu is essentially its own icon).
    ADDSUBMENU="/usr/share/extra-xdg-menus" # Create a new xml file and place here to have it merged by xdg
                                            # bap submenu entry: https://github.com/km4ack/pi-build/blob/7d5c407c14e3bceec672b06b1c3e85f64bba137f/menu-update#L164
    COMPLETEMENU="/etc/xdg/menus/applications-merged" # Completed menu stored here after merging?


run_main "$@"; exit # Run the "run_main" function after all other functions have been defined in bash.  This allows us to keep our main code at the top of the script.
