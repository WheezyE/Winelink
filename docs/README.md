![logo](WinelinkLogo.png "Project logo")
# Winɘlink
A [Winlink](http://winlink.org/) (RMS Express & VARA) installer Script for the Raspberry Pi 4, Orange Pi 4 LTS, and x86/x64 Linux (Mint/Ubuntu/Debian).  Raspberry Pi 3B+ also kind of works.

_This project has lots of bugs and should be considered [alpha](https://en.wikipedia.org/wiki/Software_release_life_cycle#Alpha) software._

------------------------
![Winlink-Pi4](Winlink-Pi4.gif)
_RMS Express/Trimode & VARA running on a Raspberry Pi 4B (RPiOS) [video sped-up]_

------------------------
![VARA-Pi4](VARA-Pi4.png "VARA running on a Raspberry Pi 4B (Twister OS)")
_VARA running on a Raspberry Pi 4B (Twister OS)_

------------------------

## Installation
Copy/paste these commands into your Raspberry Pi 4's terminal:
```bash
curl -O https://raw.githubusercontent.com/WheezyE/Winelink/main/install_winelink.sh && \
     bash install_winelink.sh
```
###### _If desired, you can tell the script to only install VARA by running `curl -O https://raw.githubusercontent.com/WheezyE/Winelink/main/install_winelink.sh && bash install_winelink.sh vara_only`_

## Known issues
 - _RMS Express sometimes won't connect (over TCP) to ARDOP & VARA. Just close RMS Express and re-open it (this is a bug in wine)._
 - _VARA's CPU gauge doesn't display (this is a bug in wine)._
 - _VARA doesn't connect to DRA boards at this time (this might be a bug in wine or box86)._
 - _Wine can sometimes freeze your OS completely if it gets overloaded. If this happens on a Raspberry Pi, you can SSH into the Pi and then run `wineserver -k` to force-quit Wine. You can also just power-off/on your system._
 - _Enabling VARA HF's waterfall display can sometimes crash RMS Express & VARA._
 - _Enabling VARA's Monitor Mode can freeze VARA. (Users might have to delete their VARA config file to recover: `rm ~/.wine/drive_c/VARA/VARA.ini`)_

## Credits
 - [ptitSeb](https://github.com/ptitSeb/box86) for box86 (& everyone on [the TwisterOS discord](https://discord.gg/Fh8sjmu))
>      (ptitSeb, pale, chills340, Itai-Nelken, Heasterian, phoenixbyrd,
>       monkaBlyat, lowspecman420, epychan, !FlameKat53, #lukefrenner,
>       icecream95, SpacingBat3, Botspot, Icenowy, Longhorn, et.al.)

 - [madewokherd](https://github.com/madewokherd/wine-mono) (Esme) for wine-mono debugging
 - [Botspot](https://github.com/Botspot/) for their RPi3 kernel switching code
 - N7ACW, AD7HE, & KK6FVG for getting me started in ham radio
 - [KM4ACK](https://github.com/km4ack/pi-build) & [OH8STN](https://oh8stn.org/) for inspiration
 - [K6ETA](http://k6eta.com/linux/installing-rms-express-on-linux-with-wine) & [DCJ21](https://dcj21net.wordpress.com/2016/06/17/install-rms-express-linux/)'s 'Winlink on Linux' guides for early proof-of-concept

         "My humanity is bound up in yours, for we can only be human together"
                                                     - Nelson Mandela


## Donations
If you feel that you are able and would like to support this project, please consider sending donations to ptitSeb, madewokherd (CodeWeavers/WineHQ), or KM4ACK - without whom, this script would not exist.
 - Sebastien "ptitSeb" Chevalier (author of [Box86](https://github.com/ptitSeb/box86), incredible developer, & really nice guy) [paypal.me/0ptitSeb](paypal.me/0ptitSeb)
 - Madewokherd (author of [wine-mono](https://github.com/madewokherd/wine-mono) & wonderful person) [https://www.winehq.org/donate](https://www.winehq.org/donate)
 - Jason "KM4ACK" Oleham (author of [Build-a-Pi](https://github.com/km4ack/pi-build), Linux elmer, & ham radio pioneer) [paypal.me/km4ack](paypal.me/km4ack)

## Stuff for nerds
<details><summary>How it works</summary>

This script will help you install Box86, Wine, winetricks, Windows DLL's, RMS Express, & VARA.  You will then be prompted to configure RMS Express & VARA to send/receive audio from a USB sound card plugged into your Pi.  This installer will only work on the Raspberry Pi 4B for now (support for earlier Raspberry Pi models is planned for later).

To run Windows .exe files on RPi4 (ARM/Linux), we need an x86 emulator ([Box86](https://github.com/ptitSeb/box86)) and a Windows API Call interpreter ([Wine](https://github.com/wine-mirror/wine)).  Box86 is open-source and runs about 5x faster than [ExaGear](https://www.huaweicloud.com/kunpeng/software/exagear.html)/[Qemu](https://github.com/qemu/qemu) (see [these benchmarks](https://box86.org/2022/03/box86-box64-vs-qemu-vs-fex-vs-rosetta2/)).  ExaGear is also closed source abandonware and Qemu (qemu-system & qemu-user-static) also has issues running more complex Wine programs on the Pi.  Box86 is much smaller in file size and much easier to install too.
</details>

<details><summary>Distribution</summary>

If you use this script in your project (or are inspired by it) just please be sure to mention ptitSeb, Box86, and myself (KI7POL).  This script is free to use, open-source, and should not be monetized (for further information see the [license file](LICENSE)).
</details>

<details><summary>Future Work: Roadmap</summary>

 - [ ] Add an AHK script to help the user with ARDOP first time soundcard setup.
 - [ ] Time all individual components and embed comments in functions for Pi models. Add variable timer to welcome screen.
 - [ ] Help DRA-board compatability with VARA ([might be a box86 issue?](https://github.com/ptitSeb/box86/issues/567))
 - [ ] Consider adding a sed script to find/delete any small-value frequencies in `RMS Channels.dat` that would crash the HF Channel Selection Browser
 - [ ] Clean up code with [Google style guide](https://google.github.io/styleguide/shellguide.html).
 - [ ] Work with WineHQ to [figure out why VARA's CPU gauge isn't working](https://bugs.winehq.org/show_bug.cgi?id=50728).
 - [ ] Work with WineHQ to [figure out why ARDOP & VARA don't always connect to RMS Express over TCP when first starting](https://bugs.winehq.org/show_bug.cgi?id=52521).
 - [ ] Add progress bar (GUI?) for installation.
 - [x] Add HDD-space check to make sure user has enough space to install everything
 - [x] Switch to using Seb's GitHub box86 binaries (or hosted box86 bins) instead of Pale's internet archive binaries.
 - [x] Bisect box86 commits that crash VARA's local TCP to RMS connection (bug in newer box86's)
 - [x] Add updated example images to readme.
 - [x] Rely on [archive.org box86 binaries](https://archive.org/details/box86.7z_20200928) instead of compiling.
    - [ ] Give user the choice to compile or not.
    - [ ] Add auto-detection of failed downloads, then switch to compiling as contingency.
 - [x] Separate soundcard setups from program installations. Make a script for that.
 - [x] Make an uninstaller script
 - [x] Put program scripts and icons into start menu instead of on desktop.
 - [x] Test COM port connections to radio ("CAT" control, PTT).
 - [x] Work with madewokherd to see if wine-mono bugs can be fixed (would drastically improve install speed).
    - [x] [ARDOP TCP/IP Connection issues](https://github.com/madewokherd/wine-mono/issues/116).
    - [x] [Message creation issues](https://github.com/madewokherd/wine-mono/issues/122).
    - [x] [Message receive issues](https://github.com/madewokherd/wine-mono/issues/122#issuecomment-962525136).
    - [x] [HF Channel Selection Browser crash](https://github.com/WheezyE/Winelink/issues/16) (from small-value input frequencies).
    - [x] [COM port connection issues to radios/TNC's](https://github.com/WheezyE/Winelink/issues/17).
 - [x] Ask Seb for help getting VARA Chat running in box86.
 - [x] Add option (or check) for running the script via SSH (currently ssh causes wine to not display Windows) - Fixed with X11 check.
 - [x] Add installer for VARA FM.
 - [x] Add installer for VARA SAT.
 - [x] Add a check for sudo priviledges? Add a check to make sure script is not run as sudo?
 - [x] Change VARA Setup/Config terminal text prompts into zenity pop-up boxes.
    - [x] Change all terminal text prompts into text boxes?
 - [x] Add more error-checking to the script.
 - [x] Make a logo for the github page.
 - [x] Make the script's user-interface look better.
 - [x] Add an AHK script to click the "Ok" button after VARA is installed.
 - [x] Add an AHK script to help the user with VARA first time soundcard setup.
 - [x] Add more clean-up functions to the script.
 - [x] Have the script download all files into the cloned repository directory (instead of into ~/Downloads)
 - [x] Add shortcuts to the desktop.
 - [x] Work with the Wine team to find [graphical errors in VARA](https://forum.winehq.org/viewtopic.php?f=8&t=34910).
 - [x] Add the fix for VARA graphical errors to the script.
    - [x] Re-fix the VARA graphics errors using a different method ([winecfg reg keys](https://wiki.winehq.org/index.php?title=Useful_Registry_Keys&highlight=%28registry%29)).
  - [x] Add pdhNT4 to [winetricks](https://github.com/Winetricks/winetricks) to streamline this installer.
  - [x] Make code modular to help readability.
 - [x] Simplify installation commands (model after KM4ACK BAP).
</details>

<details><summary>Future work: More platforms</summary>
     
Make a multi-platform [Wine](https://wiki.winehq.org/Download) installer & build/invoke box86 if needed. ([Linode](https://www.linode.com/company/about/#row--about) may be helpful here)
     
 - [x] Auto-detection of system arch (x86 vs armhf vs aarch64) & OS.
    - ARM
      - [x] Raspberry Pi 4B (32-bit OS)
      - [x] Raspberry Pi 4B (64-bit OS)
      - [x] Raspberry Pi 3B+
        - [x] Detect Raspberry Pi kernel memory split (and install the correct kernel if needed) for RPi <4 support.
        - [x] Ask Botspot if I can borrow some of his [pi-apps code](https://github.com/Botspot/pi-apps/blob/4a48ba62b157420c6e33666e7d050ee3ce21ab0b/apps/Wine%20(x86)/install-32#L165).
      - [ ] RPi Zero 2 W?
      - [ ] RPi Zero W?
      - [ ] [Termux](https://github.com/termux/termux-app) (Android without root) ([proot-distro](https://github.com/termux/proot-distro) + Ubuntu ARM + [termux-usb](https://wiki.termux.com/wiki/Termux-usb)) - see [AnBox86](https://github.com/lowspecman420/AnBox86) for proof of concept, currently untested with VARA.
      - [ ] Mac M1 processors
    - x86
      - Mac
        - [ ] OSX?
      - Linux (top priorities are distros that WineHQ hosts binaries for: Ubuntu, Debian, Fedora, macOS, SUSE, Slackware, and FreeBSD)
        - [ ] Ubuntu (Package manager: apt)
          - [ ] Linux Mint
          - [ ] Elementary OS
          - [ ] Zorin OS
        - [ ] Debian (Package manager: apt)
          - [ ] Deepin
          - [ ] Kali
          - [ ] MX-Linux
        - [ ] Red Hat (Package manager: yum, RPM)
          - [ ] Fedora (Package manager: RPM/DNF)
          - [ ] CentOS (Package manager: yum)
        - [ ] openSUSE (Package manager: ZYpp (standard); YaST (front-end); RPM (low-level))
        - [ ] Slackware (Package manager: pkgtool, slackpkg)
        - [ ] FreeBSD (Package manager: pkg)
        - [ ] Arch (Package manager: pacman, libalpm)
          - [ ] Vanilla Arch??
          - [ ] Manjaro
          - [ ] XeroLinux
          - [ ] SteamOS? (Steam Deck)
        - [ ] Gentoo (Package manager: Portage)
        - [ ] Solus (Package manager: eopkg)
      - [ ] ChromeBook Linux beta.
        - [ ] Try to detect if processor would be too slow?
    - x64
      - Linux (top priorities are distros that WineHQ hosts binaries for: Ubuntu, Debian, Fedora, macOS, SUSE, Slackware, and FreeBSD)
        - [x] Linux Mint (Ubuntu)
        - [x] Debian 11
 - [ ] Make a youtube video showcasing current methods (box86, Exagear issues, qemu-user-static errors, Pi4B, Pi3B+, Termux, Mac, Linux, ChromeOS)
</details>
     
<details><summary>Android testing notes</summary>

Termux/PRoot/AnBox86_64

 - [ ] Try using [BT/USB/TCP Bridge Pro](https://play.google.com/store/apps/details?id=masar.bluetoothbridge.pro) to connect USB devices to RMS Express (credits: Torsten, DL1THM / [harenber](https://github.com/harenber/ptc-go/wiki/Android))
 - [ ] Create alpha version of Winelink for AnBox86_64
 - [ ] Speed benchmarks with different devices (Fire HD10 Tablet is a bit slow, Retroid Pocket 2 TBD)
 - [ ] ~See if termux-usb can be adapted somehow to allow connections without root?~
 - [ ] See if [a python wrapper](https://github.com/Querela/termux-usb-python/issues/4) could be written for TermuxUSB-OTG-USB connections between RMS Express & FT-891.
 - [x] OTG-USB-CAT (order OTG_USB_C-USB)
 - [x] Audio in/out (ARDOP works with alsa / hiccups with pulseaudio)
 - [x] [Proof-of-concept](https://www.youtube.com/watch?v=FkeP_IW3GGQ&t=29s)
 - [x] Fix AnBox86
     
</details>
     
<details><summary>Legal</summary>

All software used by this script is free and legal to use (with the exception of VARA, of course, which is shareware).  Box86, Wine, wine-mono, winetricks, and AutoHotKey, are all open-source (which avoids the legal problems of use & distribution that ExaGear had - ExaGear also ran much slower than Box86 and is no-longer maintained, despite what Huawei says these days).  All proprietary Windows DLL files required by Wine are downloaded directly from Microsoft and installed according to their redistribution guidelines.  Raspberry Pi is a trademark of the Raspberry Pi Foundation
</details>
