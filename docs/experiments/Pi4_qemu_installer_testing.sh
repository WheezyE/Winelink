sudo apt-get install -y qemu qemu-user qemu-user-static binfmt-support debootstrap binutils debian-keyring debian-archive-keyring

# Now delete all /usr/bin/qemu*-static files
# Now copy all newly compiled qemu-user and qemu-user-static files to /usr/bin/

cd ~
sudo debootstrap --foreign --arch i386 stretch ./chroot-stretch-i386 http://ftp.us.debian.org/debian
sudo mount -t sysfs sys ./chroot-stretch-i386/sys/
sudo mount -t proc proc ./chroot-stretch-i386/proc/
sudo mount --bind /dev ./chroot-stretch-i386/dev/
sudo mount --bind /dev/pts ./chroot-stretch-i386/dev/pts/
sudo mount --bind /dev/shm ./chroot-stretch-i386/dev/shm/
	
sudo cp /usr/bin/qemu-i386-static ./chroot-stretch-i386/usr/bin/

sudo chroot ./chroot-stretch-i386/ /debootstrap/debootstrap --second-stage # unpack host system. takes about 15 minutes

sudo chroot /home/pi/chroot-stretch-i386/ /bin/su -l root # Set up root account
    arch # should say i686
    echo "export LANGUAGE='C'" >> ~/.bashrc #Add lines to bashrc, then initialize them too four our shell instance
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
    
    apt install -y expect # Install expect so that we can automate the user account installation
    chmod 666 /dev/ptmx
    chmod 755 /dev/pts
    mount -t devpts -o gid=5,mode=620 none /dev/pts
    
cat >~/setupusr.sh <<EOF
#!/usr/bin/expect -f
set force_conservative 0
set timeout -1
spawn adduser -uid 1000 pi # I think the uid number should be the same number as your non-chroot pi uid
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
exit

sudo chroot /home/pi/chroot-stretch-i386/ /bin/su -l pi # Set up user account
    arch # should say i686
    echo "export LANGUAGE='C'" >> ~/.bashrc #Add lines to bashrc, then initialize them too four our shell instance
    echo "export LC_ALL='C'" >> ~/.bashrc
    echo "export DISPLAY=:0" >> ~/.bashrc
    export LANGUAGE='C'
    export LC_ALL='C'
    export DISPLAY=:0
exit

sudo chroot /home/pi/chroot-stretch-i386/ /bin/su -l root # Log in as root to install wine
    # Old PlayOnLinux wine install method (Novaspirit guide)
    wget https://www.playonlinux.com/wine/binaries/linux-x86/PlayOnLinux-wine-3.9-linux-x86.pol
    tar -jxvf PlayOnLinux-wine-3.9-linux-x86.pol --strip-components=1
    mv ./3.9/bin/wine-preloader ./3.9/bin/wine-preloader.renamed # we need to rename a file for wine to run correctly
    mv ./3.9 /opt/wine-3.9/
    echo PATH=/opt/wine-3.9/bin/:$PATH >> ~/.bashrc
    PATH=/opt/wine-3.9/bin/:$PATH
exit

sudo reboot # fixed the bus error
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

    winecfg # "Bus error" may happen here (with qemu-user / qemu-user-static v1:3.1+dfsg-8+deb10u8 armhf & qemu-user / qemu-user-static v1:6.0.50 armhf). Try rebooting.
exit
