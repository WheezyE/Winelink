#!/bin/bash

exec > >(tee "omniOS.log") 2>&1 # Make a log of this script's output

function run_main()
{
    #work in progress
    
    run_detect_os
    run_detect_arch
    run_detect_bits
    run_detect_raspver
    run_detect_raspmodel
    
    if [ "${FAMILY_IS}" = "termux" && "${ARCH_IS}" = "aarch64"]; then
        # Install AnBox86 for aarch64
        pkg update -y; pkg install wget -y  < "/dev/null"
        wget https://raw.githubusercontent.com/lowspecman420/AnBox86/main/AnBox86.sh
        bash AnBox86.sh
    elif [ "${FAMILY_IS}" = "rpi" && "${ARCH_IS}" = "aarch64"]; then
        # Install Winelink for RPi4B with multiarch
        echo "Winelink does not currenly support 64bit Raspberry Pi OS."
        run_giveup
    elif [ "${FAMILY_IS}" = "rpi" && "${ARCH_IS}" = "armv7l"]; then
        # Install Winelink for RPi4B (will also attempt on earlier models but will crash for now)
        wget https://raw.githubusercontent.com/WheezyE/Winelink/main/install_winelink.sh
        bash install_winelink.sh
    else run_giveup
    fi
    
    exit
}

function run_giveup()
{
    echo -e "\nYour system is either not compatible with this script or no installation method has been found yet."
    echo "Press any key to exit . . ."
    read -n 1 -s -r -p ""
}

