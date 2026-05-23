# ============================================================
# ReTurn — Lancer l'app sur téléphone physique (PowerShell)
# Usage: .\run_device.ps1
#        .\run_device.ps1 --release          (build release)
#        .\run_device.ps1 -ServerUrl https://api.monserveur.com
# ============================================================

param(
    [string]$ServerUrl = "",
    [switch]$Release
)

Set-Location $PSScriptRoot

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
Write-Host "Préconditions :" -ForegroundColor Yellow
Write-Host "  1. Backend démarré : docker compose up -d" -ForegroundColor White
Write-Host "  2. Téléphone sur le même réseau Wi-Fi que ce PC" -ForegroundColor White
Write-Host "  3. Débogage USB activé sur le téléphone" -ForegroundColor White
Write-Host ""

$defineArg = "--dart-define=API_BASE_URL=$ServerUrl"
$modeArgs  = if ($Release) { @("--release") } else { @() }

flutter run $defineArg @modeArgs $args
