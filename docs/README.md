![logo](WinelinkLogo.png "logo")
# Winelink
A Winlink (RMS Express & VARA) installer Script for the Raspberry Pi 4.

To run Windows .exe files on RPi4 (ARM/Linux), we need an x86 emulator ([box86](https://github.com/ptitSeb/box86)) and a Windows API Call interpreter ([Wine](https://github.com/wine-mirror/wine)).  Box86 is opensource and runs about 10x faster than ExaGear or Qemu.  It's much smaller and easier to install too.

This script will help you install Box86, Wine, winetricks, Windows DLL's, Winlink (RMS Express) & VARA.  You will then be prompted to configure RMS Express & VARA to send/receive audio from a USB sound card plugged into your Pi.  This installer will only work on the Raspberry Pi 4B for now.  If you would like to use an older Raspberry Pi (3B+, 3B, 2B, Zero, for example), software may run very slow and you may need to compile a custom 2G/2G split memory kernel before installing.
    
## Credits
 - The Box86 team
>      (ptitSeb, pale, chills340, phoenixbyrd, Botspot, !FlameKat53, epychan,
>       Heasterian, monkaBlyat, SpacingBat3, #lukefrenner, Icenowy, Longhorn,
>       #MonthlyDoseOfRPi, luschia, Binay Devkota, hacker420, et.al.)
 - [K6ETA](http://k6eta.com/linux/installing-rms-express-on-linux-with-wine) & [DCJ21](https://dcj21net.wordpress.com/2016/06/17/install-rms-express-linux/)'s Winlink on Linux guides
 - [KM4ACK](https://github.com/km4ack/pi-build) & OH8STN for inspiration
 - N7ACW & AD7HE for getting me started in ham radio
 - Raspberry Pi is a trademark of the Raspberry Pi Foundation

         "My humanity is bound up in yours, for we can only be human together"
                                                     - Nelson Mandela

## Distribution
    This script is free to use, open-source, and should not be monetized.  If you use this script in your project (or are inspired by it) just please be sure to mention ptitSeb, Box86, and myself (KI7POL).

## Legal
    All software used by this script is free and legal to use (with the exception of VARA, of course, which is shareware).  Box86 and Wine are both open-source (which avoids the legal problems of use & distribution that ExaGear had - ExaGear also ran much slower than Box86 and is no-longer maintained, despite what Huawei says these days).  All proprietary Windows DLL files required by Wine are downloaded directly from Microsoft and installed according to their redistribution guidelines.

## Future work
 - [ ] Find Box86 stability bugs for Winlink & dotnet35sp1 (and ask ptitSeb very nicely if he can fix them).
   - Address internet issues.
   - Eliminate need for downgrading Box86 to install dotnet & upgrading Box86 to run Winlink.
   - Find crashes.
 - [ ] Add detection of Raspberry Pi kernel memory split (and install the correct kernel if needed) for RPi 2-3 support.
   - Ask Botspot if I can borrow some of his [pi-apps](https://github.com/Botspot/pi-apps) code.
 - [ ] Expand this script to include Android ([Termux](https://github.com/termux/termux-app) + [proot-distro](https://github.com/termux/proot-distro) + Ubuntu ARM + [termux-usb](https://wiki.termux.com/wiki/Termux-usb)), x86 Linux, Mac, and ChromeBook Linux beta.
 - [ ] Add more error-checking.
 - [ ] Work with the Wine team to fix graphical errors in VARA.
 - [ ] Add pdhNT4 to [winetricks](https://github.com/Winetricks/winetricks) to streamline this installer.
 - [ ] Add more clean-up functions to the script.
 - [x] Make a logo for the github page


## Donations
If you feel that you are able and would like to support this project, please consider sending donations to ptitSeb or KM4ACK - without whom, this script would not exist.
 - Sebastien "ptitSeb" Chevalier (author of [box86](https://github.com/ptitSeb/box86)) [paypal.me/0ptitSeb]
 - Jason "KM4ACK" Oleham (Linux elmer & ham radio pioneer) [paypal.me/km4ack]
