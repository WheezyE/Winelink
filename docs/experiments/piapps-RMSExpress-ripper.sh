#!/bin/bash

#Credits: KI7POL
#For the wine-mono dvoa.dll stability hack which was encorporated into RMS Express 12/2024: Shout out to Bent (LA9RT), Alex (VE3NEA), Esme (madewokherd), Kate (KD2ROS), and Eric (KI7POL)!

version=1-7-15-0
APPDIR=$HOME/.local/share/applications

#Installing wine
if [ $arch == 32 ];then
  "$DIRECTORY/manage" install-if-not-installed 'Wine (x86)' || error 'Failed to install wine'
elif [ $arch == 64 ];then
  "$DIRECTORY/manage" install-if-not-installed 'Wine (x64)' || error 'Failed to install wine'
fi

#Configuring wineprefix for RMS Express programs
BOX86_DYNAREC=0 BOX64_DYNAREC=0 BOX86_NOBANNER=1 BOX64_NOBANNER=1 winetricks -q mdx sound=alsa

#Ensuring wine-mono is installed (wine-mono runs & installs faster than .NET 4.6)
if [ -d "$HOME/.wine/drive_c/windows/Microsoft.NET/Framework/v4.0.30319" ]
then
    : # wine-mono or .NET 4.x have already been installed. Do nothing.
else
  echo "\nwine-mono or .NET 4.x do not appear to be installed. Running wine-mono installation.\n"
	mkdir ~/.cache/wine 2>/dev/null
	echo -e "\nDownloading and installing wine-mono . . .\n"
 	#wget -P ~/.cache/wine https://dl.winehq.org/wine/wine-mono/9.0.0/wine-mono-9.0.0-x86.msi
 	wget -P ~/.cache/wine https://dl.winehq.org/wine/wine-mono/9.1.0/wine-mono-9.1.0-x86.msi  || error 'wine-mono .msi install file download failed!'
	#wget -q -P ~/.cache/wine https://dl.winehq.org/wine/wine-mono/7.2.0/wine-mono-7.2.0-x86.msi  || error 'wine-mono .msi install file download failed!'
	wine msiexec /i ~/.cache/wine/wine-mono-9.1.0-x86.msi # install wine-mono
	rm -rf ~/.cache/wine # clean up to save disk space
 	wineboot -e && wineboot -f && wineserver -k # try to free up Wine's RAM(?) in wine (try to prevent freezes on Raspberry Pi)
fi

#Installing InnoExtract
sudo apt install innoextract -y || error 'Failed to install innoextract from apt. RMS Express program files cannot be installed.'

#Add the user to the USB dialout group so that they can access radio USB CAT control later
sudo usermod -a -G dialout $USER

