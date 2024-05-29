#!/bin/bash

#version=4.8.7
APPDIR=${HOME}/.local/share/applications
mkdir /tmp/ 2>/dev/null

#Installing wine
if [ $arch == 32 ]; then
  "$DIRECTORY/manage" install-if-not-installed 'Wine (x86)' || error 'Failed to install wine'
elif [ $arch == 64 ]; then
  "$DIRECTORY/manage" install-if-not-installed 'Wine (x64)' || error 'Failed to install wine'
fi
#Configuring wineprefix for VARA programs
BOX86_DYNAREC=0 BOX64_DYNAREC=0 BOX86_NOBANNER=1 BOX64_NOBANNER=1 winetricks -q vb6run pdh_nt4 sound=alsa

#Downloading VARA HF
mkdir /tmp/VARAHF 2>/dev/null && VARAHFDIR=/tmp/VARAHF
wget -q -r -l1 -np -nd -A "VARA HF v*setup.zip" "https://downloads.winlink.org/VARA%20Products" -P ${VARAHFDIR} || WINLINKORG_DOWNLOAD_FAILED="VARA HF download failed: Could not connect to winlink.org. Trying mega.nz"
if [ ${WINLINKORG_DOWNLOAD_FAILED} ]; then
    echo ${WINLINKORG_DOWNLOAD_FAILED}
    VARAHFLINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA HF v)') || error 'VARA HF download failed: Could not find mega.nz link from rosmodem site.'
    sudo apt install -y megatools || error 'VARA HF download failed: Could not install megatools'
    megadl ${VARAHFLINK} --path=${VARAHFDIR} || error 'VARA HF download failed: Could not connect to mega.nz'
fi

#Extracting VARA HF installer archives
unzip -o ${VARAHFDIR}/VARA\ HF\ v*setup.zip -d "${VARAHFDIR}" || error 'Failed to unzip VARA HF archive'

#Running VARA HF setup with autohotkey so we can auto-close its OK button
# Notes: The VARA installer prompts the user to hit 'OK' even during silent install (due to a secondary installer that registers OCX & DLL files which cannot be bypassed).  We will click this 'OK' button with AHK.

# Downloading AutoHotKey
echo -e "Downloading AutoHotkey..."
mkdir /tmp/AHK 2>/dev/null && AHKDIR=/tmp/AHK
wget -q "https://github.com/AutoHotkey/AutoHotkey/releases/download/v2.0.17/AutoHotkey_2.0.17.zip" -P ${AHKDIR} || error 'Failed to download AutoHotKey from Github'
unzip -o ${AHKDIR}/AutoHotkey_2.0.17.zip -d "${AHKDIR}" || error 'Failed to unzip AutoHotKey archive'

# Creating varahf_install.ahk (autohotkey script)
echo '; AHK script to make VARA installer run completely silent'                                               > ${AHKDIR}/varahf_install.ahk
echo 'SetTitleMatchMode, 2'                                                                                    >> ${AHKDIR}/varahf_install.ahk
echo 'SetTitleMatchMode, slow'                                                                                 >> ${AHKDIR}/varahf_install.ahk
echo '        Run, VARA setup (Run as Administrator).exe /SILENT /c:"VARA setup (Run as Administrator).exe"'   >> ${AHKDIR}/varahf_install.ahk
echo '        WinWait, VARA Setup ; Wait for the "VARA installed successfully" window'                         >> ${AHKDIR}/varahf_install.ahk
echo '        ControlClick, Button1, VARA Setup ; Click the OK button'                                         >> ${AHKDIR}/varahf_install.ahk
echo '        WinWaitClose'                                                                                    >> ${AHKDIR}/varahf_install.ahk

# Running varahf_install.ahk
echo -e "\nInstalling VARA HF . . ."
BOX86_DYNAREC=0 BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine ${AHKDIR}/AutoHotkey.exe ${AHKDIR}/varahf_install.ahk

# Removing tmp files
rm -rf ${AHKDIR} ${VARAHFDIR}

#Creating Desktop Entry
#sleep 3; sudo rm -rf ${$APPDIR}/wine/Programs/VARA/ # Remove wine's auto-generated VARA HF program icon from the start menu
#mkdir -p $APPDIR
#echo "[Desktop Entry]
#Name=VARA HF
#Comment=VARA HF is a shareware ham radio OFDM software modem for RMS Express and other messaging clients.
#Exec=wine $HOME/.wine/drive_c/VARA\ HF/VARA.exe
#Icon=$(dirname "$0")/icon-64.png
#Terminal=false
#StartupNotify=true
#Type=Application
#Categories=Utility;" > $APPDIR/varahf.desktop || error 'Failed to create menu button!'

