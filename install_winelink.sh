#!/bin/bash

# TODO: Check for exe's after each install. Error if no exe present.
# TODO: Add timeout timer for VARA settings menu in case of freeze. Then do `wineserver -k` if needed
# TODO: Add bap switch to run_giveup
# TODO: Compile newer custom 32-bit RPiOS kernel for RPi3 and host it.

# About:
#    This script will help you install Box86, Wine, winetricks, Windows DLL's, Winlink (RMS Express) & VARA.  You will then
#    be asked to configure RMS Express & VARA to send/receive audio from a USB sound card plugged into your Pi.  This installer 
#    will only work on the Raspberry Pi 4B for now.  If you would like to use an older Raspberry Pi (3B+, 3B, 2B, Zero, for 
#    example), software may run very slow and you may need to compile a custom 2G/2G split memory kernel before installing.
#
#    To run Windows .exe files on RPi4, we need an x86 emulator (box86) and a Windows API Call interpreter (wine).
#    Box86 is opensource and runs about 10x faster than ExaGear or Qemu.  It's much smaller and easier to install too.
#
# Distribution:
#    This script is free to use, open-source, and should not be monetized.  If you use this script in your project (or are 
#    inspired by it) just please be sure to mention ptitSeb, Box86, and myself (KI7POL).
#
# Legal:
#    All software used by this script is free and legal to use (with the exception of VARA, of course, which is shareware).
#    Box86 and Wine are both open-source (which avoids the legal problems of use & distribution that ExaGear had - ExaGear 
#    also ran much slower than Box86 and is no-longer maintained, despite what Huawei says these days).  All proprietary 
#    Windows DLL files required by Wine are downloaded directly from Microsoft and installed according to their redistribution 
#    guidelines.
#
# Code overview:
#    This script has a main routine that runs subroutines.  Some subroutines in this script are not used and are just for testing.
#    This script is designed for Raspberry Pi 4B, but the hope is to get it running on more systems (x86/x64 Linux, RPi3, etc.)
#    If you're reading this, I apologize for the confusing layout of this code.  I hope to make it cleaner one day.
#


function run_main()
{
    export WINEDEBUG=-all # silence winedbg for this instance of the terminal
    local ARG="$1" # store the first argument passed to the script file as a variable here (i.e. 'bash install_winelink.sh vara_only')

    ### Pre-installation
    run_checkpermissions
    run_checkxhost
    
    ### Clean up previous runs (or failed runs) of this script
        sudo rm install_winelink.sh 2>/dev/null # silently remove this script so it cannot be re-run by accident
        sudo rm -rf ${HOME}/winelink 2>/dev/null # silently clean up any failed past runs of this script
        sudo rm ${STARTMENU}/winlinkexpress.desktop ${STARTMENU}/vara.desktop ${STARTMENU}/vara-fm.desktop \
                ${STARTMENU}/vara-sat.desktop ${STARTMENU}/vara-chat.desktop ${STARTMENU}/vara-soundcardsetup.desktop \
                ${STARTMENU}/vara-update.desktop ${STARTMENU}/resetwine.desktop ${STARTMENU}/VarAC.desktop 2>/dev/null # remove old shortcuts
        rm ${HOME}/RMS\ Express\ *.log 2>/dev/null # silently remove old RMS Express logs
        rm ${HOME}/VarAC.ini ${HOME}/VarAC_cat_commands.ini ${HOME}/VarAC_frequencies.conf ${HOME}/VarAC_frequency_schedule.conf ${HOME}/VarAC_alert_tags.conf
        
    ### Create winelink directory
        mkdir ${HOME}/winelink && cd ${HOME}/winelink # store all downloaded/installed files in their own directory
    
        ### Start logging
        exec > >(tee "winelink.log") 2>&1
        
	### Wine omni-installation
	########################################################################################################################################
	# Installation of Wine is CPU/OS-specific. But after Wine is installed, program installation steps within Wine are universal.          #
	# - Feel free to add your Wine install for your hardware/software setup here to make this script work on your computer.                #
	# - Readability & maintenance of this section is preferred over code elegance, so this section is a little long & redundant in places. #
	# - Nested case statements: https://unix.stackexchange.com/questions/15216/bash-nested-case-syntax-and-terminators                     #
	run_detect_arch
	run_detect_os  # os-release file vars by OS: https://docs.google.com/spreadsheets/d/1ixz0PfeWJ-n8eshMQN0BVoFAFnUmfI5HIMyBA0uK43o/edit#gid=0

	case $ARCH in
	"ARM32"|"ARM64") ############### armhf & aarch64 OS Section ###############
		run_detect_rpi
		run_detect_othersbc
		
		case $SBC_SERIES in # Check for Pi's that can run in 64-bit ARM ( https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-64-bit )
		"RPi4")
			case $ID in
			"raspbian"|"debian") # Pi4 with Raspberry Pi OS
				case $ARCH in # determine 32-bit or 64-bit RPiOS
				"ARM32")
					run_greeting "${SBC_SERIES} ${ARCH} " " 8" "2.1" "${ARG}" #Vars: "Hardware", "OS Bits", "Minutes", "GB", "bap" (check if user passed "bap" to script)
					run_checkdiskspace "2100" #min space required in MB
					run_downloadbox86 "14113faa_RPi4" #emulator to run i386-wine on ARM32 (freeze version at ed8e01ea, which runs RMS, VARAHF/FM, and TCP works)
					#run_buildbox86 "14113faabace7f8f8c6a7d0bb5f6e2fea36c43f1" "RPI4" "ARM32" #TODO: Double-check this (arm32 better for building?) # NOTE: RPI3 and RPI3ARM64 don't build on Pi3B+ (`cc: error: unrecognized command-line option ‘-marm’`) but RPI4ARM64 does.
					run_Sideload_i386wine "devel" "7.1" "debian" "${VERSION_CODENAME}" "-1"
					;; #/"ARM32")
				"ARM64")
					run_greeting "${SBC_SERIES} ${ARCH} " "10" "2.8" "${ARG}"
					run_checkdiskspace "2800" #min space required in MB
					run_downloadbox86 "14113faa_RPi4"
					#run_buildbox86 "14113faabace7f8f8c6a7d0bb5f6e2fea36c43f1" "RPI4" "ARM64"
					run_Sideload_i386wine "devel" "7.1" "debian" "${VERSION_CODENAME}" "-1"
					run_Install_i386wineDependencies_RpiOS64bit
					;; #/"ARM64")
				esac #/case $ARCH
				;; #/"raspbian"|"debian")
			*)
				clear
				echo -e "ERROR: For Raspberry Pi's, only RPiOS is supported by Winelink at this time.\nGiving up on install."
				run_giveup
				;; #/*)
			esac #/case $ID
			;; #/"Pi4")
		"RPi3+"|"RPi3")
			case $ID in
			"raspbian"|"debian") # Pi3 with Raspberry Pi OS (64-bit)...
				case $ARCH in
				"ARM32")
					run_greeting "${SBC_SERIES} ${ARCH}" "35" "4.1" "${ARG}"
					#ARG="bap" # Force-skip RMS Express installation (since it doesn't run great on RPi3B+)
					run_checkdiskspace "4100" #min space required in MB
					run_increasepi3swapfile # Helps prevent insufficient RAM crashes when building box86
					run_custompi3kernel "1" # This kernel installer will ignore 64bit Pi3's since they already have 3G/1G VMem Swap (not needed for 64-bit RPiOS)
					run_downloadbox86 "14113faa_RPi4"
					#run_buildbox86 "14113faabace7f8f8c6a7d0bb5f6e2fea36c43f1" "RPI4" "ARM32" #TODO: Double-check this (arm32 better for building?) # NOTE: RPI3 and RPI3ARM64 don't build on Pi3B+ (`cc: error: unrecognized command-line option ‘-marm’`) but RPI4ARM64 does.
					run_Sideload_i386wine "devel" "7.1" "debian" "${VERSION_CODENAME}" "-1"
					;; #"ARM32")
				"ARM64")
					run_greeting "${SBC_SERIES} ${ARCH}" "28" "3.5" "${ARG}"
					#ARG="bap" # Force-skip RMS Express installation (since it doesn't run great on RPi3B+)
					run_checkdiskspace "3500" #min space required in MB
					run_increasepi3swapfile # Helps prevent insufficient RAM crashes when building box86
					run_downloadbox86 "14113faa_RPi4"
					#run_buildbox86 "14113faabace7f8f8c6a7d0bb5f6e2fea36c43f1" "RPI4" "ARM64"
					run_Sideload_i386wine "devel" "7.1" "debian" "${VERSION_CODENAME}" "-1"
					run_Install_i386wineDependencies_RpiOS64bit
					;; #"ARM64")
				esac #/case $ARCH
				;; #/"raspbian"|"debian")
			*)
				echo -e "ERROR: For Raspberry Pi's, only RPiOS is supported by Winelink at this time.\nGiving up on install."
				run_giveup
				;; #/*)
			esac #/case $ID
			;; #/"Pi3+"|"Pi3")
		"RPiZ2") # TODO - Get a PiZ2W and test this
			#run_custompi3kernel "1" 
			#run_installwine "piz2" "devel" "7.1" "${ID_LIKE}" "${VERSION_CODENAME}" "-1"
			clear
			echo -e "ERROR: Raspberry Pi Zero 2W is not supported yet, but might be in the future.\nGiving up on install."
			run_giveup
			;; #/"PiZ2")
		"Termux") #TODO: Enable this when Termux install available
			: # If no SBC_SERIES variable is set, do nothing and continue on to check for other hardware cases.
			;; #/"")
		"OrangePi4")
			case $ID in
			"ubuntu") # Orange Pi 4 LTS with Ubuntu OS. Thank you Ole W. Saastad (LB4PJ) for sharing your OrangePi 4 LTS to test with!
				case $ARCH in # determine 32-bit or 64-bit Ubuntu
				"ARM32")
					run_greeting "${SBC_SERIES} ${ARCH} " " 8" "2.1" "${ARG}" #Vars: "Hardware", "OS Bits", "Minutes", "GB", "bap" (check if user passed "bap" to script)
					run_checkdiskspace "2100" #min space required in MB
					run_downloadbox86 "14113faa_rk3399" #emulator to run i386-wine on ARM32
					#run_buildbox86 "14113faabace7f8f8c6a7d0bb5f6e2fea36c43f1" "RK3399" "ARM32" #TODO: Double-check this (arm32 better for building?) # NOTE: RPI3 and RPI3ARM64 don't build on Pi3B+ (`cc: error: unrecognized command-line option ‘-marm’`) but RPI4ARM64 does.
					#run_Sideload_i386wine "devel" "7.7" "ubuntu" "${VERSION_CODENAME}" "-1"
					run_Sideload_i386wine "devel" "7.7" "debian" "bullseye" "-1" #kludge: Use debian wine on ubuntu for now
					;; #/"ARM32")
				"ARM64")
					run_greeting "${SBC_SERIES} ${ARCH} " "10" "2.8" "${ARG}"
					run_checkdiskspace "2100" #min space required in MB
					run_downloadbox86 "14113faa_rk3399"
					#run_buildbox86 "14113faabace7f8f8c6a7d0bb5f6e2fea36c43f1" "RK3399" "ARM64" #takes longer than downloading
					#run_Sideload_i386wine "devel" "7.7" "ubuntu" "${VERSION_CODENAME}" "-1" # THIS IS BROKEN FOR SOME REASON
					run_Sideload_i386wine "devel" "7.7" "debian" "bullseye" "-1" #kludge: Use debian wine on ubuntu for now
					run_Install_i386wineDependencies_Ubuntu64bit
					#run_Install_i386wineDependencies_RpiOS64bit
					;; #/"ARM64")
				esac #/case $ARCH
				;; #/"raspbian"|"debian")
			*)
				clear
				echo -e "ERROR: For Raspberry Pi's, only RPiOS is supported by Winelink at this time.\nGiving up on install."
				run_giveup
				;; #/*)
			esac #/case $ID
			;; #/"OrangePi4")
		*)
			clear
			if [[ $SBC_SERIES == *"RPi"* ]]; then
				echo "Your Raspberry Pi is too old to run Wine/box86 well, so will not be able to run VARA or RMS Express."
			else
				echo "You seem to be running an SBC which we have not encountered yet."
				echo "If you would like your SBC added to Winelink, please post an issue on the Winelink github page."
				echo "    https://github.com/WheezyE/Winelink/"
			fi
			echo "Giving up on install."
			run_giveup
			;; #/*)
		esac #/case $SBC_SERIES

		# case $FOUNDTERMUX in # TODO - Check for 64-bit Termux
		# "Termux")
		#	run_AnBox?
		#	;; #/"Termux")
		#"")
		#	: # If no Termux variable is set, do nothing and continue on to check for other hardware cases.
		#	;; #/"")
		# esac
		#
		# TODO - If Pi or Termux is not found, what happens then?

		;; #/ARM64|ARM32)

	"x86"|"x64") ############### i386 & i686 OS Section ###############
		case $ID in
		"debian"|"raspbian")
			run_greeting "${ARCH} ${ID}" "30" "1.5" "${ARG}"
			run_checkdiskspace "1500" #min space required in MB
			
			# TODO: Use the OS-specific package manager to install needed packages? Or do a 'try' in-situ?
			#sudo apt-get install wget p7zip-full cabextract curl megatools zenity -y

			#Make sure system time and certs are up to date (in case system is old or a virtual machine).
			#Also, if NTP is not installed, install it.
			ntpq --help &> /dev/null || NTPCHECK="no_ntp" # if an error returns from the command 'ntpq --help' then set NTPCHECK to "no_ntp"
			if [ "$NTPCHECK" = "no_ntp" ]; then # If ntp time management package doesn't exist, install/configure it
				sudo apt-get install ntp ntpdate -y
				sudo sed -i 's$#server ntp.your-provider.example$server 10.1.1.1 prefer iburst$g' /etc/ntp.conf
			fi
			sudo systemctl stop ntp
			sudo ntpd -gq
			sudo systemctl start ntp
			#sudo apt-get update && apt-get upgrade -y
			sudo update-ca-certificates -v

			#Install wine (note: packages are called "wine-stable", not "winehq-stable" like in the Wine wiki).
			sudo dpkg --add-architecture i386 # also install wine32 using multi-arch
			sudo apt-key del "D43F 6401 4536 9C51 D786 DDEA 76F1 A20F F987 672F" #apt-key is deprecated, but this step is here as a hotfix in case distro has an old winehq gpg key installed
			sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key || { echo "unable to download winehq gpg key!" && run_giveup; }
			sudo wget -P /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/${VERSION_CODENAME}/winehq-${VERSION_CODENAME}.sources || { echo "unable to download winehq sources file!" && run_giveup; }
			sudo sed -i 's&/usr/share/keyrings/winehq-archive.key&/etc/apt/keyrings/winehq-archive.key&g' /etc/apt/sources.list.d/winehq-${VERSION_CODENAME}.sources #fix bug found in the winehq-bullseye.sources file https://bugs.winehq.org/show_bug.cgi?id=53662
				#Note: Old method for installing key and repo
				#wget -O - https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -
				#sudo add-apt-repository "deb https://dl.winehq.org/wine-builds/debian/ ${VERSION_CODENAME} main"
			sudo apt-get update
			sudo apt-get install --install-recommends wine-stable winehq-stable -y || { echo "wine instllation failed!" && run_giveup; } #note: winehq-stable is required for debian or else no symlinks will be made in /usr/local/bin/
				#Note: Method for installing old versions of wine
				#sudo apt-get install --install-recommends wine-${branch}-amd64=${version}~${dist} --allow-downgrades -y # Allow downgrades so that we can install old versions of wine if desired
				#sudo apt-get install --install-recommends wine-${branch}-i386=${version}~${dist} wine-${branch}=${version}~${dist} winehq-${branch}=${version}~${dist} --allow-downgrades -y

			#Add the user to the USB dialout group so that they can access radio USB CAT control later.
			sudo usermod -a -G dialout $USER
			#sudo reboot # In Ubuntu, "logout/login doesn't work. we have to reboot after doing usermod."

			#Figure out which wine com port to connect RMS Express to in order to get CAT control.
				#sudo dmesg | grep tty # see if radio USB port is connected to computer (via one of the ttyUSB ports)
				#ls -l ~/.wine/dosdevices/com* # see if wine is connected to radio USB port (via one of its fake com ports)
				#Debian 11 & RPiOS (wine-stable ): com5
				#Linux Mint (wine-devel ): com33

			echo "Installation for this distro is in alpha status."
			echo "Reboot after installation is required for CAT control"
			echo "Please report issues to: https://github.com/WheezyE/Winelink/issues"
			echo ""
		;; #/"debian"|"raspbian")
		"ubuntu"|"linuxmint") #TODO: TEST THESE
			case $ARCH in
			"x86") # i386 OS
				echo "No install path has been scouted for this distro yet."
				echo "Please post a request on the Winelink Github Issues page:"
				echo "https://github.com/WheezyE/Winelink/issues"
				echo ""
				echo "Giving up on installation"
				run_giveup
				;; #/x86)
			"x64")
				run_greeting "${ARCH}${ID}" "30" "1.5" "${ARG}"
				run_checkdiskspace "1500" #min space required in MB

				#Make sure system time and certs are up to date (in case system is old or a virtual machine)
				sudo service ntp stop
				sudo ntpd -gq
				sudo service ntp start
				sudo update-ca-certificates -v

				#Install wine (note: In Ubuntu, packages are called "wine-stable", not "winehq-stable" like in the Wine wiki).
				sudo dpkg --add-architecture i386 #Install procedure last reviewed 09/07/2022 - ejw
				sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key || { echo "unable to download winehq gpg key!" && run_giveup; }
				sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/${UBUNTU_CODENAME}/winehq-${UBUNTU_CODENAME}.sources || { echo "unable to download winehq sources file!" && run_giveup; }
				sudo sed -i 's&/usr/share/keyrings/winehq-archive.key&/etc/apt/keyrings/winehq-archive.key&g' /etc/apt/sources.list.d/winehq-${UBUNTU_CODENAME}.sources #fix bug found in the winehq-bullseye.sources file https://bugs.winehq.org/show_bug.cgi?id=53662
				sudo apt-get update
				#sudo apt-get install --install-recommends wine-stable -y  || { echo "wine instllation failed!" && run_giveup; } #note: no winehq-stable package for ubuntu. Symlinks are still created though#sudo apt-get install --install-recommends wine-stable -y  || { echo "wine instllation failed!" && run_giveup; } #note: no winehq-stable package for ubuntu. Symlinks are still created though
				sudo apt-get install --install-recommends winehq-devel -y  || { echo "wine instllation failed!" && run_giveup; } #note: for some reason wine-stable lags far behind on ubuntu

				#Add the user to the USB dialout group so that they can access radio USB CAT control later.
				sudo usermod -a -G dialout $USER
				#sudo reboot # In Ubuntu, "logout/login doesn't work. we have to reboot after doing usermod."

				#Figure out which wine com port to connect RMS Express to in order to get CAT control.
				#sudo dmesg | grep tty # see if radio USB port is connected to computer (via one of the ttyUSB ports)
				#ls -l ~/.wine/dosdevices/com* # see if wine is connected to radio USB port (via one of its fake com ports)
				#Debian 11 & RPiOS (wine-stable ): com5
				#Linux Mint (wine-devel ): com33

				# TODO: VARA Settings freeze the installer. Consider adding a countdown timer that runs wineserver -k after 10s if no progress? x2
				echo "Installation for this distro is in alpha status."
				echo "Reboot after installation is required for CAT control"
				echo "Please report issues to: https://github.com/WheezyE/Winelink/issues"
				echo ""
				;; #/x64)
			esac #/case $ARCH
			;; #/"ubuntu"|"linuxmint")
		*)
			echo "No install path has been scouted for this distro yet."
			echo "Please post a request on the Winelink Github Issues page:"
			echo "https://github.com/WheezyE/Winelink/issues"
			echo ""
			echo "Giving up on installation"
			run_giveup
			;; #/*)
		esac #/case $ID
		;; #/"x86"|"x64")
	*)
		echo "Something went wrong with system architecture identification. Giving up."
		run_giveup
		;; #/*)
	esac #/case $ARCH
	#                                                                                                                                      #
	# The script should be universal (not CPU/OS-specific) from this point on.                                                             #
	########################################################################################################################################
		
        ### Install winetricks & autohotkey - TODO: Add wget & package manager detection
            run_installwinetricks # software installer script for wine
            run_installahk
        
        ### Set up Wine (silently make & configure a new wineprefix)
            run_setupwineprefix $ARG # if 'vara_only' was passed to the winelink script, then pass 'vara_only' to this subroutine function too
	
        ### Install Winlink, VARA, & VarAC into our configured wineprefix
            if [ "$ARG" = "vara_only" ] || [ "$ARG" = "bap" ]; then #TODO: Am I using brackets and ='s correctly?
                run_installvara
            else
                run_installrms
                run_installvara
                run_installvarAC
            fi
        
        ### Post-installation
            run_makewineserverkscript
            run_makevarasoundcardsetupscript
            if [ "$ARG" = "bap" ]; then
                : # If 'bap' is passed to this script, then don't run run_varasoundcardsetup
            else
                run_varasoundcardsetup
                run_varACsetup
            fi
	    run_makeuninstallscript
	    
            clear
            echo -e "\n${GREENTXT}Setup complete.${NORMTXT}"
            case $ARCH in
                "x86"|"x64")
                    echo -e "\n${GREENTXT}Rebooting is recommended for CAT control (not needed for RPiOS)${NORMTXT}" #TODO: Add a guide on how to find USB CAT ports.
                    ;; #/"x86"|"x64")
		*)
		    : #do nothing
		    ;; #/*)
            esac #/case $ARCH
	    
	    # cleanup
	    rm -rf ${HOME}/winelink/downloads 2>/dev/null # silently remove Winlink downloads directory
	    rm ${HOME}/winelink/winelink.log 2>/dev/null # silently remove old RMS Express logs
        cd ..
    exit
}




