# ============================================================
# ReTurn - Lancer l'app sur telephone physique (PowerShell)
# Usage: .\run_device.ps1
#        .\run_device.ps1 -Release          (build release)
#        .\run_device.ps1 -ServerUrl https://api.monserveur.com
#        .\run_device.ps1 -FirebaseLog      (diagnostic erreurs natives Firebase)
# ============================================================

param(
    [string]$ServerUrl    = "",
    # Client ID Google (type Web) pour Google Sign-In — surchargable :
    #   .\run_device.ps1 -GoogleClientId "xxxx.apps.googleusercontent.com"
    [string]$GoogleClientId = "774092129161-ed0d2cs235cccvbsu506ikdiehktpko7.apps.googleusercontent.com",
    [switch]$Release,
    [switch]$FirebaseLog
)

Set-Location $PSScriptRoot
# Evite le mojibake (accents) dans la console
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

# Diagnostic : extrait l'erreur native Firebase du buffer logcat existant.
# Procedure : 1) lance l'app et reproduis l'erreur ; 2) lance ce mode.
# (On NE vide PAS le buffer : l'erreur de demarrage doit rester lisible.)
if ($FirebaseLog) {
    Write-Host "Extraction des erreurs natives (firebase / plugins)..." -ForegroundColor Cyan
    Write-Host "Si vide : relance l'app PUIS relance cette commande." -ForegroundColor DarkGray
    Write-Host "------------------------------------------------" -ForegroundColor DarkGray
    adb logcat -d -v brief |
        Select-String -Pattern "firebase|Firebase|FLTFire|GeneratedPluginRegistrant|Pigeon|NoClassDef|ClassNotFound|dlopen|registering plugin|AndroidRuntime"
    Write-Host "------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "Copie les lignes ci-dessus (surtout celles en 'E')." -ForegroundColor Yellow
    exit 0
}

# Detect local IP if no URL given
if ($ServerUrl -eq "") {
    # 1. Priorité : adaptateur Wi-Fi actif (exclut VMware, VirtualBox, Hyper-V, loopback)
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
        Write-Host "ERREUR: Impossible de detecter l'IP Wi-Fi." -ForegroundColor Red
        Write-Host "Utilisez: .\run_device.ps1 -ServerUrl http://192.168.x.x:8000" -ForegroundColor Yellow
        exit 1
    }
    $ServerUrl = "http://${ip}:8000"
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " URL backend : $ServerUrl" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " OCR/IA      : gere par le backend (cle Mistral cote serveur)" -ForegroundColor Green
Write-Host "               -> MISTRAL_API_KEY doit etre dans infra/.env" -ForegroundColor DarkGray
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Preconditions :" -ForegroundColor Yellow
Write-Host "  1. Backend demarre : cd infra ; docker compose up -d" -ForegroundColor White
Write-Host "  2. Telephone sur le meme reseau Wi-Fi que ce PC" -ForegroundColor White
Write-Host "  3. Debogage USB active sur le telephone" -ForegroundColor White
Write-Host "  Astuce: en cas d'erreur Firebase, ouvre un 2e terminal et lance" -ForegroundColor DarkGray
Write-Host "          .\run_device.ps1 -FirebaseLog" -ForegroundColor DarkGray
Write-Host ""

$defineArgs = @(
    "--dart-define=API_BASE_URL=$ServerUrl",
    "--dart-define=GOOGLE_SERVER_CLIENT_ID=$GoogleClientId"
)
$modeArgs = if ($Release) { @("--release") } else { @() }

flutter run @defineArgs @modeArgs $args
