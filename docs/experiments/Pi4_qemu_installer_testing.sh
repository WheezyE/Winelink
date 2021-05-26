# Fair warning: This script is work in progress and is currently kind of a mess.  I'm still trying to get a reliably reproducable install.  Bus error keeps getting thrown inconsistently - though it has worked on one install (not sure the conditions yet).  On the working install, wine had collisions with qemu memory allocations, which is why (I believe) novaspirit disabled the wine preloader (which probably reserves memory)

cd ~
sudo apt-get install -y qemu qemu-user qemu-user-static binfmt-support debootstrap binutils debian-keyring debian-archive-keyring

#sudo rm /usr/bin/qemu-i386-static # Delete old qemu-user-static i386 emulator file & replace with a newer version
#wget https://github.com/multiarch/qemu-user-static/releases/download/v5.2.0-2/qemu-i386-static
#sudo chmod +x qemu-i386-static
#sudo mv qemu-i386-static /usr/bin/

    cd ~/Downloads
    git clone https://git.qemu.org/git/qemu.git
    cd qemu
    ./configure \
        --prefix=$(cd ..; pwd)/qemu-user-static \
        --static \
        --disable-system \
        --enable-linux-user \
        --enable-sdl \
        --enable-opengl \
        --audio-drv-list=pa \
        --enable-kvm
    #make -j$CORES
    #sudo make install
    ninja -C build  || error "Failed to run ninja -C build'!"
    sudo ninja install -C build
    cd ../qemu-user-static/bin
    for i in *; do sudo mv $i $i-static; done
    
    sudo rm /usr/bin/qemu-*-static
    sudo chmod +x qemu-*-static
    sudo mv qemu-*-static /usr/bin/

# Notes about qemu-user-static: 
# 1. The debian repo qemu-user-static file (qemu-i386-static) is too old and will probably give us the "bus error" message when running wine later.
# 2. We can either download a pre-built qemu-i386-static file, or build our own - qemu-user-static (qemu-i386-static file) build steps are here if desired https://github.com/Itai-Nelken/qemu2deb/issues/11#issuecomment-834962681
# 3. Whether using our own built qemu-user-static files or one downloaded from the internet, we must register the file into binfmt (I believe).  The old qemu-user-static debian repo package can set up the binfmt registration for us, then we can swap our newer qemu-i386-static binary into /usr/bin/


## Register qemu-user-static (/usr/bin/qemu-i386-static binary file) into binfmt - warning untested
## https://github.com/Itai-Nelken/qemu2deb/issues/11#issuecomment-840991848
#
##i386 variables			
#magic='\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x03\x00'
#mask='\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'
#fmt=i386
#
##binfmt qemu-ARCHITECTURE-static registration
#sudo /usr/sbin/./update-binfmts --package qemu-user-static --install qemu-$fmt /usr/bin/qemu-$fmt-static \
#        --magic "$magic" --mask "$mask" --offset 0 --credential yes --fix-binary yes


sudo debootstrap --foreign --arch i386 stretch ./chroot-stretch-i386 http://ftp.us.debian.org/debian
sudo mount -t sysfs sys ./chroot-stretch-i386/sys/
sudo mount -t proc proc ./chroot-stretch-i386/proc/
sudo mount --bind /dev ./chroot-stretch-i386/dev/
sudo mount --bind /dev/pts ./chroot-stretch-i386/dev/pts/
sudo mount --bind /dev/shm ./chroot-stretch-i386/dev/shm/
	
sudo cp /usr/bin/qemu-i386-static ./chroot-stretch-i386/usr/bin/

sudo chroot ./chroot-stretch-i386/ /debootstrap/debootstrap --second-stage # unpack host system. takes about 15 minutes


## Example commands to allow this script to continue to running within chroot
## https://stackoverflow.com/questions/51305706/shell-script-that-does-chroot-and-execute-commands-in-chroot/51312156
#chroot /home/mayank/chroot/codebase /bin/bash <<"EOT"
#cd /tmp/so
#ls -l
#echo $$
#EOT