exit

function uninstallVARAHF()
{
    APPDIR=$HOME/.local/share/applications

    #Finding wineprefix directory that holds VARA
    if [ -f $APPDIR/wine/Programs/VARA/VARA.desktop ]; #if VARA shortcut exists...
    then
        echo "Found varahf shortcut"
        WINEDIR=$(more $APPDIR/wine/Programs/VARA/VARA.desktop | grep -Eio '"[^"]*"' | grep -Eio '[^"]*') #get wineprefix directory from VARA shortcut
    else
        WINEDIR=$HOME/.wine #otherwise assume VARA was installed into the default .wine wineprefix directory
    fi
    
    #Unregistering OCX/DLL files from your wineprefix
    BOX86_NOBANNER=1 BOX64_NOBANNER=1 WINEDEBUG=-all wine regsvr32 $WINEDIR/drive_c/VARA/OCX/* /u /s
    #Removing program files (but keeping any settings files)
    mv $WINEDIR/drive_c/VARA/VARA.ini /tmp/VARA.ini 2> /dev/null
    rm -rf $WINEDIR/drive_c/VARA/*
    mv /tmp/VARA.ini $WINEDIR/drive_c/VARA/VARA.ini 2> /dev/null
    if [ $(ls -A "$WINEDIR/drive_c/VARA/" | wc -l) -eq 0 ]; then rm -rf "$WINEDIR/drive_c/VARA/"; fi #also delete directory if it's empty (if its directory listing has zero lines)
    #Removing Desktop Entry
    rm $APPDIR/wine/Programs/VARA/VARA.desktop
    if [ $(ls -A "$APPDIR/wine/Programs/VARA/" | wc -l) -eq 0 ]; then rm -rf "$APPDIR/wine/Programs/VARA/"; fi #also delete directory if it's empty (if its directory listing has zero lines)
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
                    echo '; AHK script to make VARA installer run completely silent'                       > ${AHKDIR}/varafm_install.ahk
                    echo 'SetTitleMatchMode, 2'                                                            >> ${AHKDIR}/varafm_install.ahk
                    echo 'SetTitleMatchMode, slow'                                                         >> ${AHKDIR}/varafm_install.ahk
                    echo '        Run, VARA FM setup (Run as Administrator).exe /SILENT, C:\'              >> ${AHKDIR}/varafm_install.ahk
                    echo '        WinWait, VARA Setup ; Wait for the "VARA installed successfully" window' >> ${AHKDIR}/varafm_install.ahk
                    echo '        ControlClick, Button1, VARA Setup ; Click the OK button'                 >> ${AHKDIR}/varafm_install.ahk
                    echo '        WinWaitClose'                                                            >> ${AHKDIR}/varafm_install.ahk

                # Run varafm_install.ahk
                    echo -e "\n${GREENTXT}Installing VARA FM . . .${NORMTXT}\n"
                    BOX86_DYNAREC=0 BOX86_NOBANNER=1 BOX86_DYNAREC_BIGBLOCK=0 WINEDEBUG=-all wine ${AHKDIR}/AutoHotkey.exe ${AHKDIR}/varafm_install.ahk # install VARA silently using AHK

                # Clean up the installation
                    rm ~/.wine/drive_c/VARA\ FM\ setup*.exe
                    rm ${AHKDIR}/varafm_install.ahk
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

        #    # Download / extract / silently install VARA SAT
        #        # Search the rosmodem website for a VARA SAT mega.nz link of any version, then download it
        #            echo -e "\n${GREENTXT}Downloading VARA SAT . . .${NORMTXT}\n"
        #            VARAFMLINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?=https://mega.nz).*?(?=" target="_blank" rel="noopener noreferrer">VARA SAT v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
        #            megadl ${VARAFMLINK} --path=${VARAUPDATE} || { echo "VARA SAT download failed!" && run_giveup; }
        #            7z x ${VARAUPDATE}/VARA\ SAT*.zip -o"${VARAUPDATE}/VARASATInstaller" -y -bsp0 -bso0
        #            mv ${VARAUPDATE}/VARASATInstaller/VARA\ SAT\ setup*.exe ~/.wine/drive_c/ # move VARA installer here (so AHK can find it later)

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
