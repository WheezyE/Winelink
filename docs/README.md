![logo](WinelinkLogo.png "logo")
# Winelink
A script to install Winlink (RMS Express & VARA) on Raspberry Pi 4

# Future work
1. Find Box86 stability bugs for Winlink & dotnet35sp1 (and ask ptitSeb very nicely if he can fix them).
 - Address internet issues.
 - Eliminate need for downgrading Box86 to install dotnet & upgrading Box86 to run Winlink.
 - Find crashes.
2. Add detection of Raspberry Pi kernel memory split (and install the correct kernel if needed) for RPi 2-3 support.
 - Ask Botspot if I can borrow some of his [pi-apps](https://github.com/Botspot/pi-apps) code.
3. Expand this script to include Android ([Termux](https://github.com/termux/termux-app) + [proot-distro](https://github.com/termux/proot-distro) + Ubuntu ARM + [termux-usb](https://wiki.termux.com/wiki/Termux-usb)), x86 Linux, Mac, and ChromeBook Linux beta.
4. Add more error-checking.
5. Work with the [Wine](https://github.com/wine-mirror/wine) team to fix graphical errors in VARA.
6. Add pdhNT4 to [winetricks](https://github.com/Winetricks/winetricks) to streamline this installer.
7. Add more clean-up functions to the script.

# Credits
 - This project relies heavily on [Box86](https://github.com/ptitSeb/box86) to allow Winlink to run on ARM devices.
 - I was inspired by the work of KM4ACK's [Build-A-Pi](https://github.com/km4ack/pi-build) installer for ham radio operators.
 - I initially set out on this journey to miniaturize and consolodate the giant, clunky, expensive, hardware modems ("TNC's") of old after watching OH8STN's YouTube videos.
