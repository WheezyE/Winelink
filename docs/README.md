![logo](WinelinkLogo.png "Project logo")
# Winelink
A [Winlink](http://winlink.org/) (RMS Express & VARA) installer Script for the Raspberry Pi 4.

This script will help you install Box86, Wine, winetricks, Windows DLL's, RMS Express, & VARA.  You will then be prompted to configure RMS Express & VARA to send/receive audio from a USB sound card plugged into your Pi.  This installer will only work on the Raspberry Pi 4B for now (support for earlier Raspberry Pi models is planned for later).

**_This project is still very early in development. It still has lots of bugs which cause frequent crashes in RMS Express. Stability should improve later._**

To run Windows .exe files on RPi4 (ARM/Linux), we need an x86 emulator ([Box86](https://github.com/ptitSeb/box86)) and a Windows API Call interpreter ([Wine](https://github.com/wine-mirror/wine)).  Box86 is open-source and runs about 10x faster than [ExaGear](https://www.huaweicloud.com/kunpeng/software/exagear.html) or [Qemu](https://github.com/qemu/qemu).  ExaGear is also closed source abandonware and Qemu (qemu-system & qemu-user-static) also has issues running more complex Wine programs on the Pi.  Box86 is much smaller in file size and much easier to install too.

## Installation
Simply copy and paste these commands into your Raspberry Pi 4's terminal:
```bash
wget https://raw.githubusercontent.com/WheezyE/Winelink/main/install_winelink.sh && \
     bash install_winelink.sh
```
_Installation takes about 70 minutes and lots of errors will appear in the terminal (just ignore those)._

You should then be able to run RMS Express and VARA from desktop shortcuts.  They will probably crash often when you try to load them or use them.  If you run them enough times though, they should run and send/receive tones.

If you would like to install this software on an older Raspberry Pi (3B+, 3B, 2B, Zero, for example), Winlink may run very slow (and you will need to compile a custom 2G/2G split memory kernel by yourself before installing - auto-detection/installation of a custom kernel is planned for a future release of this script).

## Known issues
 - VARA's CPU gauge doesn't display (this is a bug in Wine).
 - The installation takes about 70 minutes.
 - If you get crashes when running RMS Express, just keep re-running RMS Express until it doesn't crash anymore.  This installer will also create a script on the desktop to reset Wine in case programs freeze or won't open.
 - I haven't actually tested over-the-air connections yet since I'm still just a tech.  If some generals could test, that would be awesome.

## Examples

![VARA-Pi4](VARA-Pi4.png "VARA running on a Raspberry Pi 4B (Twister OS)")
VARA running on a Raspberry Pi 4B (Twister OS)
    
## Credits
 - [The Box86 team](https://discord.gg/Fh8sjmu)
>      (ptitSeb, pale, chills340, Ita-Nelken, Heasterian, phoenixbyrd, Icenowy, Longhorn,
>       SpacingBat3, monkaBlyat, Botspot, epychan, !FlameKat53, #lukefrenner,
>       luschia, #MonthlyDoseOfRPi, Binay Devkota, hacker420, et.al.)
 - [K6ETA](http://k6eta.com/linux/installing-rms-express-on-linux-with-wine) & [DCJ21](https://dcj21net.wordpress.com/2016/06/17/install-rms-express-linux/)'s 'Winlink on Linux' guides
 - [KM4ACK](https://github.com/km4ack/pi-build) & OH8STN for inspiration
 - N7ACW & AD7HE for getting me started in ham radio

         "My humanity is bound up in yours, for we can only be human together"
                                                     - Nelson Mandela

## Legal
All software used by this script is free and legal to use (with the exception of VARA, of course, which is shareware).  Box86, Wine, winetricks, and AutoHotKey, are all open-source (which avoids the legal problems of use & distribution that ExaGear had - ExaGear also ran much slower than Box86 and is no-longer maintained, despite what Huawei says these days).  All proprietary Windows DLL files required by Wine are downloaded directly from Microsoft and installed according to their redistribution guidelines.  Raspberry Pi is a trademark of the Raspberry Pi Foundation

## Future work
 - [ ] Find Box86 [stability bugs for Winlink](https://github.com/ptitSeb/box86/issues/217) (and ask ptitSeb very nicely if he can fix them).
   - Eliminate need for downgrading Box86 to install dotnet & upgrading Box86 to run Winlink.
   - Find crashes.
 - [ ] Work with Seb to find/fix dotnet35sp1 installation issues (improve installation speed).
 - [x] Make a logo for the github page.
 - [ ] Add updated example images
 - [ ] Add installer for VARA FM.
 - [x] Make the script's user-interface look better.
 - [x] Add an AHK script to click the "Ok" button after VARA is installed.
 - [x] Add an AHK script to help the user with VARA first time soundcard setup.
 - [x] Add more clean-up functions to the script.
 - [x] Have the script download all files into the cloned repository directory (instead of into ~/Downloads)
 - [x] Add shortcuts to the desktop
 - [x] Rely on [archive.org box86 binaries](https://archive.org/details/box86.7z_20200928) instead of compiling (give user the choice to compile or not; add auto-detection of failed downloads)
 - [x] Work with the Wine team to find [graphical errors in VARA](https://forum.winehq.org/viewtopic.php?f=8&t=34910).
 - [x] Add the fix for VARA graphical errors to the script
    - [x] Re-fix the VARA graphics errors using a different method ([winecfg reg keys](https://wiki.winehq.org/index.php?title=Useful_Registry_Keys&highlight=%28registry%29))
 - [ ] Work with the Wine team to [figure out why VARA's CPU gauge isn't working](https://bugs.winehq.org/show_bug.cgi?id=50728).
 - [x] Add pdhNT4 to [winetricks](https://github.com/Winetricks/winetricks) to streamline this installer.
 - [ ] Consider adding Winlink & VARA installers to winetricks to further streamline this installer (improve readability, make Winlink easier to install for other x86 winetricks users who are not aware of this project).
 - [ ] Add more error-checking to the script.
 - [x] Make code modular to help readability.
 - [x] Simplify installation commands (model after KM4ACK BAP).
 #### Add more platforms
 - [ ] Add detection of Raspberry Pi kernel memory split (and install the correct kernel if needed) for RPi 2-3 support.
   - Ask Botspot if I can borrow some of his [pi-apps code](https://github.com/Botspot/pi-apps/blob/4a48ba62b157420c6e33666e7d050ee3ce21ab0b/apps/Wine%20(x86)/install-32#L165).
 - [ ] Expand this script to detect/include Android ([Termux](https://github.com/termux/termux-app) + [proot-distro](https://github.com/termux/proot-distro) + Ubuntu ARM + [termux-usb](https://wiki.termux.com/wiki/Termux-usb)).
 - [ ] Expand this script to detect/include x86 Linux.
 - [ ] Expand this script to detect/include Mac.
 - [ ] Expand this script to detect/include ChromeBook Linux beta.

## Distribution
If you use this script in your project (or are inspired by it) just please be sure to mention ptitSeb, Box86, and myself (KI7POL).  This script is free to use, open-source, and should not be monetized (for further information see the [license file](LICENSE)).

## Donations
If you feel that you are able and would like to support this project, please consider sending donations to ptitSeb or KM4ACK - without whom, this script would not exist.
 - Sebastien "ptitSeb" Chevalier (author of [Box86](https://github.com/ptitSeb/box86), incredible developer, & really nice guy) [paypal.me/0ptitSeb](paypal.me/0ptitSeb)
 - Jason "KM4ACK" Oleham (author of [Build-a-Pi](https://github.com/km4ack/pi-build), Linux elmer, & ham radio pioneer) [paypal.me/km4ack](paypal.me/km4ack)
