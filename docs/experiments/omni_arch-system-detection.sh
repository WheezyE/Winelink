#!/bin/bash

# Just a head's-up to anybody reading this - this is basically a rough draft and is SUPER messy.
# I don't really have a concept for how I'm going to go about this yet, but the more I play with the code, the better grasp I have on what I need to do.
# Just know that this is pretty nonsensical for now.

# The script attempts to read an OS info file.
# In general, we need to know: package manager (to install packages), $ID & $VERSION_ID (to download specific wine distro repos)

exec > >(tee "omniOS.log") 2>&1 # Make a log of this script's output

function run_main()
{
    # Detect system specs
    # - other functions in this script depend on these being run first
    run_detect_arch # sets the $ARCH variable (to x86, x86_64, ARM32, or ARM64)
    run_gather_os_info # sets many os-release variables (see below)
    
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
    
    # Now run the proper install script depending on processor OS & kernel architecture
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
                    # Need botspot code to install Winelink for RPi4B with multiarch
                    run_giveup
                else
                    run_giveup
                    # To-do: Consider warning the user and then trying a generic install method
                fi
        
    elif [[ "${ARCH}" = "ARM32" ]]; then
                if [[ "${ID}" = "raspbian" ]]; then
                    echo "32-bit Raspberry Pi (ARM) detected"
                    run_detect_raspver
                    run_detect_raspmodel
                    pause
                    # Install Winelink for RPi4B (will also attempt on earlier models but will crash for now)
                    wget https://raw.githubusercontent.com/WheezyE/Winelink/main/install_winelink.sh
                    bash install_winelink.sh
                else
                    run_giveup
                    # To-do: Consider warning the user and then trying a generic install method
                fi

    elif [[ "${ARCH}" = "x64" ]]; then
        echo "64-bit PC detected"
        run_announce_known_os
            echo "Inferred variables:"
            echo "OS Family =" $FAMILY_IS
            echo "Distro =" $DISTRO # This is redundant with $ID, but we could make the ID name look better with this var if we wanted to
            echo "Default package manager =" $PACKAGES
            echo ""
        
    elif [[ "${ARCH}" = "x86" ]]; then
        echo "32-bit PC detected"
        run_announce_known_os
            echo "Inferred variables:"
            echo "OS Family =" $FAMILY_IS
            echo "Distro =" $DISTRO # This is redundant with $ID, but we could make the ID name look better with this var if we wanted to
            echo "Default package manager =" $PACKAGES
            echo ""
        
    else
        echo "Your operating system and kernel architecture may not be compatable with Winelink.">&2
        run_giveup
        
    fi
    
    exit
}



# ============================================== Sub-routines ==============================================

function run_detect_arch()
{ # Finds what kind of processor we're running (aarch64, armv8l, armv7l, x86_64, x86, etc)
    KARCH=$(uname -m) # Don't use 'arch' since it is not supported by Termux
    
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

function run_announce_known_os() # depends on function run_gather_os_info
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

function run_detect_raspver() # depends on function run_gather_os_info
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

function run_detect_raspmodel() # depends on function run_gather_os_info
{
    TMPVAR1=$(tr -d '\0' </sys/firmware/devicetree/base/model) # Store full name of Pi
    RPIHARDWARE=${TMPVAR1%" Rev"*} # Extract Pi's name before " Rev", so we don't store the Pi's revision name.
    
    if [[ "$RPIHARDWARE" = "Raspberry Pi 3 Model A+" ]] || [[ "$RPIHARDWARE" = "Raspberry Pi 2 Model B" ]] || [[ "$RPIHARDWARE" = "Raspberry Pi 3 Model B" ]] || [[ "$RPIHARDWARE" = "Raspberry Pi 3 Model B+" ]]; then
        run_giveup
    else # [[ "$RPIHARDWARE" = "Raspberry Pi 4 Model B" ]]
        : # echo "cool"
    fi
}

function run_omni_packinstall()
{
    # Takes the name of a package and tries to install it using any onboard package manager
    # Might only be useful for installations that don't require special instructions
    # It might be best not to rely on this, but I'm not sure yet.
    #  - https://wiki.archlinux.org/title/Pacman/Rosetta
    local packagesNeeded="$1"
    if [ -x "$(command -v apk)" ];       then sudo apk add --no-cache $packagesNeeded # Alpine Linux
    elif [ -x "$(command -v apt-get)" ]; then sudo apt-get install $packagesNeeded # Debian/Ubuntu
    elif [ -x "$(command -v dnf)" ];     then sudo dnf install $packagesNeeded # Red Hat/Fedora
    elif [ -x "$(command -v rpm)" ];     then sudo rpm -i $packagesNeeded # Red Hat/Fedora - NOTE this is likely to fail? Needs rpm packages specified?
    elif [ -x "$(command -v zypper)" ];  then sudo zypper install $packagesNeeded # SLES/openSUSE
    elif [ -x "$(command -v pacman)" ];  then sudo pacman -S $packagesNeeded # Arch
    elif [ -x "$(command -v emerge)" ];  then sudo emerge [-a] $packagesNeeded # Portage package manager in Gentoo
    elif [ -x "$(command -v yum)" ];     then sudo yum install $packagesNeeded #  - deprecated, replaced by DNF. https://access.redhat.com/articles/yum-cheat-sheet
    elif [ -x "$(command -v nix)" ];  then sudo nix-env -i $packagesNeeded
    elif [ -x "$(command -v slackpkg)" ];  then sudo slackpkg install $packagesNeeded 
    else echo "FAILED TO INSTALL PACKAGE: Package manager not found. You must either use a different package manager or manually install: $packagesNeeded">&2; fi
    # 'command -v foo' outputs the location of the executable if it is installed. '-x' tests that the file is executable
}

function run_giveup()
{
    echo -e "\nYour system is either not compatible with this script or no installation method has been found yet."
    echo "Press any key to exit . . ."
    read -n 1 -s -r -p ""
}

run_main