############################################# Subroutines #############################################

function run_greeting()
{
    local hardware="$1"
    local tinst="$2"
    local space="$3"
    local arg="$4"
    
    clear
    echo ""
    echo "####################### Winlink & VARA Installer Script #######################"
    echo "# Author: Eric Wiessner (KI7POL)                         System: ${hardware}  #"
    echo "# Version: 0.0098a                                 Install time: apx ${tinst} min   #"
    echo "#                                                Space required: apx ${space} GB   #"
    echo "# Credits:                                                                    #"
    echo "#   The Box86 team (ptitSeb, pale, chills340, Itai-Nelken, Heasterian, et al) #"
    echo "#   Esme 'madewokherd' Povirk (CodeWeavers) for adding functions to wine-mono #"
    echo "#   Botspot for RPi kernel switching bash code. Chris Keller for Pat support. #"
    echo "#   N7ACW, AD7HE, & KK6FVG for getting me started in ham radio.               #"
    echo "#   KM4ACK & OH8STN for inspiration. K6ETA & DCJ21's Winlink on Linux guides. #"
    echo "#                                                                             #"
    echo "# Donations:                                                                  #"
    echo "#    Box86                        paypal.me/0ptitSeb                          #"
    echo "#    madewokherd / CodeWeavers    codeweavers.com/crossover                   #"
    echo "#    Wine / wine-mono             winehq.org/donate                           #"
    echo "#                                                                             #"
    echo "#    \"My humanity is bound up in yours, for we can only be human together\"    #"
    echo "#                                                - Nelson Mandela             #"
    echo "###############################################################################"
    
    if [ "$arg" = "bap" ]; then
    	echo "Install will begin in 10 seconds"
	sleep 10 # If using Build-a-Pi (if 'bap' was passed to the script) then let greeting run without user intervention.
    else
	read -n 1 -s -r -p "Press any key to continue . . ."
    fi
    clear
}

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
        echo -e "${GREENTXT}Please give your user account sudoer access before running this script.${NORMTXT}"
	echo -e "${GREENTXT}You can do this by copy-pasting the following commands ONE LINE AT A TIME:${NORMTXT}"
	echo "    su - #enter root, then copy-paste these next commands into root"
	echo '    echo "'"${USER} ALL=(ALL) NOPASSWD: ALL"'" >> /etc/sudoers'
	echo "    exit #log out of root"
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

function run_checkdiskspace()
{
	# https://stackoverflow.com/questions/41127585/shell-how-to-check-available-space-and-exit-if-not-enough
	# https://unix.stackexchange.com/questions/179274/what-does-1k-blocks-column-mean-in-the-output-of-df
	# Byte conversions https://docs.google.com/spreadsheets/d/13c4mXAcKSfo5qoa6zvWUhWv9rkL0A-fefuh3fiicON0/edit?usp=sharing
	
	local reqSpaceMB=$1 # Note: Input values should be in MB (aka 1000 kB per MB; 1000 bytes per kB), not in MiB (1024 KiB per MiB).
	reqSpace512Blocks=$(($reqSpaceMB*1000000/512))  # Convert MB to 512-byte units for POSIX calculation below (POSIX 1 block = 512 bytes)
							# y 512Blocks = x MB * (1000000 bytes / 1 MB) * (1 512Block / 512 bytes)
	
	availSpace=$(POSIXLY_CORRECT=1 df "$HOME" | awk 'NR==2 { print $4 }') # A "1" value = 512 bytes in this POSIX notation
	if (( availSpace < reqSpace512Blocks )); then
		echo "Winelink requires at least $reqSpaceMB MB of disk space." >&2
		echo "Please free up more space or use a larger SD card, then try again."
		run_giveup
	fi
}