#Downloading RMS Express from winlink.org
wget -q -r -l1 -np -nd -A "Winlink_Express_install*.zip" "https://downloads.winlink.org/User%20Programs/" -P /tmp/ || error 'RMS Express download failed!'
#Extracting RMS Express installer archives
unzip -o /tmp/Winlink_Express_install*.zip -d "/tmp" || error 'Failed to unzip RMS Express archive'
mkdir -p $APPDIR
#Copying program files to the Linux local app directory
innoextract /tmp/Winlink_Express_install.exe -d $APPDIR/RMS\ Express || error 'Failed to unpack RMS Express innosetup'
mv $APPDIR/RMS\ Express/app/* $APPDIR/RMS\ Express/ && rm -rf $APPDIR/RMS\ Express/app/ # organize the directory a little bit
#Removing RMS Express installer archives
rm /tmp/Winlink_Express_install*.zip
rm /tmp/Winlink_Express_install.exe
#Creating symlink to Linux local app directory within wine
ln -sf $HOME/.local/share/applications/RMS\ Express $HOME/.wine/drive_c/RMS\ Express

#Creating Desktop Entry
# notes: BOX64_DYNAREC_BIGBLOCK=0 (box86 default for .NET programs), BOX64_DYNAREC_SAFEFLAGS=2 (box86 default for vara.exe), other envvars found empirically ( also see https://github.com/ptitSeb/box64/blob/main/docs/USAGE.md ).
echo "[Desktop Entry]
Name=RMS Express
Comment=RMS Express is a freeware ham radio software modem messaging suite which leverages the Winlink Global Radio Messaging service.
Exec=env BOX64_DYNAREC_SAFEFLAGS=2 BOX64_DYNAREC_STRONGMEM=2 BOX64_DYNAREC_CALLRET=1 wine $APPDIR/RMS\ Express/RMS\ Express.exe
Icon=$(dirname "$0")/icon-64.png
Terminal=false
StartupNotify=true
Type=Application
Categories=Utility;" > $APPDIR/rmsexpress.desktop || error 'Failed to create menu button!'

exit

function uninstallRMSExpress()
{
    APPDIR=$HOME/.local/share/applications
    #Unregistering OCX/DLL files with your wineprefix
    BOX86_NOBANNER=1 BOX64_NOBANNER=1 WINEDEBUG=-all wine regsvr32 $APPDIR/VARA\ HF/OCX/* /u /s
    #Removing program files
    rm -rf $APPDIR/VARA\ HF/
    unlink $HOME/.wine/drive_c/VARA\ HF
    #Removing Desktop Entry
    rm $APPDIR/varahf.desktop
}


function run_installrmsexpress()  # Download/extract/install RMS Express
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
            WINEDEBUG=-all wine WinlinkExpressInstaller/Winlink_Express_install.exe /SILENT
	    
	# Clean up
            rm -rf WinlinkExpressInstaller
	    sleep 3; sudo rm -rf ~/.local/share/applications/wine/Programs/RMS\ Express/ # Remove wine's auto-generated program icon from the start menu
            
        # Make an RMS Express desktop shortcut
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

function run_installrmsterminal()
{
    mkdir downloads 2>/dev/null; cd downloads
        # Download RMS Terminal (no matter its version number) [https://downloads.winlink.org/Sysop%20Programs/]
            echo -e "\n${GREENTXT}Downloading and installing RMS Simple Terminal . . .${NORMTXT}\n"
            wget -q -r -l1 -np -nd -A "RMS_Simple_Terminal_install_*.zip" https://downloads.winlink.org/Sysop%20Programs || { echo "RMS Simple Terminal download failed!" && run_giveup; }

        # Extract/install RMS Terminal
            7z x RMS_Simple_Terminal_install_*.zip -o"RMSTerminalInstaller" -y -bsp0 -bso0
            BOX86_DYNAREC=0 WINEDEBUG=-all wine msiexec /i RMSTerminalInstaller/RMS\ Simple\ Terminal\ Setup.msi /quiet

	# Clean up
            rm -rf RMSTerminalInstaller
	    #sleep 3; sudo rm -rf ~/.local/share/applications/wine/Programs/RMS\ Simple\ Terminal/ # Remove wine's auto-generated program icon from the start menu

        # Make an RMS Simple Terminal desktop shortcut
            echo '[Desktop Entry]'                                                                                               | sudo tee ${STARTMENU}/rmssimpleterminal.desktop > /dev/null
            echo 'Name=RMS Simple Terminal'                                                                                      | sudo tee -a ${STARTMENU}/rmssimpleterminal.desktop > /dev/null
            echo 'GenericName=RMS Simple Terminal'                                                                               | sudo tee -a ${STARTMENU}/rmssimpleterminal.desktop > /dev/null
            echo 'Comment=RMS Simple Terminal emulated with Box86/Wine'                                                          | sudo tee -a ${STARTMENU}/rmssimpleterminal.desktop > /dev/null
            echo 'Exec=env BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine '$HOME'/.wine/drive_c/RMS/RMS\ Simple\ Terminal/RMS\ Simple\ Terminal.exe' | sudo tee -a ${STARTMENU}/rmssimpleterminal.desktop > /dev/null
            echo 'Type=Application'                                                                                              | sudo tee -a ${STARTMENU}/rmssimpleterminal.desktop > /dev/null
            echo 'StartupNotify=true'                                                                                            | sudo tee -a ${STARTMENU}/rmssimpleterminal.desktop > /dev/null
            #echo 'Icon=none.0'                                                                                                   | sudo tee -a ${STARTMENU}/rmssimpleterminal.desktop > /dev/null
            echo 'StartupWMClass=rms simple terminal.exe'                                                                        | sudo tee -a ${STARTMENU}/rmssimpleterminal.desktop > /dev/null
            echo 'Categories=HamRadio;'                                                                                          | sudo tee -a ${STARTMENU}/rmssimpleterminal.desktop > /dev/null
    cd ..
}

function run_installrmstrimode()  # Download/extract/install RMS Express
{
    mkdir downloads 2>/dev/null; cd downloads
        # Download RMS Trimode (no matter its version number) [https://downloads.winlink.org/Sysop%20Programs/]
            echo -e "\n${GREENTXT}Downloading and installing RMS Trimode . . .${NORMTXT}\n"
            wget -q -r -l1 -np -nd -A "RMS_Trimode_install_*.zip" https://downloads.winlink.org/Sysop%20Programs || { echo "RMS Trimode download failed!" && run_giveup; }

        # We could also use curl if we don't want to use wget to find the link . . .
            #RMSTRILINKPREFIX="https://downloads.winlink.org"
            #RMSTRILINKSUFFIX=$(curl -s https://downloads.winlink.org/User%20Programs/ | grep -oP '(?=/Sysop%20Programs/RMS_Trimode_install_).*?(\.zip).*(?=">RMS_Trimode_install_)')
            #RMSTRILINK=$RMSTRILINKPREFIX$RMSTRILINKSUFFIX
            #wget -q $RMSTRILINK || { echo "RMS Trimode download failed!" && run_giveup; }

        # Extract/install RMS Trimode
            7z x RMS_Trimode_install_*.zip -o"RMSTrimodeInstaller" -y -bsp0 -bso0
            WINEDEBUG=-all wine RMSTrimodeInstaller/RMS_Trimode_install.exe /SILENT

	# Clean up
            rm -rf RMSTrimodeInstaller
	    sleep 3; sudo rm -rf ~/.local/share/applications/wine/Programs/RMS\ Trimode/ # Remove wine's auto-generated program icon from the start menu

        # Make an RMS Trimode desktop shortcut
            echo '[Desktop Entry]'                                                                                               | sudo tee ${STARTMENU}/rmstrimode.desktop > /dev/null
            echo 'Name=RMS Trimode'                                                                                              | sudo tee -a ${STARTMENU}/rmstrimode.desktop > /dev/null
            echo 'GenericName=RMS Trimode'                                                                                       | sudo tee -a ${STARTMENU}/rmstrimode.desktop > /dev/null
            echo 'Comment=RMS Trimode emulated with Box86/Wine'                                                                  | sudo tee -a ${STARTMENU}/rmstrimode.desktop > /dev/null
            echo 'Exec=env BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine '$HOME'/.wine/drive_c/RMS/RMS\ Trimode/RMS\ Trimode.exe' | sudo tee -a ${STARTMENU}/rmstrimode.desktop > /dev/null
            echo 'Type=Application'                                                                                              | sudo tee -a ${STARTMENU}/rmstrimode.desktop > /dev/null
            echo 'StartupNotify=true'                                                                                            | sudo tee -a ${STARTMENU}/rmstrimode.desktop > /dev/null
            echo 'Icon=C4A8_RMS Trimode.0'                                                                                       | sudo tee -a ${STARTMENU}/rmstrimode.desktop > /dev/null
            echo 'StartupWMClass=rms trimode.exe'                                                                                | sudo tee -a ${STARTMENU}/rmstrimode.desktop > /dev/null
            echo 'Categories=HamRadio;'                                                                                          | sudo tee -a ${STARTMENU}/rmstrimode.desktop > /dev/null
    cd ..
}

function run_installrmsadifanalyzer()
{
    mkdir downloads 2>/dev/null; cd downloads
        # Download RMS ADIF Analyzer (no matter its version number) [https://downloads.winlink.org/Sysop%20Programs/]
            echo -e "\n${GREENTXT}Downloading and installing ADIF Analyzer (companion app for RMS Trimode) . . .${NORMTXT}\n"
            wget -q -r -l1 -np -nd -A "ADIF_Analyzer_install_*.zip" https://downloads.winlink.org/Sysop%20Programs || { echo "RMS ADIF Analyzer download failed!" && run_giveup; }

        # Extract/install RMS ADIF Analyzer
            7z x ADIF_Analyzer_install_*.zip -o"RMSADIFInstaller" -y -bsp0 -bso0
            BOX86_DYNAREC=0 WINEDEBUG=-all wine RMSADIFInstaller/ADIF_Analyzer_install.exe /SILENT
	    #TODO: Extract .ico from exe, convert to .png, and save as .0 in ${HOME}/.local/share/icons/hicolor/48x48/apps/

	# Clean up
            rm -rf RMSADIFInstaller
	    sleep 3; sudo rm -rf ~/.local/share/applications/wine/Programs/ADIF\ Analyzer/ # Remove wine's auto-generated program icon from the start menu

        # Make an RMS ADIF Analyzer desktop shortcut
            echo '[Desktop Entry]'                                                                                               | sudo tee ${STARTMENU}/rmsadifanalyzer.desktop > /dev/null
            echo 'Name=RMS ADIF Analyzer'                                                                                        | sudo tee -a ${STARTMENU}/rmsadifanalyzer.desktop > /dev/null
            echo 'GenericName=RMS ADIF Analyzer'                                                                                 | sudo tee -a ${STARTMENU}/rmsadifanalyzer.desktop > /dev/null
            echo 'Comment=ADIF Analyzer emulated with Box86/Wine'                                                                | sudo tee -a ${STARTMENU}/rmsadifanalyzer.desktop > /dev/null
            echo 'Exec=env BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine '$HOME'/.wine/drive_c/RMS/ADIF\ Analyzer/ADIF\ Analyzer.exe' | sudo tee -a ${STARTMENU}/rmsadifanalyzer.desktop > /dev/null
            echo 'Type=Application'                                                                                              | sudo tee -a ${STARTMENU}/rmsadifanalyzer.desktop > /dev/null
            echo 'StartupNotify=true'                                                                                            | sudo tee -a ${STARTMENU}/rmsadifanalyzer.desktop > /dev/null
            echo 'Icon=2BD9_ADIF Analyzer.0'                                                                                     | sudo tee -a ${STARTMENU}/rmsadifanalyzer.desktop > /dev/null
            echo 'StartupWMClass=adif analyzer.exe'                                                                              | sudo tee -a ${STARTMENU}/rmsadifanalyzer.desktop > /dev/null
            echo 'Categories=HamRadio;'                                                                                          | sudo tee -a ${STARTMENU}/rmsadifanalyzer.desktop > /dev/null
    cd ..
}

function run_installrmspacket()
{
    mkdir downloads 2>/dev/null; cd downloads
        # Download RMS Packet (no matter its version number) [https://downloads.winlink.org/Sysop%20Programs/]
            echo -e "\n${GREENTXT}Downloading and installing RMS Packet . . .${NORMTXT}\n"
            wget -q -r -l1 -np -nd -A "RMS_Packet_install_*.zip" https://downloads.winlink.org/Sysop%20Programs || { echo "RMS Packet download failed!" && run_giveup; }

        # Extract/install RMS Packet
            7z x RMS_Packet_install_*.zip -o"RMSPacketInstaller" -y -bsp0 -bso0
            BOX86_DYNAREC=0 WINEDEBUG=-all wine RMSPacketInstaller/RMS_Packet_install.exe /SILENT

	# Clean up
            rm -rf RMSPacketInstaller
	    sleep 3; sudo rm -rf ~/.local/share/applications/wine/Programs/RMS\ Packet/ # Remove wine's auto-generated program icon from the start menu

        # Make an RMS Packet desktop shortcut
            echo '[Desktop Entry]'                                                                                             | sudo tee ${STARTMENU}/rmspacket.desktop > /dev/null
            echo 'Name=RMS Packet'                                                                                             | sudo tee -a ${STARTMENU}/rmspacket.desktop > /dev/null
            echo 'GenericName=RMS Packet'                                                                                      | sudo tee -a ${STARTMENU}/rmspacket.desktop > /dev/null
            echo 'Comment=RMS Packet emulated with Box86/Wine'                                                                 | sudo tee -a ${STARTMENU}/rmspacket.desktop > /dev/null
            echo 'Exec=env BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine '$HOME'/.wine/drive_c/RMS/RMS\ Packet/RMS\ Packet.exe' | sudo tee -a ${STARTMENU}/rmspacket.desktop > /dev/null
            echo 'Type=Application'                                                                                            | sudo tee -a ${STARTMENU}/rmspacket.desktop > /dev/null
            echo 'StartupNotify=true'                                                                                          | sudo tee -a ${STARTMENU}/rmspacket.desktop > /dev/null
            echo 'Icon=3563_RMS Packet.0'                                                                                      | sudo tee -a ${STARTMENU}/rmspacket.desktop > /dev/null
            echo 'StartupWMClass=rms packet.exe'                                                                               | sudo tee -a ${STARTMENU}/rmspacket.desktop > /dev/null
            echo 'Categories=HamRadio;'                                                                                        | sudo tee -a ${STARTMENU}/rmspacket.desktop > /dev/null
    cd ..
}

function run_installrmsrelay()
{
    mkdir downloads 2>/dev/null; cd downloads
        # Download RMS Relay (no matter its version number) [https://downloads.winlink.org/Sysop%20Programs/]
            echo -e "\n${GREENTXT}Downloading and installing RMS Relay . . .${NORMTXT}\n"
            wget -q -r -l1 -np -nd -A "RMS_Relay_install_*.zip" https://downloads.winlink.org/Sysop%20Programs || { echo "RMS Relay download failed!" && run_giveup; }

        # Extract/install RMS Relay
            7z x RMS_Relay_install_*.zip -o"RMSRelayInstaller" -y -bsp0 -bso0
            BOX86_DYNAREC=0 WINEDEBUG=-all wine RMSRelayInstaller/RMS_Relay_install.exe /SILENT

	# Clean up
            rm -rf RMSRelayInstaller
	    #sleep 3; sudo rm -rf ~/.local/share/applications/wine/Programs/RMS\ Relay/ # Remove wine's auto-generated program icon from the start menu

        # Make an RMS Relay desktop shortcut
            echo '[Desktop Entry]'                                                                                           | sudo tee ${STARTMENU}/rmsrelay.desktop > /dev/null
            echo 'Name=RMS Relay'                                                                                            | sudo tee -a ${STARTMENU}/rmsrelay.desktop > /dev/null
            echo 'GenericName=RMS Relay'                                                                                     | sudo tee -a ${STARTMENU}/rmsrelay.desktop > /dev/null
            echo 'Comment=RMS Relay emulated with Box86/Wine'                                                                | sudo tee -a ${STARTMENU}/rmsrelay.desktop > /dev/null
            echo 'Exec=env BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine '$HOME'/.wine/drive_c/RMS/RMS\ Relay/RMS\ Relay.exe' | sudo tee -a ${STARTMENU}/rmsrelay.desktop > /dev/null
            echo 'Type=Application'                                                                                          | sudo tee -a ${STARTMENU}/rmsrelay.desktop > /dev/null
            echo 'StartupNotify=true'                                                                                        | sudo tee -a ${STARTMENU}/rmsrelay.desktop > /dev/null
            #echo 'Icon=2BD9_ADIF Analyzer.0'                                                                                 | sudo tee -a ${STARTMENU}/rmsrelay.desktop > /dev/null
            echo 'StartupWMClass=rms relay.exe'                                                                              | sudo tee -a ${STARTMENU}/rmsrelay.desktop > /dev/null
            echo 'Categories=HamRadio;'                                                                                      | sudo tee -a ${STARTMENU}/rmsrelay.desktop > /dev/null
    cd ..
}

function run_installrmslinktest()
{
    mkdir downloads 2>/dev/null; cd downloads
        # Download RMS Link Test (no matter its version number) [https://downloads.winlink.org/Sysop%20Programs/]
            echo -e "\n${GREENTXT}Downloading and installing RMS Link Test . . .${NORMTXT}\n"
            wget -q -r -l1 -np -nd -A "RMS_Link_Test_install_*.zip" https://downloads.winlink.org/Sysop%20Programs || { echo "RMS Link Test download failed!" && run_giveup; }

        # Extract/install RMS Link Test
            7z x RMS_Link_Test_install_*.zip -o"RMSLinkTestInstaller" -y -bsp0 -bso0
            BOX86_DYNAREC=0 WINEDEBUG=-all wine RMSLinkTestInstaller/RMS_Link_Test_install.exe /SILENT

	# Clean up
            rm -rf RMSLinkTestInstaller
	    sleep 3; sudo rm -rf ~/.local/share/applications/wine/Programs/RMS\ Link\ Test/ # Remove wine's auto-generated program icon from the start menu

        # Make an RMS Link Test desktop shortcut
            echo '[Desktop Entry]'                                                                                               | sudo tee ${STARTMENU}/rmslinktest.desktop > /dev/null
            echo 'Name=RMS Link Test'                                                                                            | sudo tee -a ${STARTMENU}/rmslinktest.desktop > /dev/null
            echo 'GenericName=RMS Link Test'                                                                                     | sudo tee -a ${STARTMENU}/rmslinktest.desktop > /dev/null
            echo 'Comment=RMS Link Test emulated with Box86/Wine'                                                                | sudo tee -a ${STARTMENU}/rmslinktest.desktop > /dev/null
            echo 'Exec=env BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine '$HOME'/.wine/drive_c/RMS/RMS\ Link\ Test/RMS\ Link\ Test.exe' | sudo tee -a ${STARTMENU}/rmslinktest.desktop > /dev/null
            echo 'Type=Application'                                                                                              | sudo tee -a ${STARTMENU}/rmslinktest.desktop > /dev/null
            echo 'StartupNotify=true'                                                                                            | sudo tee -a ${STARTMENU}/rmslinktest.desktop > /dev/null
            echo 'Icon=C08D_RMS Link Test.0'                                                                                     | sudo tee -a ${STARTMENU}/rmslinktest.desktop > /dev/null
            echo 'StartupWMClass=rms link test.exe'                                                                              | sudo tee -a ${STARTMENU}/rmslinktest.desktop > /dev/null
            echo 'Categories=HamRadio;'                                                                                          | sudo tee -a ${STARTMENU}/rmslinktest.desktop > /dev/null
    cd ..
}

function run_installvarAC()  # Download/extract/install varAC chat app
{
    mkdir downloads 2>/dev/null; cd downloads
        # Download varAC linux working version 6.1 (static Link as no dynamic link known at the moment)
            echo -e "\n${GREENTXT}Downloading and installing VarAC . . .${NORMTXT}\n"
            wget -q https://varac.hopp.bio/varac_latest || { echo "VarAC download failed!" && run_giveup; }
            
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

function run_installvara()
{
			# Download / extract / silently install VARA HF
				# Search the rosmodem website for a VARA HF mega.nz link of any version, then download it
					echo -e "\n${GREENTXT}Downloading VARA HF . . .${NORMTXT}\n"
					VARAHFLINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA HF v)')
					megadl ${VARAHFLINK} --path=${VARAUPDATE} || { echo "VARA HF download failed!" && run_giveup; }
					7z x ${VARAUPDATE}/VARA\ HF*.zip -o"${VARAUPDATE}/VARAHFInstaller" -y -bsp0 -bso0
					mv ${VARAUPDATE}/VARAHFInstaller/VARA\ setup*.exe ~/.wine/drive_c/ # move VARA installer into wineprefix (so AHK can find it)

          # Install dll's needed by users of "RA-boards," like the DRA-50
          #  https://masterscommunications.com/products/radio-adapter/dra/dra-index.html
          #BOX86_NOBANNER=1 winetricks -q hid # unsure if this is needed...
          ##sudo apt-get install p7zip-full -y
          ##wget -q http://uz7.ho.ua/modem_beta/ptt-dll.zip
          ##7z x ptt-dll.zip -o"$HOME/.wine/drive_c/VARA/" -y -bsp0 -bso0 # For VARA HF & VARAChat
          ##7z x ptt-dll.zip -o"$HOME/.wine/drive_c/VARA FM/" -y -bsp0 -bso0 # For VARA FM
          
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
					BOX86_DYNAREC=0 BOX86_NOBANNER=1 BOX64_DYNAREC_BIGBLOCK=0 BOX64_DYNAREC=0 BOX64_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine ${AHK}/AutoHotkey.exe ${AHK}/varahf_install.ahk # install VARA silently using AHK
				
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
}

function run_installothervarastuff()
{
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
					BOX86_DYNAREC=0 BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine ${AHK}/AutoHotkey.exe ${AHK}/varafm_install.ahk # install VARA silently using AHK

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
		#			BOX86_DYNAREC=0 BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine ${AHK}/AutoHotkey.exe ${AHK}/varasat_install.ahk # install VARA silently using AHK
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
					BOX86_NOBANNER=1 BOX86_DYNAREC=0 wine ${VARAUPDATE}/VARAChatInstaller/VARA\ Chat\ setup*.exe /SILENT # install VARA Chat
				
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
			sudo rm ${STARTMENU}/winlinkexpress.desktop ${STARTMENU}/rmssimpleterminal.desktop \
				${STARTMENU}/rmstrimode.desktop ${STARTMENU}/rmsadifanalyzer.desktop \
				${STARTMENU}/rmspacket.desktop ${STARTMENU}/rmsrelay.desktop ${STARTMENU}/rmslinktest.desktop \
				${STARTMENU}/vara.desktop ${STARTMENU}/vara-fm.desktop ${STARTMENU}/vara-sat.desktop ${STARTMENU}/vara-chat.desktop \
				${STARTMENU}/vara-soundcardsetup.desktop ${STARTMENU}/vara-update.desktop ${STARTMENU}/VarAC.desktop \
				${STARTMENU}/resetwine.desktop 2>/dev/null # remove old shortcuts
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


run_main "$@"; exit # Run the "run_main" function after a
