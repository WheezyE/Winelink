
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

function run_Sideload_i386wine() {
	# Wine version variables
	local branch="$1" #example: "devel" or "stable" without quotes (wine-staging 4.5+ depends on libfaudio0 and requires more install steps)
	local version="$2" #example: "7.1"
	local id="$3" #example: debian ($ID_LIKE) - TODO: implement other distros, like Ubuntu
	local dist="$4" #example: bullseye ($VERSION_CODENAME)
	local tag="$5" #example: -1
 
	# if [ $WINEVER is populated (indicating wine is the desired version) ] && [ dotnet4 is installed (indicating wine is functioning) ] then skip re-wine install.
	local WINEVER=$(wine --version | grep "$version\b")
	if [ ! -z "$WINEVER" ] && [ -d "$HOME/.wine/drive_c/windows/Microsoft.NET/Framework/v4.0.30319" ]
	then
		echo "Wine has already been installed and run. Skipping wine installation."
	else	
		# NOTE: We only really need i386-wine/box86 on RPiOS 64/32-bit for RMS Express and VARA since they are 32-bit.
		# We don't need really amd64-wine64/box64 for our purposes of running RMS Express and VARA.
		
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
	fi
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
	for i in 'libcap2-bin:armhf' 'libcups2:armhf' 'libdbus-1-3:armhf' 'libfontconfig1:armhf' 'libfreetype6:armhf' 'libglu1-mesa:armhf' 'libgnutls30:armhf' 'libgssapi-krb5-2:armhf' 'libkrb5-3:armhf' 'libodbc1:armhf' 'libosmesa6:armhf' 'libsdl2-2.0-0:armhf' 'libv4l-0:armhf' 'libxcomposite1:armhf' 'libxcursor1:armhf' 'libxfixes3:armhf' 'libxi6:armhf' 'libxinerama1:armhf' 'libxrandr2:armhf' 'libxrender1:armhf' 'libxxf86vm1:armhf'; do
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

function run_Install_i386wineDependencies_RpiOS64bit()
{
	# Install :armhf libraries to run i386-Wine on RPiOS 64-bit
	# - these packages are needed for running box86/wine-i386 on a 64-bit RPiOS via multiarch
	echo -e "${GREENTXT}Installing armhf dependencies for i386-Wine on aarch64 . . .${NORMTXT}"
	sudo dpkg --add-architecture armhf && sudo apt-get update #enable multi-arch
	
	sudo apt-get install -y libasound2:armhf libc6:armhf libglib2.0-0:armhf libgphoto2-6:armhf libgphoto2-port12:armhf \
	    libgstreamer-plugins-base1.0-0:armhf libgstreamer1.0-0:armhf libldap-2.5-0:armhf libopenal1:armhf libpcap0.8:armhf \
	    libpulse0:armhf libsane1:armhf libudev1:armhf libusb-1.0-0:armhf libvkd3d1:armhf libx11-6:armhf libxext6:armhf \
	    libasound2-plugins:armhf ocl-icd-libopencl1:armhf libncurses6:armhf libncurses5:armhf libcap2-bin:armhf libcups2:armhf \
	    libdbus-1-3:armhf libfontconfig1:armhf libfreetype6:armhf libglu1-mesa:armhf libglu1:armhf libgnutls30:armhf \
	    libgssapi-krb5-2:armhf libkrb5-3:armhf libodbc1:armhf libosmesa6:armhf libsdl2-2.0-0:armhf libv4l-0:armhf \
	    libxcomposite1:armhf libxcursor1:armhf libxfixes3:armhf libxi6:armhf libxinerama1:armhf libxrandr2:armhf \
	    libxrender1:armhf libxxf86vm1 libc6:armhf libcap2-bin:armhf x11-utils:armhf libxcomposite-dev:armhf # to run wine-i386 through box86:armhf on aarch64
	# Dependencies can be found through trial-error and/or by by downloading...
	#	wget https://dl.winehq.org/wine-builds/debian/dists/bullseye/main/binary-i386/wine-devel-i386_7.1~bullseye-1_i386.deb
	#	wget https://dl.winehq.org/wine-builds/debian/dists/bullseye/main/binary-i386/winehq-devel_7.1~bullseye-1_i386.deb
	#	wget https://dl.winehq.org/wine-builds/debian/dists/bullseye/main/binary-i386/wine-devel_7.1~bullseye-1_i386.deb
	# then `dpkg-deb -I package.deb`. Read output, add `:armhf` to packages in dep list, then try installing them on Pi aarch64.
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