sudo chroot /home/pi/chroot-stretch-i386/ /bin/su -l root # Set up root account
    # NOTE: "chroot: failed to run command '/bin/su': Exec format error" means that qemu-i386-static was not registered into binfmt correctly. Reinstall the deb repo qemu-user-static package
    arch # should say i686
    echo "export LANGUAGE='C'" >> ~/.bashrc # Add some lines to bashrc for future shell instances, then also initialize those lines for our current shell instance
    echo "export LC_ALL='C'" >> ~/.bashrc
    echo "export DISPLAY=:0" >> ~/.bashrc
    export LANGUAGE='C'
    export LC_ALL='C'
    export DISPLAY=:0
    apt update
    
    apt install -y leafpad # install any x86 gui application so that requirements to run gui will also be installed. Takes about 5 min
    apt install -y bzip2 # for extracting POL files in case we need that
    apt install -y ca-certificates # Teach wget to trust websites
    
    apt install -y sudo # Give the pi (user) chroot account sudo access
    echo "pi ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
    #apt install winbind # don't think we need this even though wine complains about it
    #apt install --reinstall libgnutls30 # not sure what to do about this yet (also not sure if libgnutls wine errors are just old wine bugs from POL version)
    
    # Run an expect script to autoinput info to set up user account automagically
    apt install -y expect # Install expect so that we can automate the user account installation
    chmod 666 /dev/ptmx
    chmod 755 /dev/pts
    mount -t devpts -o gid=5,mode=620 none /dev/pts # this is required for expect to work
    cat >~/setupusr.sh <<EOF
        #!/usr/bin/expect -f
        set force_conservative 0
        set timeout -1
        spawn adduser -uid 1000 pi # I think the uid number should be the same number as your non-chroot pi uid ("id -u")
        match_max 100000
        expect "Enter new UNIX password: "
        send -- "raspberry\r"
        expect "Retype new UNIX password: "
        send -- "raspberry\r"
        expect -exact "Full Name \[\]: "
        send -- "\r"
        expect -exact "Room Number \[\]: "
        send -- "\r"
        expect -exact "Work Phone \[\]: "
        send -- "\r"
        expect -exact "Home Phone \[\]: "
        send -- "\r"
        expect -exact "Other \[\]: "
        send -- "\r"
        expect -exact "Is the information correct? \[Y/n\] "
        send -- "Y\r"
        expect eof
    EOF
    chmod +x ~/setupusr.sh
    ./setupusr.sh
    rm setupusr.sh
exit # exit the su account

sudo chroot /home/pi/chroot-stretch-i386/ /bin/su -l pi # Set up user account
    arch # should say i686
    echo "export LANGUAGE='C'" >> ~/.bashrc #Add lines to bashrc, then initialize them too four our shell instance
    echo "export LC_ALL='C'" >> ~/.bashrc
    echo "export DISPLAY=:0" >> ~/.bashrc
    export LANGUAGE='C'
    export LC_ALL='C'
    export DISPLAY=:0
exit # exit the user account

sudo chroot /home/pi/chroot-stretch-i386/ /bin/su -l root # Log in as root to install wine
    # Old PlayOnLinux wine install method (Novaspirit guide)
    wget https://www.playonlinux.com/wine/binaries/linux-x86/PlayOnLinux-wine-3.9-linux-x86.pol
    tar -jxvf PlayOnLinux-wine-3.9-linux-x86.pol --strip-components=1
    mv ./3.9/bin/wine-preloader ./3.9/bin/wine-preloader.renamed # we need to rename a file for wine to run correctly
    mv ./3.9 /opt/wine-3.9/
    echo PATH=/opt/wine-3.9/bin/:$PATH >> ~/.bashrc
    PATH=/opt/wine-3.9/bin/:$PATH
exit # exit the su account

sudo reboot # fixed the bus error?
#sudo systemctl restart systemd-binfmt # maybe just need to restart binfmt?

sudo chroot /home/pi/chroot-stretch-i386/ /bin/su -l pi # Only the user account can run wine (root account can't use exported display / “export DISPLAY=:0”)
    arch # should say i686
    mkdir ~/Downloads
	
    wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks # Install winetricks
    chmod +x winetricks 
    sudo mv winetricks /usr/local/bin
    sudo apt install -y cabextract # winetricks needs cabextract

		# Old PlayOnLinux wine install method (Novaspirit guide - libgnutls errors??)
		echo PATH=/opt/wine-3.9/bin/:$PATH >> ~/.bashrc
		PATH=/opt/wine-3.9/bin/:$PATH

    winecfg # "Bus error" may happen here (with qemu-user / qemu-user-static v1:3.1+dfsg-8+deb10u8 armhf & qemu-user / qemu-user-static v1:6.0.50 armhf). Try latest qemu and qemu-user-static binaries built from scratch (overwrite files in host's /usr/bin/ and the qemu-i386-static file in your chroot install) and rebooting.
exit # exit the user account