function run_downloadbox86()  # Download & install Box86. (This function needs a date passed to it) - TODO: Replace with self-hosted github binaries
{
    local version="$1"
    
    if [ "$ARCH" == "ARM64" ]; then
	sudo dpkg --add-architecture armhf && sudo apt-get update
	sudo apt-get install libc6:armhf -y # needed to run box86:armhf on aarch64
	#sudo apt-get install libgtk2.0-0:armhf libsdl2-image-2.0-0:armhf libsdl1.2debian:armhf \
	#	libopenal1:armhf libvorbisfile3:armhf libgl1:armhf libjpeg62:armhf libcurl4:armhf \
	#	libasound2-plugins:armhf -y # not sure if needed. from: https://box86.org/2022/03/box86-box64-vs-qemu-vs-fex-vs-rosetta2/
    elif [ "$ARCH" == "ARM32" ]; then
    	:
    fi
    sudo apt-get install p7zip-full -y # TODO: remove redundant apt-get installs - put them at top of script.
    
    echo -e "${GREENTXT}Downloading and installing Box86 . . .${NORMTXT}"
    mkdir downloads 2>/dev/null; cd downloads
        mkdir box86; cd box86
            sudo rm /usr/local/bin/box86 2>/dev/null # in case box86 is already installed and running
            #wget -q https://github.com/WheezyE/Winelink/raw/WheezyE-patch-5/binaries/box86_"$version".7z # || { echo "box86_$version download failed!" && run_giveup; }
            wget -q https://github.com/WheezyE/Winelink/raw/main/binaries/box86_"$version".7z || { echo "box86_$version download failed!" && run_giveup; }
	    7z x box86_"$version".7z -y -bsp0 -bso0
            sudo cp box86_"$version"/build/system/box86.conf /etc/binfmt.d/
            sudo cp box86_"$version"/build/box86 /usr/local/bin/box86
	    sudo chmod +x /usr/local/bin/box86
	    sudo mkdir /usr/lib/i386-linux-gnu/ 2>/dev/null;
            sudo cp box86_"$version"/x86lib/* /usr/lib/i386-linux-gnu/
            sudo systemctl restart systemd-binfmt # must be run after first installation of box86 (initializes binfmt configs so any encountered i386 binaries are sent to box86)
        cd ..
    cd ..
}

function run_buildbox64() # This method is not currently used
{
    # This function can only be run on a 64-bit ARM OS (32-bit will fail)
    local commit86="$1"
    local series="$2" # "RPI4"
    
    # Build and install box64
    sudo apt-get install git cmake python3 build-essential gcc -y # box64 dependencies
    echo -e "${GREENTXT}Building and installing Box64 . . .${NORMTXT}"
    mkdir downloads 2>/dev/null; cd downloads
        mkdir box64; cd box64
            rm -rf box64-builder; mkdir box64-builder && cd box64-builder/
                git clone https://github.com/ptitSeb/box64 && cd box64
                    git checkout "$commit64"
                    mkdir build; cd build
                        cmake .. -DARM_DYNAREC=ON -D${series}ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
			make -j$(($(nproc)-2)) # compile using all processors minus two (to prevent OS freezes)
                        sudo make install
                        sudo systemctl restart systemd-binfmt
                    cd ..
                cd ..
            cd ..
        cd ..
    cd ..
}

function run_buildbox86() # Compile box64 & box86 on-device (takes a long time, builds are fresh and links less breakable)
{
    # This function can only be run on an ARM OS (32-bit or 64-bit)
    local commit86="$1" # "ed8e01ea0c69739ced597fecb5c3d61b96c5c761"
    local series="$2" # "RPI4"
    local arch="$3" # "ARM64" (ARM32 is not needed since it's default)

    if [ "$arch" == "ARM64" ]; then
	sudo dpkg --add-architecture armhf && sudo apt-get update
	sudo apt-get install libc6:armhf # needed to run box86:armhf on aarch64
	#sudo apt-get install libgtk2.0-0:armhf libsdl2-image-2.0-0:armhf libsdl1.2debian:armhf \
	#	libopenal1:armhf libvorbisfile3:armhf libgl1:armhf libjpeg62:armhf libcurl4:armhf \
	#	libasound2-plugins:armhf -y # not sure if needed. from: https://box86.org/2022/03/box86-box64-vs-qemu-vs-fex-vs-rosetta2/
        sudo apt-get install gcc-arm-linux-gnueabihf python3 build-essential gcc -y # extra libraries for building ARM32 on aarch64
    elif [ "$arch" == "ARM32" ]; then
        local arch="" # box86 builds ARM32 by default
    fi
    sudo apt-get install cmake git -y # box86 dependencies

    echo -e "${GREENTXT}Building and installing Box86 . . .${NORMTXT}"
    mkdir downloads 2>/dev/null; cd downloads
        mkdir box86; cd box86
            rm -rf box86-builder; mkdir box86-builder && cd box86-builder/
                git clone https://github.com/ptitSeb/box86 && cd box86/
                    git checkout "$commit86"
                    mkdir build; cd build
		    	if [ "${series}" = "RPi" ]; then
                        	cmake .. -DARM_DYNAREC=ON -D${series}${arch}=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
				echo "Compiling box86 for RPi on ${arch}"
			elif [ "${series}" = "RK3399" ]; then
				cmake .. -D${series}=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
				echo "Compiling box86 for RK3399 on ${arch}"
			else
				cmake .. -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo
				echo "Compiling box86 for unknown SBC on ${arch}"
			fi
			if [ "$(nproc)" > 1 ]; then
                        	make -j$(($(nproc)-2)) # compile using all processors minus two (to prevent OS freezes)
			else
				make
			fi
                        sudo make install
                        sudo systemctl restart systemd-binfmt
                    cd ..
                cd ..
            cd ..
        cd ..
    cd ..
}

function run_Sideload_i386wine() {
	# NOTE: We only really need i386-wine/box86 on RPiOS 64/32-bit for RMS Express and VARA since they are 32-bit.
	# We don't need really amd64-wine64/box64 for our purposes of running RMS Express and VARA.

	# Wine version variables
	local branch="$1" #example: "devel" or "stable" without quotes (wine-staging 4.5+ depends on libfaudio0 and requires more install steps)
	local version="$2" #example: "7.1"
	local id="$3" #example: debian ($ID_LIKE) - TODO: implement other distros, like Ubuntu
	local dist="$4" #example: bullseye ($VERSION_CODENAME)
	local tag="$5" #example: -1

	# Clean up any old wine instances
	wineserver -k &> /dev/null # stop any old wine installations from running - TODO: double-check this command
	rm -rf ~/.cache/wine # remove any old wine-mono or wine-gecko install files in case wine was installed previously
	rm -rf ~/.local/share/applications/wine # remove any old program shortcuts

	# Backup any old wine installs
	rm -rf ~/wine-old 2>/dev/null; mv ~/wine ~/wine-old 2>/dev/null
	rm -rf ~/.wine-old 2>/dev/null; mv ~/.wine ~/.wine-old 2>/dev/null
	sudo mv /usr/local/bin/wine /usr/local/bin/wine-old 2>/dev/null
	sudo mv /usr/local/bin/wineboot /usr/local/bin/wineboot-old 2>/dev/null
	sudo mv /usr/local/bin/winecfg /usr/local/bin/winecfg-old 2>/dev/null
	sudo mv /usr/local/bin/wineserver /usr/local/bin/wineserver-old 2>/dev/null

	# Wine download links from WineHQ: https://dl.winehq.org/wine-builds/
	#LNKA="https://dl.winehq.org/wine-builds/${id}/dists/${dist}/main/binary-amd64/" #amd64-wine links
	#DEB_A1="wine-${branch}-amd64_${version}~${dist}${tag}_amd64.deb" #wine64 main bin
	#DEB_A2="wine-${branch}_${version}~${dist}${tag}_amd64.deb" #wine64 support files (required for wine64 / can work alongside wine_i386 main bin)
		#DEB_A3="winehq-${branch}_${version}~${dist}${tag}_amd64.deb" #shortcuts & docs?
	LNKB="https://dl.winehq.org/wine-builds/${id}/dists/${dist}/main/binary-i386/" #i386-wine links
	DEB_B1="wine-${branch}-i386_${version}~${dist}${tag}_i386.deb" #wine_i386 main bin
	DEB_B2="wine-${branch}_${version}~${dist}${tag}_i386.deb" #wine_i386 support files (required for wine_i386 if no wine64 / CONFLICTS WITH wine64 support files)
		#DEB_B3="winehq-${branch}_${version}~${dist}${tag}_i386.deb" #shortcuts & docs?

	# Download, extract wine, and install wine
	mkdir downloads 2>/dev/null; cd downloads
		echo -e "${GREENTXT}Downloading wine . . .${NORMTXT}" # Install i386-wine (32-bit)
		wget -q ${LNKB}${DEB_B1} || { echo "${DEB_B1} download failed!" && run_giveup; }
		wget -q ${LNKB}${DEB_B2} || { echo "${DEB_B2} download failed!" && run_giveup; }
		echo -e "${GREENTXT}Extracting wine . . .${NORMTXT}"
		dpkg-deb -x ${DEB_B1} wine-installer
		dpkg-deb -x ${DEB_B2} wine-installer
		echo -e "${GREENTXT}Installing wine . . .${NORMTXT}\n"
		mv wine-installer/opt/wine* ~/wine
		
		## Install amd64-wine (64-bit) and i386-wine (32-bit)
		#echo -e "\n${GREENTXT}Downloading wine . . .${NORMTXT}"
		#wget -q ${LNKA}${DEB_A1} || { echo "${DEB_A1} download failed!" && run_giveup; }
		#wget -q ${LNKA}${DEB_A2} || { echo "${DEB_A2} download failed!" && run_giveup; }
		#wget -q ${LNKB}${DEB_B1} || { echo "${DEB_B1} download failed!" && run_giveup; }
		#echo -e "${GREENTXT}Extracting wine . . .${NORMTXT}"
		#dpkg-deb -x ${DEB_A1} wine-installer
		#dpkg-deb -x ${DEB_A2} wine-installer
		#dpkg-deb -x ${DEB_B1} wine-installer
		#echo -e "${GREENTXT}Installing wine . . .${NORMTXT}\n"
		#mv wine-installer/opt/wine* ~/wine	
	cd ..

	# Install symlinks (and make 32bit launcher. Credits: grayduck, Botspot) - TODO: Try to remove linux32 flag
	echo -e '#!/bin/bash\nsetarch linux32 -L '"$HOME/wine/bin/wine "'"$@"' | sudo tee -a /usr/local/bin/wine >/dev/null # script to launch wine programs as 32bit only
	#sudo ln -s ~/wine/bin/wine /usr/local/bin/wine # you could also just make a symlink, but box86 only works for 32bit apps at the moment
	sudo ln -s ~/wine/bin/wineboot /usr/local/bin/wineboot
	sudo ln -s ~/wine/bin/winecfg /usr/local/bin/winecfg
	sudo ln -s ~/wine/bin/wineserver /usr/local/bin/wineserver
	sudo chmod +x /usr/local/bin/wine /usr/local/bin/wineboot /usr/local/bin/winecfg /usr/local/bin/wineserver
}

function run_Install_i386wineDependencies_RpiOS64bit()
{
	# Install :armhf libraries to run i386-Wine on RPiOS 64-bit
	# - these packages are needed for running box86/wine-i386 on a 64-bit RPiOS via multiarch
	echo -e "${GREENTXT}Installing armhf dependencies for i386-Wine on aarch64 . . .${NORMTXT}"
	sudo dpkg --add-architecture armhf && sudo apt-get update #enable multi-arch
	
	#depends main packages - NOTE: This for loop method is inefficient, but ensures packages install even if some are missing.
	for i in 'libasound2:armhf' 'libc6:armhf' 'libglib2.0-0:armhf' 'libgphoto2-6:armhf' 'libgphoto2-port12:armhf' 'libgstreamer-plugins-base1.0-0:armhf' 'libgstreamer1.0-0:armhf' 'libldap-2.4-2:armhf' 'libopenal1:armhf' 'libpcap0.8:armhf' 'libpulse0:armhf' 'libsane1:armhf' 'libudev1:armhf' 'libusb-1.0-0:armhf' 'libvkd3d1:armhf' 'libx11-6:armhf' 'libxext6:armhf' 'libasound2-plugins:armhf' 'ocl-icd-libopencl1:armhf' 'libncurses6:armhf' 'libncurses5:armhf' 'libcap2-bin:armhf' 'libcups2:armhf' 'libdbus-1-3:armhf' 'libfontconfig1:armhf' 'libfreetype6:armhf' 'libglu1-mesa:armhf' 'libglu1:armhf' 'libgnutls30:armhf' 'libgssapi-krb5-2:armhf' 'libkrb5-3:armhf' 'libodbc1:armhf' 'libosmesa6:armhf' 'libsdl2-2.0-0:armhf' 'libv4l-0:armhf' 'libxcomposite1:armhf' 'libxcursor1:armhf' 'libxfixes3:armhf' 'libxi6:armhf' 'libxinerama1:armhf' 'libxrandr2:armhf' 'libxrender1:armhf' 'libxxf86vm1' 'libc6:armhf' 'libcap2-bin:armhf'; do
		sudo apt-get install -y "$i"
		done
		# This list found by downloading...
		#	wget https://dl.winehq.org/wine-builds/debian/dists/bullseye/main/binary-i386/wine-devel-i386_7.1~bullseye-1_i386.deb
		#	wget https://dl.winehq.org/wine-builds/debian/dists/bullseye/main/binary-i386/winehq-devel_7.1~bullseye-1_i386.deb
		#	wget https://dl.winehq.org/wine-builds/debian/dists/bullseye/main/binary-i386/wine-devel_7.1~bullseye-1_i386.deb
		# then `dpkg-deb -I package.deb`. Read output, add `:armhf` to packages in dep list, then try installing them on Pi aarch64.
	
	# Old i386-wine dependency list for box86/wine on aarch64 (worked for buster, but causes taskbar to disappear in bullseye) from Discord
	# Credits: monkaBlyat (Dr. van RockPi), Itai-Nelken, & WheezyE
	#sudo apt-get install libavcodec58:armhf libavformat58:armhf libboost-filesystem1.74.0:armhf libboost-iostreams1.74.0:armhf \
	#	libboost-program-options1.74.0:armhf libcal3d12v5:armhf libcups2:armhf libcurl4:armhf libfontconfig1:armhf \
	#	libfreetype6:armhf libgdk-pixbuf2.0-0:armhf libgl1-mesa-dev:armhf libgtk2.0-0:armhf libjpeg62:armhf libmpg123-0:armhf \
	#	libmyguiengine3debian1v5:armhf libncurses5:armhf libncurses6:armhf libopenal1:armhf libpng16-16:armhf \
	#	libsdl1.2-dev:armhf libsdl2-2.0-0:armhf libsdl2-image-2.0-0:armhf libsdl2-mixer-2.0-0:armhf libsdl2-net-2.0-0:armhf \
	#	libsdl-mixer1.2:armhf libsmpeg0:armhf libsnappy1v5:armhf libstdc++6:armhf libswscale5:armhf libudev1:armhf \
	#	libvorbis-dev:armhf libx11-6:armhf libx11-dev:armhf libxcb1:armhf libxcomposite1:armhf libxcursor1:armhf libxext6:armhf \
	#	libxi6:armhf libxinerama1:armhf libxrandr2:armhf libxrender1:armhf libxxf86vm1:armhf mesa-va-drivers:armhf osspd:armhf \
	#	pulseaudio:armhf -y # for i386-wine on aarch64 - TODO: Something in this list makes taskbar disappear (after reboot) in bullseye
	#	sudo apt-get install libasound2:armhf libpulse0:armhf libxml2:armhf libxslt1.1:armhf libxslt1-dev:armhf -y # fixes i386-wine sound? from Discord
}

function run_Install_i386wineDependencies_Ubuntu64bit()
{
	# Install :armhf libraries to run i386-Wine on Ubuntu 64-bit - TODO: SOMETHING IS NOT RIGHT WITH UBUNTU WINE ON armhf - using debian wine on ubuntu for now
	# - these packages are needed for running box86/wine-i386 on a 64-bit Ubuntu via multiarch
	echo -e "${GREENTXT}Installing armhf dependencies for i386-Wine on aarch64 . . .${NORMTXT}"
	sudo dpkg --add-architecture armhf && sudo apt-get update #enable multi-arch
	
	# NOTE: This for loop method is inefficient, but ensures packages install even if some are missing.
	for i in 'libasound2:armhf' 'libc6:armhf' 'libglib2.0-0:armhf' 'libgphoto2-6:armhf' 'libgphoto2-port12:armhf' 'libgstreamer-plugins-base1.0-0:armhf' 'libgstreamer1.0-0:armhf' 'libldap-2.5-0:armhf' 'libopenal1:armhf' 'libpcap0.8:armhf' 'libpulse0:armhf' 'libsane1:armhf' 'libudev1:armhf' 'libusb-1.0-0:armhf' 'libx11-6:armhf' 'libxext6:armhf' 'ocl-icd-libopencl1:armhf' 'libasound2-plugins:armhf' 'libncurses6:armhf'; do
		sudo apt-get install -y "$i" #depends main packages
		done
	for i in 'libopencl1:armhf' 'libopencl-1.2-1:armhf' 'libncurses5:armhf' 'libncurses:armhf'; do
		sudo apt-get install -y "$i" #depends alternate packages
		done
	for i in 'libcap2-bin:armhf' 'libcups2:armhf' 'libdbus-1-3:armhf' 'libfontconfig1:armhf' 'libfreetype6:armhf' 'libglu1-mesa:armhf' 'libgnutls30:armhf' 'libgssapi-krb5-2:armhf' 'libkrb5-3:armhf' 'libodbc1:armhf' 'libosmesa6:armhf' 'libsdl2-2.0-0:armhf' 'libv4l-0:armhf' 'libxcomposite1:armhf' 'libxcursor1:armhf' 'libxfixes3:armhf' 'libxi6:armhf' 'libxinerama1:armhf' 'libxrandr2:armhf' 'libxrender1:armhf' 'libxxf86vm1'; do
		sudo apt-get install -y "$i" #recommends main packages
		done
	for i in 'libglu1:armhf' 'libgnutls28:armhf' 'libgnutls26:armhf'; do
		sudo apt-get install -y "$i" #recommends alternate packages
		done
	
	#amd64-wine likes these packages too?
	sudo apt-get install -y 'libunwind8:armhf' 
	sudo apt-get install -y 'libjpeg62-turbo:armhf'
	sudo apt-get install -y 'libjpeg8:armhf'
	
	# Ubuntu will complain about /usr/lib/arm-linux-gnueabihf/ld-linux-armhf.so.3 crashing /usr/sbin/capsh. We can silent the error message.
	sudo sed -i 's+enabled=1+enabled=0+g' /etc/default/apport

	# This list found by downloading...
	#	wget https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/main/binary-i386/wine-devel-i386_7.7~jammy-1_i386.deb
	#	wget https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/main/binary-i386/winehq-devel_7.7~jammy-1_i386.deb
	#	wget https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/main/binary-i386/wine-devel_7.7~jammy-1_i386.deb
	# then `dpkg-deb -I package.deb`. Read output, add `:armhf` to packages in dep list, then try installing them on Pi aarch64.
	# I think installing these might mess up the system: 'debconf-2.0:armhf' 'debconf:armhf'
}

function run_Sideload_amd64wineWithi386wine()
{
	# NOTE: Can only run on aarch64 (since box64 can only run on aarch64)
	# box64 runs wine-amd64, box86 runs wine-i386.
	# NOTE: We only really need i386-wine/box86 on RPiOS 64/32-bit for RMS Express and VARA since they are 32-bit.
	# We don't need really amd64-wine64/box64 for our purposes of running RMS Express and VARA.
  	
  	# Wine version variables
	local branch="$1" #example: devel, staging, or stable (wine-staging 4.5+ requires libfaudio0:i386)
	local version="$2" #example: "7.1"
	local id="$3" #example: debian, ubuntu
	local dist="$4" #example (for debian): bullseye, buster, jessie, wheezy, ${VERSION_CODENAME}, etc 
	local tag="$5" #example: -1 (some wine .deb files have -1 tag on the end and some don't)

	# Clean up any old wine instances
	wineserver -k &> /dev/null # stop any old wine installations from running
	rm -rf ~/.cache/wine # remove any old wine-mono/wine-gecko install files
	rm -rf ~/.local/share/applications/wine # remove any old program shortcuts

	# Backup any old wine installs
	rm -rf ~/wine-old 2>/dev/null; mv ~/wine ~/wine-old 2>/dev/null
	rm -rf ~/.wine-old 2>/dev/null; mv ~/.wine ~/.wine-old 2>/dev/null
	sudo mv /usr/local/bin/wine /usr/local/bin/wine-old 2>/dev/null
	sudo mv /usr/local/bin/wine64 /usr/local/bin/wine-old 2>/dev/null
	sudo mv /usr/local/bin/wineboot /usr/local/bin/wineboot-old 2>/dev/null
	sudo mv /usr/local/bin/winecfg /usr/local/bin/winecfg-old 2>/dev/null
	sudo mv /usr/local/bin/wineserver /usr/local/bin/wineserver-old 2>/dev/null

	# Wine download links from WineHQ: https://dl.winehq.org/wine-builds/
	LNKA="https://dl.winehq.org/wine-builds/${id}/dists/${dist}/main/binary-amd64/" #amd64-wine links
	DEB_A1="wine-${branch}-amd64_${version}~${dist}${tag}_amd64.deb" #wine64 main bin
	DEB_A2="wine-${branch}_${version}~${dist}${tag}_amd64.deb" #wine64 support files (required for wine64 / can work alongside wine_i386 main bin)
		#DEB_A3="winehq-${branch}_${version}~${dist}${tag}_amd64.deb" #shortcuts & docs
	LNKB="https://dl.winehq.org/wine-builds/${id}/dists/${dist}/main/binary-i386/" #i386-wine links
	DEB_B1="wine-${branch}-i386_${version}~${dist}${tag}_i386.deb" #wine_i386 main bin
	DEB_B2="wine-${branch}_${version}~${dist}${tag}_i386.deb" #wine_i386 support files (required for wine_i386 if no wine64 / CONFLICTS WITH wine64 support files)
		#DEB_B3="winehq-${branch}_${version}~${dist}${tag}_i386.deb" #shortcuts & docs

	# Install amd64-wine (64-bit) alongside i386-wine (32-bit)
	echo -e "Downloading wine . . ."
	wget -q ${LNKA}${DEB_A1} 
	wget -q ${LNKA}${DEB_A2} 
	wget -q ${LNKB}${DEB_B1} 
	echo -e "Extracting wine . . ."
	dpkg-deb -x ${DEB_A1} wine-installer
	dpkg-deb -x ${DEB_A2} wine-installer
	dpkg-deb -x ${DEB_B1} wine-installer
	echo -e "Installing wine . . ."
	mv wine-installer/opt/wine* ~/wine

	# These packages are needed for running wine-staging on RPiOS (Credits: chills340)
	sudo apt install libstb0 -y
	cd ~/Downloads
	wget -r -l1 -np -nd -A "libfaudio0_*~bpo10+1_i386.deb" http://ftp.us.debian.org/debian/pool/main/f/faudio/ # Download libfaudio i386 no matter its version number
	dpkg-deb -xv libfaudio0_*~bpo10+1_i386.deb libfaudio
	sudo cp -TRv libfaudio/usr/ /usr/
	rm libfaudio0_*~bpo10+1_i386.deb # clean up
	rm -rf libfaudio # clean up

	# Install symlinks
	sudo ln -s ~/wine/bin/wine /usr/local/bin/wine
	sudo ln -s ~/wine/bin/wine64 /usr/local/bin/wine64
	sudo ln -s ~/wine/bin/wineboot /usr/local/bin/wineboot
	sudo ln -s ~/wine/bin/winecfg /usr/local/bin/winecfg
	sudo ln -s ~/wine/bin/wineserver /usr/local/bin/wineserver
	sudo chmod +x /usr/local/bin/wine /usr/local/bin/wine64 /usr/local/bin/wineboot /usr/local/bin/winecfg /usr/local/bin/wineserver
}

function run_Install_amd64wineDependencies_RpiOS64bit()
{
	# Download wine64 dependencies
	# - these packages are needed for running box64/wine-amd64 on RPiOS (box64 only runs on 64-bit OS's)
	sudo apt-get install -y libasound2:arm64 libc6:arm64 libglib2.0-0:arm64 libgphoto2-6:arm64 libgphoto2-port12:arm64 \
		libgstreamer-plugins-base1.0-0:arm64 libgstreamer1.0-0:arm64 libldap-2.4-2:arm64 libopenal1:arm64 libpcap0.8:arm64 \
		libpulse0:arm64 libsane1:arm64 libudev1:arm64 libunwind8:arm64 libusb-1.0-0:arm64 libvkd3d1:arm64 libx11-6:arm64 libxext6:arm64 \
		ocl-icd-libopencl1:arm64 libasound2-plugins:arm64 libncurses6:arm64 libncurses5:arm64 libcups2:arm64 \
		libdbus-1-3:arm64 libfontconfig1:arm64 libfreetype6:arm64 libglu1-mesa:arm64 libgnutls30:arm64 \
		libgssapi-krb5-2:arm64 libjpeg62-turbo:arm64 libkrb5-3:arm64 libodbc1:arm64 libosmesa6:arm64 libsdl2-2.0-0:arm64 libv4l-0:arm64 \
		libxcomposite1:arm64 libxcursor1:arm64 libxfixes3:arm64 libxi6:arm64 libxinerama1:arm64 libxrandr2:arm64 \
		libxrender1:arm64 libxxf86vm1:arm64 libc6:arm64 libcap2-bin:arm64
		# This list found by downloading...
		#	wget https://dl.winehq.org/wine-builds/debian/dists/bullseye/main/binary-amd64/wine-devel_7.1~bullseye-1_amd64.deb
		#	wget https://dl.winehq.org/wine-builds/debian/dists/bullseye/main/binary-amd64/wine-devel-amd64_7.1~bullseye-1_amd64.deb
		# then `dpkg-deb -I package.deb`. Read output, add `:arm64` to packages in dep list, then try installing them on Pi aarch64.	
		
	# Old: Wine-amd64 on aarch64 needs some 64-bit libs
	#	sudo apt-get install apt-utils libcups2 libfontconfig1 libncurses6 libxcomposite-dev libxcursor-dev libxi6 libxinerama1 libxrandr2 libxrender1 -y
	#	sudo apt-get install libpulse0 -y # not sure if needed, but probably can't hurt
}

function run_installwinemono()  # Wine-mono replaces MS.NET 4.6 and earlier.
{
    # MS.NET 4.6 takes a very long time to install on RPi4 in Wine and runs slower than wine-mono
    sudo apt-get install p7zip-full -y
    mkdir ~/.cache/wine 2>/dev/null
    echo -e "\n${GREENTXT}Downloading and installing wine-mono . . .${NORMTXT}\n"
    wget -q -P ~/.cache/wine https://dl.winehq.org/wine/wine-mono/7.2.0/wine-mono-7.2.0-x86.msi  || { echo "wine-mono .msi install file download failed!" && run_giveup; }
    wine msiexec /i ~/.cache/wine/wine-mono-7.2.0-x86.msi
    rm -rf ~/.cache/wine # clean up to save disk space
}

function run_increasepi3swapfile()
{
	# Thank you to K4OAM for the suggestion that a larger swap file can help Pi3 compatability with Wine/box86
	# - Instructions from https://pimylifeup.com/raspberry-pi-swap-file/
	# 73 de KI7POL (WheezyE)
	sudo sed -i 's+#CONF_SWAPSIZE\=+CONF_SWAPSIZE\=+g' /etc/dphys-swapfile # Uncomment #CONF_SWAPSIZE= (in case it's commented-out)
	source /etc/dphys-swapfile # Have bash read the 'CONF_SWAPSIZE=' line so that it becomes a bash variable.
	if [[ "${CONF_SWAPSIZE}" == "" ]]; then
		echo -e "Swap file not found. Strange...\nContinuing without swap file increase..."
	elif (( ${CONF_SWAPSIZE} < 750 )); then
		echo -e "Increasing swap file size to 750MByte."
		sudo dphys-swapfile swapoff
		sudo sed -i 's+CONF_SWAPSIZE\='"${CONF_SWAPSIZE}"'+CONF_SWAPSIZE\=750+g' /etc/dphys-swapfile
		sudo dphys-swapfile setup
		sudo dphys-swapfile swapon
		echo "Continuing with kernel swap."
	elif (( ${CONF_SWAPSIZE} >= 750 )); then
		echo -e "Swap file size is already 750MByte or larger."
	fi
}


function run_custompi3kernel() # Needed to run wine on Pi3's running RPiOS (32-bit)
{
	# Wine requires a linux 3G/1G VM split in the kernel.
	#     Raspberry Pi OS (32-bit) on Pi3 has a 2G/2G split though, which will not work with Wine.
	#     Raspberry Pi OS (64-bit) on Pi3 has a 3G/1G split, which will work with Wine.
	# For RPiOS 32-bit on Pi3, we can either compile a custom 32-bit kernel on-device (takes several hours), download a pre-compiled 
	#     custom 32-bit kernel (takes ~2 min, might be outdated), or switch to RPiOS 64-bit (takes ~2 min, might mess up user programs).
	#     All methods require a reboot before wine will work.
	# To avoid surprising the user by switching their OS from 32-bit to 64-bit without permission, we will try to download a kernel 
	#     first, but then compile a kernel instead if the download fails.
	#
	# This kernel-VM-split swapping method (2G/2G -> 3G/1G) for Pi3 was copied and modified from Botspot's PiApps code with permission.
	#     https://github.com/Botspot/pi-apps/blob/1ce54b670c13119986474224415a34b90b281d82/apps/Wine%20(x86)/install-32#L11
	
	# Thank you Botspot for this code!!!
	
	local kernelswapmethod="$1" # TODO: Have this function auto-try the other methods if the first method fails.
	
	if [ ! -e /proc/config.gz ]; then # TODO: Revamp this kernel switcher with custom links and more reliable vmsplit detection https://forums.raspberrypi.com/viewtopic.php?p=2042152#p2042152
		sudo modprobe configs # Kludge: Run twice just in case (to try to help RPi3 64bit OS install)
		sudo modprobe configs || { echo -e "Cannot find kernel 'configs' module.\nTry rebooting your Pi and re-running this install." && run_giveup; }
		if [ ! -e /proc/config.gz ]; then
			{ echo "/proc/config.gz does not exist after running sudo modprobe configs!" && run_giveup; }
		fi
	fi

	vmsplit_output="$(gunzip < /proc/config.gz | grep VMSPLIT)"
	if [ -z "$vmsplit_output" ]; then
		kernel="$(uname -m)"
		if [ $kernel == aarch64 ]; then
			echo "No memory split information due to running a 64-bit kernel. Continuing..."
		else
			echo "No memory split information and not running a 64-bit kernel. Strange."
			sleep 2
			echo "Continuing..."
		fi
	elif echo "$vmsplit_output" | grep -q "^CONFIG_VMSPLIT_2G=y" || echo "$vmsplit_output" | grep -q "^# CONFIG_VMSPLIT_3G is not set" ; then #ensure hardware is armv7 for kernel compiling to work
		if [[ "$SBC_SERIES" != 'RPi3' && "$SBC_SERIES" != "RPi3+" ]]; then
			echo "User error: This script is not capable of handling your $SBC_SERIES board with a 2G/2G memory split.\nWhatever you did to get yourself into this situation, undo it and try installing Wine again."
			run_giveup
		#ensure /boot/config.txt exists to make sure this is a rpi board
		elif [ ! -f /boot/config.txt ]; then
			echo "User error: Your system is not currently compatible with Wine. It needs a kernel with 3G/1G memory split. This is easy to do: switch to the 64-bit kernel by adding a line to /boot/config.txt. However, that file does not exist. Most likely you are trying to use Winelink on an unsupported device or operating system."
			run_giveup
		fi
		
		echo -e "You are using a kernel with a 2G/2G memory split.\nWine will not work on such systems. We will now install a custom 3G/1G kernel."
		# 1. Install a precompiled 3G/1G kernel (about 2 minutes but might be outdated)
		# 2. Compile a 3G/1G kernel (several hours)
		# 3. Switch to the 64-bit kernel (about 2 minutes)
		if [ "$kernelswapmethod" == 1 ]; then #install precompiled 3g/1g kernel
			#backup ~/linux if it exists
			rm -rf ~/linux.bak
			[ -e ~/linux ] && (echo "$HOME/linux already exists, moving it to $HOME/linux.bak" ; mv -f ~/linux ~/linux.bak)
			#download precompiled kernel
			cd $HOME
			echo "Downloading precompiled kernel..."
			wget -q https://github.com/Itai-Nelken/RPi-3g-1g-kernel-wine/releases/download/5/rpi23_3g1g_kernel.zip -O ~/3g1g-rpi-kernel.zip || { echo "Failed to download prebuilt kernel!" && run_giveup; }
			#extract precompiled kernel
			echo "Extracting prebuilt kernel..."
			sleep 0.5 # so user has time to read what is happening
			unzip ~/3g1g-rpi-kernel.zip || { echo "Failed to extract kernel!" && run_giveup; }
			cd linux || { echo "Failed to change folder to ~/linux!" && run_giveup; }
			#install the precompiled kernel
			export KERNEL=kernel7
			sudo make modules_install || { echo "sudo make modules_install failed!" && run_giveup; }
			sudo cp arch/arm/boot/dts/*.dtb /boot/ || { echo "Failed to copy dtb files to /boot!" && run_giveup; }
			sudo cp arch/arm/boot/dts/overlays/*.dtb* /boot/overlays/ || { echo "Failed to copy overlays to /boot/overlays!" && run_giveup; }
			sudo cp arch/arm/boot/dts/overlays/README /boot/overlays/
			sudo cp arch/arm/boot/zImage /boot/$KERNEL.img || { echo "Failed to copy kernel to /boot/$KERNEL.img!" && run_giveup; }
			cd
			rm -rf linux ~/3g1g-rpi-kernel.zip
			#message
			echo -e "\e[1mIt appears the precompiled 3G/1G kernel has been installed successfully.\nPlease reboot and install Winelink again.\e[0m"
			sleep infinity
		elif [ "$kernelswapmethod" == 2 ]; then #compile 3g/1g kernel
			#backup ~/linux if it exists
			rm -rf ~/linux.bak
			[ -e ~/linux ] && (echo "$HOME/linux already exists, moving it to $HOME/linux.bak" ; mv -f ~/linux ~/linux.bak)
			
			echo "Installing necessary build packages..."
			sudo apt-get install raspberrypi-kernel-headers build-essential bc git wget bison flex libssl-dev make libncurses-dev -y

			#download kernel source code
			cd $HOME
			git clone --depth=1 https://github.com/raspberrypi/linux || { echo "Failed to clone the raspberry pi kernel repo!" && run_giveup; }

			#build for pi3
			cd ~/linux || { echo "Failed to enter the ~/linux folder!" && run_giveup; }
			KERNEL=kernel7
			make -j$(($(nproc)-2)) bcm2709_defconfig || { echo "The make command exited with failure. Full command: 'make -j$(($(nproc)-2)) bcm2709_defconfig'" && run_giveup; }

			#change memory split config
			echo "Setting memory split to 3G/1G"
			sed -i 's/CONFIG_VMSPLIT_2G=y/# CONFIG_VMSPLIT_2G is not set/g' ~/linux/.config || { echo "sed failed to edit $HOME/linux/.config file!" && run_giveup; }
			sed -i 's/# CONFIG_VMSPLIT_3G is not set/CONFIG_VMSPLIT_3G=1/g' ~/linux/.config

			echo '' | make -j$(($(nproc)-2)) zImage modules dtbs || { echo "Failed to make bcm2709_defconfig zImage modules dtbs!" && run_giveup; }

			#install
			echo "Copying new files to /boot/..."
			sudo make modules_install || { echo "sudo make modules_install failed!" && run_giveup; }
			sudo cp arch/arm/boot/dts/*.dtb /boot/ || { echo "Failed to copy dtb files to /boot!" && run_giveup; }
			sudo cp arch/arm/boot/dts/overlays/*.dtb* /boot/overlays/ || { echo "Failed to copy overlays to /boot/overlays!" && run_giveup; }
			sudo cp arch/arm/boot/dts/overlays/README /boot/overlays/
			sudo cp arch/arm/boot/zImage /boot/$KERNEL.img || { echo "Failed to copy kernel to /boot/$KERNEL.img!" && run_giveup; }
			cd
			rm -rf ~/linux

			#message
			echo -e "It appears the 3G/1G kernel has been built and installed successfully.\nPlease reboot and install Winelink again."
			sleep infinity
		elif [ "$kernelswapmethod" == 3 ]; then #switch to 64bit kernel
			echo "arm_64bit=1" | sudo tee --append /boot/config.txt >/dev/null
			echo -e "The 64-bit kernel has been enabled by adding 'arm_64bit=1' to /boot/config.txt\nPlease reboot and install Winelink again."
			sleep infinity
		else
			echo "Invalid method input. Must be '1', '2', or '3'."
			run_giveup
		fi
	else
		echo "Your system is using a 3G/1G kernel. Continuing..."
	fi
	
	#Past this point, the pi is running a Wine-compatible kernel. Wine should now run ok.
}


function run_installwinetricks() # Download and install winetricks
{
    sudo apt-get remove winetricks -y
    sudo apt-get install cabextract -y # winetricks needs this
    mkdir downloads 2>/dev/null; cd downloads
        echo -e "\n${GREENTXT}Downloading and installing winetricks . . .${NORMTXT}\n"
        sudo mv /usr/local/bin/winetricks /usr/local/bin/winetricks-old 2>/dev/null # backup any old winetricks installs
        wget -q https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks || { echo "Winetricks download failed!" && run_giveup; } # download
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
        DISPLAY=0 WINEARCH=win32 WINEDEBUG=-all wine wineboot # initialize Wine silently (silently makes a fresh wineprefix in `~/.wine`)

    # Install pre-requisite software into the wineprefix for RMS Express and VARA
        if [ "$varaonly" = "vara_only" ]; then
	    echo -e "\n${GREENTXT}Setting up your wineprefix for VARA . . .${NORMTXT}\n"
	    BOX86_NOBANNER=1 winetricks -q vb6run pdh_nt4 win7 sound=alsa || { echo "Winetricks failed to download/install VB6 or PDH.DLL!" && run_giveup; } # for VARA
	    #WTERR_VB6RUN=$( winetricks -q vb6run | tee /dev/stderr | grep -o -P '(warning: Downloading )(.*?)(VB6.0-KB290887-X86.exe failed)' ) # more precise error reporting
	else
	    echo -e "\n${GREENTXT}Setting up your wineprefix for RMS Express & VARA . . .${NORMTXT}\n"
	    run_installwinemono # for RMS Express - wine-mono replaces dotnet46
	    #BOX86_NOBANNER=1 winetricks -q dotnet46 win7 sound=alsa # for RMS Express
	    BOX86_NOBANNER=1 winetricks -q vb6run pdh_nt4 win7 sound=alsa || { echo "Winetricks failed to download/install VB6 or PDH.DLL!" && run_giveup; } # for VARA
	fi
	# TODO: Check to see if 'winetricks -q corefonts riched20' would make text look nicer
}

function run_installahk()
{
    sudo apt-get install p7zip-full -y # TODO: remove redundant apt-get installs - put them at top of script.
    mkdir downloads 2>/dev/null; cd downloads
        # Download AutoHotKey
	echo -e "\n${GREENTXT}Downloading AutoHotkey . . .${NORMTXT}\n"
        wget -q https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.1.36.02/AutoHotkey_1.1.36.02_setup.exe || { echo "AutoHotkey download failed!" && run_giveup; }
        7z e AutoHotkey_1.1.36.02_setup.exe AutoHotkeyU32.exe -y -bsp0 -bso0
	mkdir ${HOME}/winelink 2>/dev/null
	mkdir ${AHK}
	sudo mv AutoHotkeyU32.exe ${AHK}/AutoHotkey.exe
	sudo chmod +x ${AHK}/AutoHotkey.exe
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

function run_installvarAC()  # Download/extract/install varAC chat app
{
    mkdir downloads 2>/dev/null; cd downloads
        # Download varAC linux working version 6.1 (static Link as no dynamic link known at the moment)
            echo -e "\n${GREENTXT}Downloading and installing VarAC . . .${NORMTXT}\n"
            wget -q https://varac.hopp.to/varac_latest || { echo "VarAC download failed!" && run_giveup; }
            
        # Extract/install VarAC
            mkdir -p ${HOME}/.wine/drive_c/VarAC
            7z x varac_latest -aoa -y -o"${HOME}/.wine/drive_c/VarAC" -bsp0 -bso0
            
	# Extract VarAC Windows icon then convert it to png for Linux
	    sudo apt-get install icoutils -y # installs wrestool & icotool
            wrestool -x --output=${HOME}'/.wine/drive_c/VarAC/varac.ico' -t14 ${HOME}'/.wine/drive_c/VarAC/VarAC.exe' 2>/dev/null; # extract ico from exe
            mkdir ${HOME}'/.wine/drive_c/VarAC/img/' 2>/dev/null;
            icotool -x -o ${HOME}'/.wine/drive_c/VarAC/img/' ${HOME}'/.wine/drive_c/VarAC/varac.ico' 2>/dev/null; # extract png from ico
	    VARACICON="$(basename $(find ${HOME}'/.wine/drive_c/VarAC/img/' -maxdepth 1 -type f  -printf "%s\t%p\n" | sort -n | tail -1 | awk '{print $NF}'))" 2>/dev/null; # store name of largest png - https://unix.stackexchange.com/a/565995
            
        # Clean up
            rm -rf varac_latest
            
        # Make a VarAC Chat desktop shortcut
            echo '[Desktop Entry]'                                                                             | sudo tee ${STARTMENU}/VarAC.desktop > /dev/null
            echo 'Name=VarAC Chat'                                                                             | sudo tee -a ${STARTMENU}/VarAC.desktop > /dev/null
            echo 'GenericName=VarAC Chat'                                                                      | sudo tee -a ${STARTMENU}/VarAC.desktop > /dev/null
            echo 'Comment=VarAC emulated with Box86/Wine'                                                      | sudo tee -a ${STARTMENU}/VarAC.desktop > /dev/null
            echo 'Exec=env BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine '$HOME'/.wine/drive_c/VarAC/VarAC.exe' | sudo tee -a ${STARTMENU}/VarAC.desktop > /dev/null
            echo 'Type=Application'                                                                            | sudo tee -a ${STARTMENU}/VarAC.desktop > /dev/null
            echo 'StartupNotify=true'                                                                          | sudo tee -a ${STARTMENU}/VarAC.desktop > /dev/null
            echo 'Icon='$HOME'/.wine/drive_c/VarAC/img/'${VARACICON}                                           | sudo tee -a ${STARTMENU}/VarAC.desktop > /dev/null
            echo 'StartupWMClass=VarAC.exe'                                                                    | sudo tee -a ${STARTMENU}/VarAC.desktop > /dev/null
            echo 'Categories=HamRadio;'                                                                        | sudo tee -a ${STARTMENU}/VarAC.desktop > /dev/null
    cd ..
}

function run_varACsetup() # TODO: This is a kludge until VarAC can be patched to find its own config files / not put them into the user home directory!!!
{
        # Set up VarAC for the user
            #cp ${HOME}'/.wine/drive_c/VarAC/VarAC.ini' ${HOME}'/VarAC.ini' # This will be created when we run VarAC (copying before running VarAC is unstable for some reason).
            cp ${HOME}'/.wine/drive_c/VarAC/VarAC_alert_tags.conf' ${HOME}'/VarAC_alert_tags.conf' 2>/dev/null; # Kludge: VarAC can't find its files on Wine
            cp ${HOME}'/.wine/drive_c/VarAC/VarAC_frequencies.conf' ${HOME}'/VarAC_frequencies.conf' 2>/dev/null; # Kludge: VarAC can't find its files on Wine
            cp ${HOME}'/.wine/drive_c/VarAC/VarAC_cat_commands.ini' ${HOME}'/VarAC_cat_commands.ini' 2>/dev/null; # Kludge: VarAC can't find its files on Wine
	    
	# Guide the user to enter Callsign/Grid into VarAC's menu (configure hardware soundcard input/output)
            clear
            #echo -e "\n${GREENTXT}Loading VarAC . . .${NORMTXT}\n"
            #echo -e "\n${GREENTXT}Please enter your Callsign & Gridsquare into the VarAC settings box\n(click 'Ok' on the user prompt textbox to continue)\n\nThis might take a moment.${NORMTXT}\n"
            #zenity --info --height 100 --width 350 --text="We will now setup your Callsign &amp; Gridsquare for VarAC. \n\nInstall will continue once you have closed the VarAC Settings menu." --title="VarAC User Info Setup"
            echo -e "\n${GREENTXT}Configuring VarAC now . . .${NORMTXT}\n"
	    echo -e "\n${GREENTXT}Note: This might take a moment${NORMTXT}\n"
            
	# Create/run varaac_configure.ahk
		# VarAC must be run once an then closed so that it makes a 'VarAC.ini' file in the user home directory. Then we can modify that file.
		# First run of VarAC will also prompt the user for CallSn & Grid.
		echo '; AHK script to assist users in setting up VARA on its first run'                > ${AHK}/varac_configure.ahk
		echo 'SetTitleMatchMode, 2'                                                            >> ${AHK}/varac_configure.ahk
		echo 'SetTitleMatchMode, slow'                                                         >> ${AHK}/varac_configure.ahk
		echo '        Run, C:\VarAC\VarAC.exe'                                                 >> ${AHK}/varac_configure.ahk
		echo '        WinWait, Callsign missing ; Wait for VarAC to open'                      >> ${AHK}/varac_configure.ahk
		echo '        WinActivate, Callsign missing'                                           >> ${AHK}/varac_configure.ahk
		echo '        Send, {Enter}'                                                           >> ${AHK}/varac_configure.ahk
		echo '        WinWait, My Information ; Wait for VarAC to open'                        >> ${AHK}/varac_configure.ahk
		echo '        WinActivate, My Information'                                             >> ${AHK}/varac_configure.ahk
		echo '        Send, {X}'                                                               >> ${AHK}/varac_configure.ahk
		echo '        Send, {X}'                                                               >> ${AHK}/varac_configure.ahk
		echo '        Send, {X}'                                                               >> ${AHK}/varac_configure.ahk
		echo '        Send, {X}'                                                               >> ${AHK}/varac_configure.ahk
		echo '        Send, {X}'                                                               >> ${AHK}/varac_configure.ahk
		echo '        Send, {X}'                                                               >> ${AHK}/varac_configure.ahk
		echo '        Send, {Tab}'                                                             >> ${AHK}/varac_configure.ahk
		echo '        Send, {Tab}'                                                             >> ${AHK}/varac_configure.ahk
		echo '        Send, {Tab}'                                                             >> ${AHK}/varac_configure.ahk
		echo '        Send, {A}'                                                               >> ${AHK}/varac_configure.ahk
		echo '        Send, {A}'                                                               >> ${AHK}/varac_configure.ahk
		echo '        Send, {0}'                                                               >> ${AHK}/varac_configure.ahk
		echo '        Send, {0}'                                                               >> ${AHK}/varac_configure.ahk
		echo '        Send, {X}'                                                               >> ${AHK}/varac_configure.ahk
		echo '        Send, {X}'                                                               >> ${AHK}/varac_configure.ahk
		echo '        Send, {Tab}'                                                             >> ${AHK}/varac_configure.ahk
		echo '        Send, {Tab}'                                                             >> ${AHK}/varac_configure.ahk
		echo '        Send, {Tab}'                                                             >> ${AHK}/varac_configure.ahk
		echo '        Send, {Tab}'                                                             >> ${AHK}/varac_configure.ahk
		echo '        Send, {Enter}'                                                           >> ${AHK}/varac_configure.ahk
		echo '        WinWait, Restart required ; Wait for VarAC to open'                      >> ${AHK}/varac_configure.ahk
		echo '        WinActivate, Restart required'                                           >> ${AHK}/varac_configure.ahk
		echo '        Send, {Enter}'                                                           >> ${AHK}/varac_configure.ahk
		echo '        WinWait, VARA HF ; Wait for VARA to open'                                >> ${AHK}/varac_configure.ahk
		echo '        WinMinimize, VARA HF ; Minimize VARA'                                    >> ${AHK}/varac_configure.ahk
		echo '        WinWait, Change frequency Manually ; Wait for VarAC to open'             >> ${AHK}/varac_configure.ahk
		echo '        WinActivate, Change frequency Manually'                                  >> ${AHK}/varac_configure.ahk
		echo '        Send, {Enter}'                                                           >> ${AHK}/varac_configure.ahk
		echo '        WinWait, VarAC ; Wait for VarAC to open'                                 >> ${AHK}/varac_configure.ahk
		echo '        WinClose, VarAC ; Close VarAC'                                           >> ${AHK}/varac_configure.ahk
		BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine ${HOME}/winelink/ahk/AutoHotkey.exe ${AHK}/varac_configure.ahk # nobanner option to make console prettier
		rm ${AHK}/varac_configure.ahk
		sleep 5
	    
            sed -i 's&Mycall=XXXXXX&Mycall=&' ${HOME}'/VarAC.ini' 2>/dev/null;
            sed -i 's&MyLocator=AA00XX&MyLocator=&' ${HOME}'/VarAC.ini' 2>/dev/null;
            sed -i 's&LinuxCompatibleMode=OFF&LinuxCompatibleMode=ON&' ${HOME}'/VarAC.ini' 2>/dev/null;
            sed -i 's&VaraModemType=&VaraModemType=VaraHF&' ${HOME}'/VarAC.ini' 2>/dev/null;
            sed -i 's&VarahfMainKissPort=8100&VarahfMainKissPort=8100\nVarahfMainPath=C:\\VARA\\VARA.exe\nVarahfMainPort=8300\nVarahfMonitorPort=8350&' ${HOME}'/VarAC.ini' 2>/dev/null;
            mkdir ${HOME}'/.wine/drive_c/VarAC/incoming' 2>/dev/null;
            mkdir ${HOME}'/.wine/drive_c/VarAC/outgoing' 2>/dev/null;
            sed -i 's&IncomingFilesDir=&IncomingFilesDir=C:\\VarAC\\incoming\\&' ${HOME}'/VarAC.ini' 2>/dev/null;
            sed -i 's&OutgoingFilesDir=&OutgoingFilesDir=C:\\VarAC\\outgoing\\&' ${HOME}'/VarAC.ini' 2>/dev/null;
            sed -i 's&IncomingFilesSizeLimit=1000&IncomingFilesSizeLimit=1000000&' ${HOME}'/VarAC.ini' 2>/dev/null;
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
	rm ${HOME}/winelink/override-x11.reg 2>/dev/null # silently remove Win registry file

    # Install dll's needed by users of "RA-boards," like the DRA-50
    #  https://masterscommunications.com/products/radio-adapter/dra/dra-index.html
       #BOX86_NOBANNER=1 winetricks -q hid # unsure if this is needed...
       ##sudo apt-get install p7zip-full -y
       ##wget -q http://uz7.ho.ua/modem_beta/ptt-dll.zip
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
					megadl ${VARAHFLINK} --path=${VARAUPDATE} || { echo "VARA HF download failed!" && run_giveup; }
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
					BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine ${AHK}/AutoHotkey.exe ${AHK}/varahf_install.ahk # install VARA silently using AHK
				
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
					megadl ${VARAFMLINK} --path=${VARAUPDATE} || { echo "VARA FM download failed!" && run_giveup; }
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
					BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine ${AHK}/AutoHotkey.exe ${AHK}/varafm_install.ahk # install VARA silently using AHK

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

		#	# Download / extract / silently install VARA SAT
		#		# Search the rosmodem website for a VARA SAT mega.nz link of any version, then download it
		#			echo -e "\n${GREENTXT}Downloading VARA SAT . . .${NORMTXT}\n"
		#			VARAFMLINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA SAT v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
		#			megadl ${VARAFMLINK} --path=${VARAUPDATE} || { echo "VARA SAT download failed!" && run_giveup; }
		#			7z x ${VARAUPDATE}/VARA\ SAT*.zip -o"${VARAUPDATE}/VARASATInstaller" -y -bsp0 -bso0
		#			mv ${VARAUPDATE}/VARASATInstaller/VARA\ SAT\ setup*.exe ~/.wine/drive_c/ # move VARA installer here (so AHK can find it later)
		#
		#		# Create varasat_install.ahk autohotkey script
		#			# The VARA installer prompts the user to hit 'OK' even during silent install (due to a secondary installer).  We will suppress this prompt with AHK.
		#			echo '; AHK script to make VARA installer run completely silent'                       > ${AHK}/varasat_install.ahk
		#			echo 'SetTitleMatchMode, 2'                                                            >> ${AHK}/varasat_install.ahk
		#			echo 'SetTitleMatchMode, slow'                                                         >> ${AHK}/varasat_install.ahk
		#			echo '        Run, VARA SAT setup (Run as Administrator).exe /SILENT, C:\'             >> ${AHK}/varasat_install.ahk
		#			echo '        WinWait, VARA Setup ; Wait for the "VARA installed successfully" window' >> ${AHK}/varasat_install.ahk
		#			echo '        ControlClick, Button1, VARA Setup ; Click the OK button'                 >> ${AHK}/varasat_install.ahk
		#			echo '        WinWaitClose'                                                            >> ${AHK}/varasat_install.ahk
		#
		#		# Run varasat_install.ahk
		#			echo -e "\n${GREENTXT}Installing VARA SAT . . .${NORMTXT}\n"
		#			BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine ${AHK}/AutoHotkey.exe ${AHK}/varasat_install.ahk # install VARA silently using AHK
		#
		#		# Clean up the installation
		#			rm ~/.wine/drive_c/VARA\ SAT\ setup*.exe
		#			rm ${AHK}/varasat_install.ahk
		#			sleep 3; sudo rm -rf ${HOME}/.local/share/applications/wine/Programs/VARA # Remove wine's auto-generated VARA SAT program icon from the start menu
		#
		#		# Make a VARA SAT desktop shortcut
		#			echo '[Desktop Entry]'                                                                 | sudo tee ${STARTMENU}/vara-sat.desktop > /dev/null
		#			echo 'Name=VARA SAT'                                                                   | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null
		#			echo 'GenericName=VARA SAT'                                                            | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null
		#			echo 'Comment=VARA SAT TNC emulated with Box86/Wine'                                   | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null
		#			echo 'Exec=env WINEDEBUG=-all wine '$HOME'/.wine/drive_c/VARA/VARASAT.exe'             | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null
		#			echo 'Type=Application'                                                                | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null
		#			echo 'StartupNotify=true'                                                              | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null
		#			echo 'Icon=29B6_VARASAT.0'                                                             | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null
		#			echo 'StartupWMClass=varasat.exe'                                                      | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null
		#			echo 'Categories=HamRadio'                                                             | sudo tee -a ${STARTMENU}/vara-sat.desktop > /dev/null

			# Download / extract / silently install VARA Chat
				# Search the rosmodem website for a VARA Chat mega.nz link of any version, then download it
					echo -e "\n${GREENTXT}Downloading VARA Chat . . .${NORMTXT}\n"
					VARACHATLINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA Chat v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
					megadl ${VARACHATLINK} --path=${VARAUPDATE} || { echo "VARA Chat download failed!" && run_giveup; }
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
			echo '        Send, !{s} ; Open view menu for user to turn off waterfall'              >> ${AHK}/varahf_configure.ahk
			echo '        Sleep 100'                                                               >> ${AHK}/varahf_configure.ahk
			echo '        Send, {Right}'                                                           >> ${AHK}/varahf_configure.ahk
			echo '        Sleep, 100'                                                              >> ${AHK}/varahf_configure.ahk
			echo '        Send, {Down}'                                                            >> ${AHK}/varahf_configure.ahk
			echo '        Sleep, 100'                                                              >> ${AHK}/varahf_configure.ahk
			echo '        Send, {Down}'                                                            >> ${AHK}/varahf_configure.ahk
			echo '        Sleep, 100'                                                              >> ${AHK}/varahf_configure.ahk
			echo '        Send, {Enter}'                                                           >> ${AHK}/varahf_configure.ahk
			echo '        Send, !{s} ; Open SoundCard menu for user to set up sound cards'         >> ${AHK}/varahf_configure.ahk
			echo '        Sleep 500'                                                               >> ${AHK}/varahf_configure.ahk
			echo '        Send, {Down}'                                                            >> ${AHK}/varahf_configure.ahk
			echo '        Sleep, 100'                                                              >> ${AHK}/varahf_configure.ahk
			echo '        Send, {Enter}'                                                           >> ${AHK}/varahf_configure.ahk
			echo '        Sleep 5000'                                                              >> ${AHK}/varahf_configure.ahk
			echo '        WinWaitClose, SoundCard ; Wait for user to finish setting up soundcard'  >> ${AHK}/varahf_configure.ahk
			echo '        Sleep 100'                                                               >> ${AHK}/varahf_configure.ahk
			echo '        WinClose, VARA HF ; Close VARA'                                          >> ${AHK}/varahf_configure.ahk
			BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine ${HOME}/winelink/ahk/AutoHotkey.exe ${AHK}/varahf_configure.ahk # nobanner option to make console prettier
			rm ${AHK}/varahf_configure.ahk
			sleep 5
		
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
			echo '        Send, !{s} ; Open view menu for user to turn off waterfall'              >> ${AHK}/varafm_configure.ahk
			echo '        Sleep 100'                                                               >> ${AHK}/varafm_configure.ahk
			echo '        Send, {Right}'                                                           >> ${AHK}/varafm_configure.ahk
			echo '        Sleep, 100'                                                              >> ${AHK}/varafm_configure.ahk
			echo '        Send, {Down}'                                                            >> ${AHK}/varafm_configure.ahk
			echo '        Sleep, 100'                                                              >> ${AHK}/varafm_configure.ahk
			echo '        Send, {Enter}'                                                           >> ${AHK}/varafm_configure.ahk
			echo '        Send, !{s} ; Open SoundCard menu for user to set up sound cards'         >> ${AHK}/varafm_configure.ahk
			echo '        Sleep 500'                                                               >> ${AHK}/varafm_configure.ahk
			echo '        Send, {Down}'                                                            >> ${AHK}/varafm_configure.ahk
			echo '        Sleep, 100'                                                              >> ${AHK}/varafm_configure.ahk
			echo '        Send, {Enter}'                                                           >> ${AHK}/varafm_configure.ahk
			echo '        Sleep 5000'                                                              >> ${AHK}/varafm_configure.ahk
			echo '        WinWaitClose, SoundCard ; Wait for user to finish setting up soundcard'  >> ${AHK}/varafm_configure.ahk
			echo '        Sleep 100'                                                               >> ${AHK}/varafm_configure.ahk
			echo '        WinClose, VARA FM ; Close VARA'                                          >> ${AHK}/varafm_configure.ahk
			BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine ${HOME}/winelink/ahk/AutoHotkey.exe ${AHK}/varafm_configure.ahk # Nobanner option to make console prettier
			rm ${AHK}/varafm_configure.ahk
			sleep 5
			
	#	# Guide the user to the VARA SAT audio setup menu (configure hardware soundcard input/output)
	#		clear
	#		echo -e "\n${GREENTXT}Configuring VARA SAT . . .${NORMTXT}\n"
	#		echo -e "\n${GREENTXT}Please set up your soundcard input/output for VARA SAT\n(please click 'Ok' on the user prompt textbox to continue)${NORMTXT}\n"
	#		zenity --info --height 100 --width 350 --text="We will now setup your soundcards for VARA SAT. \n\nInstall will continue once you have closed the VARA Settings menu." --title="VARA SAT Soundcard Setup"
	#		echo -e "\n${GREENTXT}Loading VARA SAT now . . .${NORMTXT}\n"
	#
	#	# Create/run varasat_configure.ahk
	#		# We will disable all graphics except gauges to help RPi4 CPU. Users can enable these if they have better CPU
	#		# We will then open the soundcard menu for users so that they can set up their sound cards
	#		# After the settings menu is closed, we will close VARA SAT
	#		echo '; AHK script to assist users in setting up VARA on its first run'                > ${AHK}/varasat_configure.ahk
	#		echo 'SetTitleMatchMode, 2'                                                            >> ${AHK}/varasat_configure.ahk
	#		echo 'SetTitleMatchMode, slow'                                                         >> ${AHK}/varasat_configure.ahk
	#		echo '        Run, VARASAT.exe, C:\VARA'                                               >> ${AHK}/varasat_configure.ahk
	#		echo '        WinActivate, VARA SAT'                                                   >> ${AHK}/varasat_configure.ahk
	#		echo '        WinWait, VARA SAT ; Wait for VARA HF to open'                            >> ${AHK}/varasat_configure.ahk
	#		echo '        Sleep 2500 ; If we dont wait at least 2000 for VARA then AHK wont work'  >> ${AHK}/varasat_configure.ahk
	#		echo '        Send, !{s} ; Open view menu for user to turn off waterfall'              >> ${AHK}/varasat_configure.ahk
	#		echo '        Sleep 100'                                                               >> ${AHK}/varasat_configure.ahk
	#		echo '        Send, {Right}'                                                           >> ${AHK}/varasat_configure.ahk
	#		echo '        Sleep, 100'                                                              >> ${AHK}/varasat_configure.ahk
	#		echo '        Send, {Right}'                                                           >> ${AHK}/varasat_configure.ahk
	#		echo '        Sleep, 100'                                                              >> ${AHK}/varasat_configure.ahk
	#		echo '        Send, {Down}'                                                            >> ${AHK}/varasat_configure.ahk
	#		echo '        Sleep, 100'                                                              >> ${AHK}/varasat_configure.ahk
	#		echo '        Send, {Down}'                                                            >> ${AHK}/varasat_configure.ahk
	#		echo '        Sleep, 100'                                                              >> ${AHK}/varasat_configure.ahk
	#		echo '        Send, {Down}'                                                            >> ${AHK}/varasat_configure.ahk
	#		echo '        Sleep, 100'                                                              >> ${AHK}/varasat_configure.ahk
	#		echo '        Send, {Enter}'                                                           >> ${AHK}/varasat_configure.ahk
	#		echo '        Send, !{s} ; Open SoundCard menu for user to set up sound cards'         >> ${AHK}/varasat_configure.ahk
	#		echo '        Sleep 500'                                                               >> ${AHK}/varasat_configure.ahk
	#		echo '        Send, {Down}'                                                            >> ${AHK}/varasat_configure.ahk
	#		echo '        Sleep, 100'                                                              >> ${AHK}/varasat_configure.ahk
	#		echo '        Send, {Enter}'                                                           >> ${AHK}/varasat_configure.ahk
	#		echo '        Sleep 5000'                                                              >> ${AHK}/varasat_configure.ahk
	#		echo '        WinWaitClose, SoundCard ; Wait for user to finish setting up soundcard'  >> ${AHK}/varasat_configure.ahk
	#		echo '        Sleep 100'                                                               >> ${AHK}/varasat_configure.ahk
	#		echo '        WinClose, VARA SAT ; Close VARA'                                         >> ${AHK}/varasat_configure.ahk
	#		BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine ${HOME}/winelink/ahk/AutoHotkey.exe ${AHK}/varasat_configure.ahk # nobanner option to make console prettier
	#		rm ${AHK}/varasat_configure.ahk
	#		sleep 5
		
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
        echo '#!/bin/bash'                                                                                         > ${HOME}/winelink/Reset\ Wine
        echo ''                                                                                                    >> ${HOME}/winelink/Reset\ Wine
	echo '# Turn off the waterfalls for VARA HF/FM/Sat (change 'View=1' to 'View=3' in their VARA.ini files).' >> ${HOME}/winelink/Reset\ Wine
	echo '# (INI files show up after first run of each VARA program)'                                          >> ${HOME}/winelink/Reset\ Wine
	echo 'sed -i 's+View\=1+View\=3+g' ~/.wine/drive_c/VARA/VARA.ini'                                          >> ${HOME}/winelink/Reset\ Wine
	echo 'sed -i 's+WaterFall\=1+WaterFall\=0+g' ~/.wine/drive_c/VARA/VARA.ini'                                >> ${HOME}/winelink/Reset\ Wine
	echo 'sed -i 's+View\=1+View\=3+g' ~/.wine/drive_c/VARA/VARASAT.ini'                                       >> ${HOME}/winelink/Reset\ Wine
	echo 'sed -i 's+WaterFall\=1+WaterFall\=0+g' ~/.wine/drive_c/VARA/VARASAT.ini'                             >> ${HOME}/winelink/Reset\ Wine
	echo 'sed -i 's+View\=1+View\=3+g' ~/.wine/drive_c/VARA\ FM/VARAFM.ini'                                    >> ${HOME}/winelink/Reset\ Wine
	echo ''                                                                                                    >> ${HOME}/winelink/Reset\ Wine
        echo 'wineserver -k'                                                                                       >> ${HOME}/winelink/Reset\ Wine
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
				${STARTMENU}/vara-update.desktop ${STARTMENU}/resetwine.desktop ${STARTMENU}/VarAC.desktop 2>/dev/null # remove old shortcuts
			sudo rm -rf ${HOME}/winelink 2>/dev/null
			rm ${HOME}/RMS\ Express\ *.log 2>/dev/null # silently remove old RMS Express logs
			rm ${HOME}/VarAC.ini ${HOME}/VarAC_cat_commands.ini ${HOME}/VarAC_frequencies.conf ${HOME}/VarAC_frequency_schedule.conf ${HOME}/VarAC_alert_tags.conf

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

function run_detect_os()
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
    if [ -e /etc/os-release ];       then OS_INFOFILE='/etc/os-release'     #&& echo "Found an OS info file located at ${OS_INFOFILE}"
    elif [ -e /usr/lib/os-release ]; then OS_INFOFILE='/usr/lib/os-release' #&& echo "Found an OS info file located at ${OS_INFOFILE}"
    elif [ -e /etc/*elease ];        then OS_INFOFILE='/etc/*elease'        #&& echo "Found an OS info file located at ${OS_INFOFILE}"
    # Add mac OS  https://apple.stackexchange.com/questions/255546/how-to-find-file-release-in-os-x-el-capitan-10-11-6
    # Add chrome OS
    # Add chroot Android? (uname -o  can be used to find "Android")
    else OS_INFOFILE='' && echo "No Linux OS info files could be found!">&2 && run_giveup;
    fi
    
    # Load OS-Release File vars into memory (reads vars like "NAME", "ID", "VERSION_ID", "PRETTY_NAME", and "HOME_URL")
    source "${OS_INFOFILE}"
    
    # TODO: Add Termux detection
}

function run_detect_rpi()  # Learn about our user's RPi hardware configuration by reading the revision number stored in '/proc/cpuinfo'
{
	# If we are not running a Raspberry Pi, don't try to parse the model number.
		if ! grep -q Raspberry "/proc/device-tree/model"; then
			echo "This is not a Raspberry Pi."
			return 1 # leave this function
			# https://gist.github.com/jperkin/c37a574379ef71e339361954be96be12#raspberry-pi-cpuinfo-vs-device-tree
		fi
	
	# Get revision number
		#local HEXREVISION="$1" # uncomment this (and comment-out the line below this) if you want to pass revision numbers to this script instead of auto-detecting
		local HEXREVISION=$(cat /proc/cpuinfo | grep Revision | cut -d ' ' -f 2) # Get revision number from cpuinfo (revision number is in hex)
	
	# Convert revision number into a 32 bit binary string with leading zero's (name it "REVCODE")
		local BINREVISION=$(echo "obase=2; ibase=16; ${HEXREVISION^^}" | bc) # Convert revision number from hex to binary (bc needs upper-case)
		local COUNTBITS=${#BINREVISION}
		if (( "$COUNTBITS" < "32" )); then # If the revision number is not 32 bits long, add leading zero's to it - Note: $(printf "%032d\n" $BINREVISION) doesn't work with large numbers
			local ZEROSNEEDED=$((32-COUNTBITS))
			local LEADINGZEROS=$(printf "%0${ZEROSNEEDED}d\n" 0)
			local REVCODE=${LEADINGZEROS}${BINREVISION}
		elif (( "$COUNTBITS" == "32" )); then
			REVCODE=${BINREVISION}
		else
			echo "Something went wrong with calculating the Pi's revision number."
			run_giveup
		fi
	
	# Parse $REVCODE (find substrings, determine new-format vs old-format, decipher/store info in variables, print info for the user).
		# Now that REVCODE is readable in binary, create hexadecimal substrings from it.
		#       New-style revision codes: NOQuuuWwFMMMCCCCPPPPTTTTTTTTRRRR
		#         - https://www.raspberrypi.com/documentation/computers/raspberry-pi.html
		#         - https://github.com/raspberrypi/documentation/blob/develop/documentation/asciidoc/computers/raspberry-pi/revision-codes.adoc
		#       If a is constant, b=${a:12:5} does substring extraction where 12 is the offset (zero-based) and 5 is the length.
		#         - https://stackoverflow.com/questions/428109/extract-substring-in-bash
		local N=${REVCODE:0:1}                                           # Overvoltage (0: Overvoltage allowed, 1: Overvoltage disallowed)
		local O=${REVCODE:1:1}                                           # OTP Program (0: OTP programming allowed, 1: OTP programming disallowed)
		local Q=${REVCODE:2:1}                                           # OTP Read (0: OTP reading allowed, 1: OTP reading disallowed)
		#local uuu=$(echo "obase=16; ibase=2; ${REVCODE:3:3}" | bc)      # Unused bits
		local W=${REVCODE:6:1}                                           # Warranty bit [starting with RPi2/Zero] (0: Warranty is intact, 1: Warranty has been voided by overclocking)
		local w=${REVCODE:7:1}                                           # Unused bit [starting with RPi2/Zero] / warranty bit [prior to RPi2/Zero]
		local F=${REVCODE:8:1}                                           # New flag (1: new-style revision, 0: old-style revision)
		local MMM=$(echo "obase=16; ibase=2; ${REVCODE:9:3}" | bc)       # Memory size (0: 256MB, 1: 512MB, 2: 1GB, 3: 2GB, 4: 4GB, 5: 8GB)
		local CCCC=$(echo "obase=16; ibase=2; ${REVCODE:12:4}" | bc)     # Manufacturer (0: Sony UK, 1: Egoman, 2: Embest, 3: Sony Japan, 4: Embest, 5: Stadium)
		local PPPP=$(echo "obase=16; ibase=2; ${REVCODE:16:4}" | bc)     # Processor (0: BCM2835, 1: BCM2836, 2: BCM2837, 3: BCM2711)
		local TTTTTTTT=$(echo "obase=16; ibase=2; ${REVCODE:20:8}" | bc) # Type (0: A, 1: B, 2: A+, 3: B+, 4: 2B, 5: Alpha (early prototype), 6: CM1, 8: 3B, 
		                                                                 #       9: Zero, A: CM3, C: Zero W, D: 3B+, E: 3A+, F: Internal use only, 10: CM3+, 
		                                                                 #       11: 4B, 12: Zero 2 W, 13: 400, 14: CM4)
		local RRRR=$(echo "obase=16; ibase=2; ${REVCODE:28:4}" | bc)     # Revision (0, 1, 2, etc.)
		
		# Zero-out our variables in case this function runs twice (this step might be redundant)
		PI_OVERVOLTAGE=""
		PI_OTPPROGRAM=""
		PI_OTPREAD=""
		PI_WARRANTY=""
		PI_RAM=""
		PI_MANUFACTURER=""
		PI_PROCESSOR=""
		PI_TYPE=""
		PI_REVISION=""
		
		if [ "$F" = "0" ]; then
			# Old-style revision codes [Leading 0x100 = warranty is void from overclocking (the "w" binary bit is set)]:
			case $HEXREVISION in
				"0002" | "1000002")
					PI_TYPE="1B"
					PI_REVISION="1.0"
					PI_RAM="256MB"
					PI_MANUFACTURER="Egoman"
					;;
				"0003" | "1000003")
					PI_TYPE="1B"
					PI_REVISION="1.0"
					PI_RAM="256MB"
					PI_MANUFACTURER="Egoman"
					;;
				"0004" | "1000004")
					PI_TYPE="1B"
					PI_REVISION="2.0"
					PI_RAM="256MB"
					PI_MANUFACTURER="Sony UK"
					;;
				"0005" | "1000005")
					PI_TYPE="1B"
					PI_REVISION="2.0"
					PI_RAM="256MB"
					PI_MANUFACTURER="Qisda"
					;;
				"0006" | "1000006")
					PI_TYPE="1B"
					PI_REVISION="2.0"
					PI_RAM="256MB"
					PI_MANUFACTURER="Egoman"
					;;
				"0007" | "1000007")
					PI_TYPE="1A"
					PI_REVISION="2.0"
					PI_RAM="256MB"
					PI_MANUFACTURER="Egoman"
					;;
				"0008" | "1000008")
					PI_TYPE="1A"
					PI_REVISION="2.0"
					PI_RAM="256MB"
					PI_MANUFACTURER="Sony UK"
					;;
				"0009" | "1000009")
					PI_TYPE="1A"
					PI_REVISION="2.0"
					PI_RAM="256MB"
					PI_MANUFACTURER="Qisda"
					;;
				"000d" | "100000d")
					PI_TYPE="1B"
					PI_REVISION="2.0"
					PI_RAM="512MB"
					PI_MANUFACTURER="Egoman"
					;;
				"000e" | "100000e")
					PI_TYPE="1B"
					PI_REVISION="2.0"
					PI_RAM="512MB"
					PI_MANUFACTURER="Sony UK"
					;;
				"000f" | "100000f")
					PI_TYPE="1B"
					PI_REVISION="2.0"
					PI_RAM="512MB"
					PI_MANUFACTURER="Egoman"
					;;
				"0010" | "1000010")
					PI_TYPE="1B+"
					PI_REVISION="1.2"
					PI_RAM="512MB"
					PI_MANUFACTURER="Sony UK"
					;;
				"0011" | "1000011")
					PI_TYPE="CM1"
					PI_REVISION="1.0"
					PI_RAM="512MB"
					PI_MANUFACTURER="Sony UK"
					;;
				"0012" | "1000012")
					PI_TYPE="1A+"
					PI_REVISION="1.1"
					PI_RAM="256MB"
					PI_MANUFACTURER="Sony UK"
					;;
				"0013" | "1000013")
					PI_TYPE="1B+"
					PI_REVISION="1.2"
					PI_RAM="512MB"
					PI_MANUFACTURER="Embest"
					;;
				"0014" | "1000014")
					PI_TYPE="CM1"
					PI_REVISION="1.0"
					PI_RAM="512MB"
					PI_MANUFACTURER="Embest"
					;;
				"0015" | "1000015")
					PI_TYPE="1A+"
					PI_REVISION="1.1"
					PI_RAM="256MB/512MB"
					PI_MANUFACTURER="Embest"
					;;
				*)
					PI_TYPE="UNKNOWN"
					PI_REVISION="UNKNOWN"
					PI_RAM="UNKNOWN"
					PI_MANUFACTURER="UNKNOWN"
					echo "ERROR: Unable to parse Raspberry Pi old-style revision code"
					run_giveup
					;;
			esac
			
			case $w in
				"0")
					PI_WARRANTY="intact"
					;;
				"1")
					PI_WARRANTY="voided by overclocking"
					;;
				*)
					PI_WARRANTY="UNKNOWN"
					echo "ERROR: Unable to parse Raspberry Pi old-style overclock/warranty code."
					run_giveup
					;;
			esac
			
			echo -e "\nRaspberry Pi Model ${PI_TYPE} Rev ${PI_REVISION} with ${PI_RAM} of RAM. Manufactured by ${PI_MANUFACTURER}."
			echo "(Warranty ${PI_WARRANTY})"
			
		elif [ "$F" = "1" ]; then
			# New-style revision codes:
			case $N in
				"0")
					PI_OVERVOLTAGE="allowed"
					;;
				"1")
					PI_OVERVOLTAGE="disallowed"
					;;
				*)
					PI_OVERVOLTAGE="UNKNOWN"
					echo "ERROR: Unable to parse Raspberry Pi overvoltage allowance bit."
					run_giveup
					;;
			esac
			
			case $O in
				"0")
					PI_OTPPROGRAM="allowed"
					;;
				"1")
					PI_OTPPROGRAM="disallowed"
					;;
				*)
					PI_OTPPROGRAM="UNKNOWN"
					echo "ERROR: Unable to parse Raspberry Pi OTP programming allowance bit."
					run_giveup
					;;
			esac
			
			case $Q in
				"0")
					PI_OTPREAD="allowed"
					;;
				"1")
					PI_OTPREAD="disallowed"
					;;
				*)
					PI_OTPREAD="UNKNOWN"
					echo "ERROR: Unable to parse Raspberry Pi OTP reading allowance bit."
					run_giveup
					;;
			esac
			
			case $W in
				"0")
					PI_WARRANTY="intact"
					;;
				"1")
					PI_WARRANTY="voided by overclocking"
					;;
				*)
					PI_WARRANTY="UNKNOWN"
					echo "ERROR: Unable to parse Raspberry Pi new-style overclock/warranty code."
					run_giveup
					;;
			esac
			
			case $MMM in
				"0")
					PI_RAM="256MB"
					;;
				"1")
					PI_RAM="512MB"
					;;
				"2")
					PI_RAM="1GB"
					;;
				"3")
					PI_RAM="2GB"
					;;
				"4")
					PI_RAM="4GB"
					;;
				"5")
					PI_RAM="8GB"
					;;
				*)
					PI_RAM="UNKNOWN"
					echo "ERROR: Unable to parse Raspberry Pi RAM type code."
					run_giveup
					;;
			esac
			
			case $CCCC in
				"0")
					PI_MANUFACTURER="Sony UK"
					;;
				"1")
					PI_MANUFACTURER="Egoman"
					;;
				"2")
					PI_MANUFACTURER="Embest"
					;;
				"3")
					PI_MANUFACTURER="Sony Japan"
					;;
				"4")
					PI_MANUFACTURER="Embest"
					;;
				"5")
					PI_MANUFACTURER="Stadium"
					;;
				*)
					PI_MANUFACTURER="UNKNOWN"
					echo "ERROR: Unable to parse Raspberry Pi manufacturer code."
					run_giveup
					;;
			esac
			
			case $PPPP in
				"0")
					PI_PROCESSOR="BCM2835"
					;;
				"1")
					PI_PROCESSOR="BCM2836"
					;;
				"2")
					PI_PROCESSOR="BCM2837"
					;;
				"3")
					PI_PROCESSOR="BCM2711"
					;;
				*)
					PI_PROCESSOR="UNKNOWN"
					echo "ERROR: Unable to parse Raspberry Pi processor type code."
					run_giveup
					;;
			esac
			
			case $TTTTTTTT in
				"0")
					PI_TYPE="1A"
					;;
				"1")
					PI_TYPE="1B"
					;;
				"2")
					PI_TYPE="1A+"
					;;
				"3")
					PI_TYPE="1B+"
					;;
				"4")
					PI_TYPE="2B"
					;;
				"5")
					PI_TYPE="Alpha (early prototype)"
					;;
				"6")
					PI_TYPE="CM1"
					;;
				"8")
					PI_TYPE="3B"
					;;
				"9")
					PI_TYPE="Zero"
					;;
				"A")
					PI_TYPE="CM3"
					;;
				"C")
					PI_TYPE="Zero W"
					;;
				"D")
					PI_TYPE="3B+"
					;;
				"E")
					PI_TYPE="3A+"
					;;
				"F")
					PI_TYPE="Internal use only"
					;;
				"10")
					PI_TYPE="CM3+"
					;;
				"11")
					PI_TYPE="4B"
					;;
				"12")
					PI_TYPE="Zero 2 W"
					;;
				"13")
					PI_TYPE="400"
					;;
				"14")
					PI_TYPE="CM4"
					;;
				*)
					PI_TYPE="UNKNOWN"
					echo "ERROR: Unable to parse Raspberry Pi model code."
					run_giveup
					;;
			esac
			
			PI_REVISION="1.${RRRR}"
			
			echo -e "\nRaspberry Pi Model ${PI_TYPE} Rev ${PI_REVISION} ${PI_PROCESSOR} with ${PI_RAM} of RAM. Manufactured by ${PI_MANUFACTURER}."
			echo "(Overvoltage ${PI_OVERVOLTAGE}. OTP programming ${PI_OTPPROGRAM}. OTP reading ${PI_OTPREAD}. Warranty ${PI_WARRANTY})"
		else
			echo "ERROR: Could not read the Raspberry Pi's revision code version bit."
			run_giveup
		fi
		
	# Categorize the Pi into a series (based on the $PI_TYPE variable)
		if [ "$PI_TYPE" = "4B" ] || [ "$PI_TYPE" = "400" ] || [ "$PI_TYPE" = "CM4" ]; then
			SBC_SERIES=RPi4
		elif [ "$PI_TYPE" = "3A+" ] || [  "$PI_TYPE" = "3B+" ] || [  "$PI_TYPE" = "CM3+" ]; then
			SBC_SERIES=RPi3+
		elif [ "$PI_TYPE" = "Zero 2 W" ]; then
			SBC_SERIES=RPiZ2
		elif [ "$PI_TYPE" = "3B" ] || [  "$PI_TYPE" = "CM3" ]; then
			SBC_SERIES=RPi3
		elif [ "$PI_TYPE" = "Zero" ] || [ "$PI_TYPE" = "Zero W" ]; then
			SBC_SERIES=RPiZ1
		elif [ "$PI_TYPE" = "2B" ]; then
			SBC_SERIES=RPi2
		elif [ "$PI_TYPE" = "1A+" ] || [ "$PI_TYPE" = "1B+" ]; then
			SBC_SERIES=RPi1+
		elif [ "$PI_TYPE" = "1A" ] || [ "$PI_TYPE" = "1B" ] || [ "$PI_TYPE" = "CM1" ]; then
			SBC_SERIES=RPi1
		elif [ "$PI_TYPE" = "Internal use only" ] || [ "$PI_TYPE" = "Alpha (early prototype)" ]; then
			SBC_SERIES=X
		else
			echo "Error: Could not identify Pi series.">&2
			run_giveup
		fi
		echo -e "\nThis Pi is part of the ${SBC_SERIES} series."
}

function run_detect_othersbc()
{
	local model=$(tr -d '\0' </proc/device-tree/model)
	# source: https://stackoverflow.com/questions/46163678/get-rid-of-warning-command-substitution-ignored-null-byte-in-input

	# Categorize the SBC into a series
	if [ "$model" = "OrangePi 4 LTS" ] || [ "$model" = "OrangePi 4" ]; then
		SBC_SERIES=OrangePi4
	fi
	echo -e "\nThis SBC is part of the ${SBC_SERIES} series."
}

function run_giveup()  # If our script failed at any critical stages, notify the user and quit
{
    echo ""
    echo "Winelink installation failed."
    echo ""
    echo -e "If a download failed, please check your internet connection and try re-running \nthe script."
    echo "For help, please reference the '${HOME}/winelink\winelink.log' file"
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
