# ============================================================
# ReTurn — Build APK release avec la bonne adresse backend
# Usage:
#   .\build_apk.ps1                          → IP Wi-Fi auto
#   .\build_apk.ps1 -ServerUrl http://192.168.1.55:8000
#   .\build_apk.ps1 -Install                 → installe aussi sur le téléphone USB
#   .\build_apk.ps1 -ServerUrl https://api.mon-serveur.com   → prod
# ============================================================

param(
    [string]$ServerUrl  = "",
    [switch]$Install,          # Installe l'APK via ADB après le build
    [switch]$SplitPerAbi       # Build un APK par architecture (plus léger)
)

Set-Location $PSScriptRoot

# ── Détection de l'IP Wi-Fi ──────────────────────────────────────────────────
if ($ServerUrl -eq "") {
    $ip = (
        Get-NetAdapter |
        Where-Object {
            $_.Status -eq 'Up' -and
            $_.InterfaceDescription -notmatch 'VMware|VirtualBox|Hyper-V|Loopback|Bluetooth|TAP|Tunnel'
        } |
        Sort-Object -Property { $_.Name -match 'Wi.?Fi|WLAN|Wireless' } -Descending |
        ForEach-Object {
            Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.IPAddress -notmatch '^(127\.|169\.254\.)' }
        } |
        Select-Object -First 1
    ).IPAddress

    if (-not $ip) {
        Write-Host "ERREUR: Impossible de détecter l'IP Wi-Fi." -ForegroundColor Red
        Write-Host "Utilisez: .\build_apk.ps1 -ServerUrl http://192.168.x.x:8000" -ForegroundColor Yellow
        exit 1
    }
    $ServerUrl = "http://${ip}:8000"
}

# ── Affichage de la config ────────────────────────────────────────────────────
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  ReTurn — Build APK release" -ForegroundColor White
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Backend  : $ServerUrl" -ForegroundColor Green
Write-Host "  OCR/IA   : géré par le backend (clé Mistral dans infra/.env)" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# ── Avertissement IP locale ───────────────────────────────────────────────────
if ($ServerUrl -match "^http://192\.|^http://10\.|^http://172\.") {
    Write-Host "ATTENTION : L'APK est compilé avec une IP locale ($ServerUrl)." -ForegroundColor Yellow
    Write-Host "Le téléphone DOIT être sur le même réseau Wi-Fi que ce PC." -ForegroundColor Yellow
    Write-Host "Si l'IP change (DHCP), rebuild l'APK." -ForegroundColor Yellow
    Write-Host ""
}

# ── Préconditions ─────────────────────────────────────────────────────────────
Write-Host "Préconditions :" -ForegroundColor Yellow
Write-Host "  1. Backend démarré  : cd infra && docker compose up -d" -ForegroundColor White
Write-Host "  2. Pare-feu Windows : port 8000 ouvert (voir ci-dessous si besoin)" -ForegroundColor White
if ($Install) {
    Write-Host "  3. Téléphone branché en USB avec débogage activé" -ForegroundColor White
}
Write-Host ""

# ── Construction des arguments dart-define ────────────────────────────────────
$defineArgs = @(
    "--dart-define=API_BASE_URL=$ServerUrl"
)

# ── Build ─────────────────────────────────────────────────────────────────────
Write-Host "Build en cours…" -ForegroundColor Cyan

if ($SplitPerAbi) {
    # 3 APK séparés : arm64-v8a (~15 Mo), armeabi-v7a (~14 Mo), x86_64 (~16 Mo)
    flutter build apk --release --split-per-abi @defineArgs
} else {
    # 1 APK universel (compatible tous téléphones, ~30–40 Mo)
    flutter build apk --release @defineArgs
}

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERREUR : Le build a échoué." -ForegroundColor Red
    exit 1
}

# ── Localisation de l'APK ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "  BUILD RÉUSSI" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

if ($SplitPerAbi) {
    $apkDir = "build\app\outputs\flutter-apk"
    Write-Host "APK générés dans : $apkDir" -ForegroundColor White
    Get-ChildItem "$apkDir\app-*-release.apk" | ForEach-Object {
        Write-Host "  $($_.Name)  ($([math]::Round($_.Length / 1MB, 1)) Mo)" -ForegroundColor Cyan
    }
    $apkPath = "$apkDir\app-arm64-v8a-release.apk"   # défaut pour l'install
} else {
    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    $sizeMb  = [math]::Round((Get-Item $apkPath).Length / 1MB, 1)
    Write-Host "APK : $apkPath  ($sizeMb Mo)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "  URL backend embarquée : $ServerUrl" -ForegroundColor White
Write-Host ""

# ── Installation ADB (optionnel) ──────────────────────────────────────────────
if ($Install) {
    Write-Host "Installation via ADB…" -ForegroundColor Cyan
    adb install -r $apkPath
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Installation réussie !" -ForegroundColor Green
    } else {
        Write-Host "ERREUR ADB. Vérifiez que le téléphone est branché et le débogage USB activé." -ForegroundColor Red
    }
} else {
    Write-Host "Pour installer manuellement :" -ForegroundColor Yellow
    Write-Host "  1. Copiez l'APK sur le téléphone (USB / Google Drive / WhatsApp…)" -ForegroundColor White
    Write-Host "  2. Sur le téléphone : Paramètres > Sécurité > Sources inconnues → Autoriser" -ForegroundColor White
    Write-Host "  3. Ouvrez le fichier APK sur le téléphone pour installer" -ForegroundColor White
    Write-Host ""
    Write-Host "Pour installer directement via USB :" -ForegroundColor Yellow
    Write-Host "  .\build_apk.ps1 -Install" -ForegroundColor White
}

$q = [char]34
Write-Host ""
Write-Host "-- Pare-feu Windows (si connexion refusee) ---------------------------------" -ForegroundColor DarkGray
Write-Host "  Executez en admin PowerShell :" -ForegroundColor DarkGray
Write-Host "  New-NetFirewallRule -DisplayName ${q}ReTurn Backend 8000${q} -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow" -ForegroundColor DarkGray
Write-Host ""
