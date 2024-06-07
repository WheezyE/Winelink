w_metadata winemono apps \
    title="wine-mono installer" \
    publisher="WineHQ, madewokherd" \
    year="2024" \
    media="download" \
    conflicts="dotnet11 dotnet11sp1 dotnet20 dotnet20sdk dotnet20sp1 dotnet20sp2 dotnet30 dotnet30sp1 dotnet35 dotnet35sp1 dotnet40 dotnet40_kb2468871 dotnet45 dotnet452 dotnet46 dotnet462 dotnet461 dotnet471 dotnet472 dotnet48 dotnet_verifier" \
    installed_file1="${W_WINDIR_WIN}/mono/mono-2.0/bin/libmono-2.0-x86.dll" \
    homepage="https://github.com/madewokherd/wine-mono"

load_winemono()
{
    # Look for registry keys
    ${WINE} reg query "HKLM\\Software\\Microsoft\\.NETFramework\\Policy" 1>/dev/null # check for wine-mono/dotnet48- regkeys (dotnet5+/dotnetcore don't store regkeys here)
    regquery_dnbelow5=$? # 0 = found regkeys; 1 = no regkeys (or wine crashed while searching)
    ${WINE} reg query "HKCU\\Software\\Wine\\Mono" 1>/dev/null # check if a user created a custom wine-mono installation. This is not a default regkey when wine-mono is installed
    regquery_customwinemono=$? # 0 = found regkeys; 1 = no regkeys (or wine crashed while searching)
    # Note: Can't use winetricks w_try here since we are counting on an error code being returned.
    
    # Cancel installation if .NET or wine-mono are already installed
    if [ -d "${W_WINDIR_UNIX}/mono/mono-2.0" ] || [ -d "${WINEPREFIX}/share/wine/mono/wine-mono-5.0.0" ] || [ -d "/usr/local/share/wine/mono/wine-mono-5.0.0" ] || [ -d "/usr/share/wine/mono/wine-mono-5.0.0" ] || [ -d "/opt/wine/mono/wine-mono-5.0.0" ] || [ $regquery_customwinemono -eq 0 ]; then
        w_die "Wine-mono is already installed. Cancelling installation."
    elif [ $regquery_dnbelow5 -eq 0 ]; then
        w_die "Please remove any installations .NET Framework 4.8 or earlier. To run Wine's \"Add/Remove Programs\" menu, type:\nwine uninstaller\n\nCancelling installation."
        # Note: Simply checking for "${W_WINDIR_UNIX}/Microsoft.NET/Framework/" doesn't work here since dotnet uninstallers often leave files behind.
    fi

    # Auto-install any cached wine-mono*.msi files silenty, or use AHK to silently press "Wine Mono Installer" install button, or run "Wine Mono Installer" for user
    if [ -f "$HOME/.cache/wine/wine-mono*.msi" ] || [ -f "/usr/share/wine/mono/wine-mono*.msi" ] || [ -f "/opt/wine/mono/wine-mono*.msi" ]; then
        w_try "${WINE}" control.exe appwiz.cpl install_mono # launch Wine's Wine Mono Installer
        # Note: Wine Mono Installer will auto-install a cached wine-mono*.msi if it is in any of these directories (ignores .tar.gz / .tar.xz files).
    elif [ ${W_OPT_UNATTENDED} ]; then
        w_ahk_do "
            ; AutoHotKey script to push the Install button on the Wine Mono Installer window.
            SetTitleMatchMode, 2
            Run, control.exe appwiz.cpl install_mono, C:\windows\System32
            WinWait, Wine Mono Installer,, 8
            if ErrorLevel
            {
                MsgBox, 0, Warning, AutoHotKey could not find the Wine Mono Installer window.`n`nYou might have to install wine-mono manually., 5
                return
            }
            ControlClick, Button1, Wine Mono Installer ; Click the OK button
            WinWaitClose
        "
    else
        # For regular install, run the "Wine Mono Installer" and let the user click the "Install" button
        w_try "${WINE}" control.exe appwiz.cpl install_mono # launch Wine's Wine Mono Installer
    fi
}