function run_detect_os()
{
    # Find os-release file & and try to read its variables
    if [ -e /etc/os-release ];       then OS_INFOFILE='/etc/os-release'     && echo "Found ${OS_INFOFILE}"
    elif [ -e /usr/lib/os-release ]; then OS_INFOFILE='/usr/lib/os-release' && echo "Found ${OS_INFOFILE}"
    elif [ -e /etc/*elease ];        then OS_INFOFILE='/etc/*elease'        && echo "Found ${OS_INFOFILE}"
    else OS_INFOFILE='' && echo "No OS info files could be found!">&2; # go to run_giveup
    fi
    
    # Read OS-Release File vars (loads vars like "ID")
    source "${OS_INFOFILE}"
    # Each release file has its own set of vars, but highly-conserved vars are ...
        #NAME="Alpine Linux"
        #ID=alpine
        #VERSION_ID=3.8.1
        #PRETTY_NAME="Alpine Linux v3.8"
        #HOME_URL="http://alpinelinux.org"
    # Other vars are listed here: https://docs.google.com/spreadsheets/d/1ixz0PfeWJ-n8eshMQN0BVoFAFnUmfI5HIMyBA0uK43o/edit#gid=0
    
    # Parse vars from OS release file
    if [ "${PREFIX}" = "/data/data/com.termux/files/usr" ];      then echo "Looks like Termux!"                         && FAMILY_IS=termux && DISTRO=termux && PACKAGES=pkg
    # [[ $PREFIX =~ /data/data/[^/]+/files/usr ]] && echo IN_TERMUX # for use with termux forks (where [^/]+ means one or more characters that are not a forward slash /)

    elif [ "${ID}" = "linuxmint" ];                              then echo "Looks like Linux Mint (Ubuntu/Debian)!"     && FAMILY_IS=debian && DISTRO= && PACKAGES=apt    # Mint also has ID_LIKE=ubuntu
    elif [ "${ID}" = "elementary" ];                             then echo "Looks like elementary OS (Ubuntu/Debian)!"  && FAMILY_IS=debian && DISTRO= && PACKAGES=apt    # elementary OS also has ID_LIKE=ubuntu
    elif [ "${ID}" = "ubuntu" ] || [ "${ID_LIKE}" = "ubuntu" ];  then echo "Looks like Ubuntu (Debian)!"                && FAMILY_IS=debian && DISTRO= && PACKAGES=apt    # Ubuntu also has ID_LIKE=debian

    elif [ "${ID}" = "kali" ];                                   then echo "Looks like Kali (Debian)!"                  && FAMILY_IS=debian && DISTRO= && PACKAGES=apt    # Kali also has ID_LIKE=debian
    elif [ "${ID}" = "raspbian" ];                               then echo "Looks like Raspberry Pi OS (Debian)!"       && FAMILY_IS=rpi    && DISTRO= && PACKAGES=apt    # RPi OS also has ID_LIKE=debian
    elif [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ];  then echo "Looks like Debian!"                         && FAMILY_IS=debian && DISTRO= && PACKAGES=apt

    elif [ "${ID}" = "rhel" ];                                   then echo "Looks like Red Hat (Fedora)!"               && FAMILY_IS=fedora && DISTRO= && PACKAGES='' # Red Hat also has ID_LIKE=fedora
    elif [ "${ID}" = "centos" ];                                 then echo "Looks like CentOS (Fedora)!"                && FAMILY_IS=fedora && DISTRO= && PACKAGES='' # CentOS also has "ID_LIKE=rhel fedora"
    elif [ "${ID}" = "fedora" ] || [ "${ID_LIKE}" = "fedora" ];  then echo "Looks like Fedora!"                         && FAMILY_IS=fedora && DISTRO= && PACKAGES=''

    elif [ "${ID}" = "manjaro" ];                                then echo "Looks like Manjaro (Arch Linux)!"           && FAMILY_IS=arch   && DISTRO= && PACKAGES='' # Manjaro also has ID_LIKE=arch
    elif [ "${ID}" = "arch" ] || [ "${ID_LIKE}" = "archlinux" ]; then echo "Looks like Arch Linux!"                     && FAMILY_IS=arch   && DISTRO= && PACKAGES=''

    elif [ "${ID}" = "opensuse" ];                               then echo "Looks like openSUSE!"                       && FAMILY_IS=suse   && DISTRO= && PACKAGES=''  # openSuSe also has ID_LIKE="suse"
    elif [ "${ID}" = "sles" ];                                   then echo "Looks like SUSE Linux Enterprise Server!"   && FAMILY_IS=suse   && DISTRO= && PACKAGES=''  # SLES also has ID_LIKE="suse" (though old SLES doesn't)

    elif [ "${ID}" = "slackware" ];                              then echo "Looks like Slackware!"                      && FAMILY_IS=slack  && DISTRO= && PACKAGES=''
    elif [ "${ID}" = "ol" ];                                     then echo "Looks like Oracle!"                         && FAMILY_IS=oracle && DISTRO= && PACKAGES=''
    elif [ "${ID}" = "gentoo" ];                                 then echo "Looks like Gentoo!"                         && FAMILY_IS=gentoo && DISTRO= && PACKAGES=''
    elif [ "${ID}" = "alpine" ];                                 then echo "Looks like Alpine Linux!"                   && FAMILY_IS=alpine && DISTRO= && PACKAGES=''
    
    # Add mac OS
    # Add chrome OS
    # Add chroot Android?
    # Find package managers
    
    else FAMILY_IS=suse && PACKAGES=unknown && echo "Could not determine operating system!">&2; # Go to run_giveup
    fi
    
    # To my knowledge . . .
    #  - Most post-2012 distros should have a standard '/etc/os-release' file for finding OS
    #  - Pre-2012 distros (& small distros) may not have a canonical way of finding OS.
    
    #echo "Running on ${PRETTY_NAME:-an unknown OS}" # Print name of OS. If no PRETTY_NAME was found, print "an uknown OS."
    #uname -o # can be used to find "Android"
}

function run_detect_arch()
{
    uname -m # do not use 'arch' since it is not supported by Termux
    # armv7l on RPi4B and RPi3B+ 32-bit
}

function run_detect_bits()
{
    # https://superuser.com/questions/208301/linux-command-to-return-number-of-bits-32-or-64/208306#208306
}

function run_detect_raspver()
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

function run_detect_raspmodel()
{
    TMPVAR1=$(tr -d '\0' </sys/firmware/devicetree/base/model) # Store full name of Pi
    RPIHARDWARE=${TMPVAR1%" Rev"*} # Extract Pi's name before " Rev", so we don't store the Pi's revision name.
    
    if [[ "$RPIHARDWARE" = "Raspberry Pi 3 Model A+" ]] || [[ "$RPIHARDWARE" = "Raspberry Pi 2 Model B" ]] || [[ "$RPIHARDWARE" = "Raspberry Pi 3 Model B" ]] || [[ "$RPIHARDWARE" = "Raspberry Pi 3 Model B+" ]]; then
        run_giveup
    else # [[ "$RPIHARDWARE" = "Raspberry Pi 4 Model B" ]]
        # echo "cool"
    fi
}

function run_omni_packinstall()
{
    # Takes the name of a package and tries to install it using any onboard package manager
    #  - https://wiki.archlinux.org/title/Pacman/Rosetta
    local packagesNeeded="$1"
    if [ -x "$(command -v apk)" ];       then sudo apk add --no-cache $packagesNeeded # Alpine Linux
    elif [ -x "$(command -v apt-get)" ]; then sudo apt-get install $packagesNeeded # Debian/Ubuntu
    elif [ -x "$(command -v dnf)" ];     then sudo dnf install $packagesNeeded # Red Hat/Fedora
    elif [ -x "$(command -v zypper)" ];  then sudo zypper install $packagesNeeded # SLES/openSUSE
    elif [ -x "$(command -v pacman)" ];  then sudo pacman -S $packagesNeeded # Arch
    elif [ -x "$(command -v emerge)" ];  then sudo emerge [-a] $packagesNeeded # Portage? Gentoo
    elif [ -x "$(command -v yum)" ];     then sudo yum install $packagesNeeded #  - deprecated, replaced by DNF. https://access.redhat.com/articles/yum-cheat-sheet
    elif [ -x "$(command -v nix)" ];  then sudo nix-env -i $packagesNeeded
    else echo "FAILED TO INSTALL PACKAGE: Package manager not found. You must manually install: $packagesNeeded">&2; fi
    # 'command -v foo' outputs the location of the executable if it is installed. '-x' tests that the file is executable
}

run_main
