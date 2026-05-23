@echo off
:: ============================================================
:: ReTurn — Lancer l'app sur téléphone physique
:: Détecte automatiquement l'IP locale du PC (Wi-Fi ou Ethernet)
:: Usage: double-cliquer ou lancer depuis PowerShell/CMD
:: ============================================================

:: Récupérer l'IP locale (première interface non-loopback)
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4" ^| findstr /v "127.0.0.1"') do (
    set LOCAL_IP=%%a
    goto :found
)

:found
:: Nettoyer les espaces
set LOCAL_IP=%LOCAL_IP: =%

if "%LOCAL_IP%"=="" (
    echo ERREUR: Impossible de détecter l'IP locale.
    echo Vérifiez que vous êtes connecté au Wi-Fi ou Ethernet.
    pause
    exit /b 1
)

echo.
echo ====================================================
echo  IP détectée : %LOCAL_IP%
echo  URL backend : http://%LOCAL_IP%:8000
echo ====================================================
echo.
echo Assurez-vous que :
echo  1. Le backend tourne (docker compose up)
echo  2. Le téléphone est sur le MÊME réseau Wi-Fi que ce PC
echo  3. Le téléphone est branché en USB ou en mode débogage Wi-Fi
echo.
echo Lancement de flutter run...
echo.

cd /d "%~dp0"
flutter run --dart-define=API_BASE_URL=http://%LOCAL_IP%:8000 %*
