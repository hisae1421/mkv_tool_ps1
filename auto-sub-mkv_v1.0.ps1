# 01/2026 - beta
# Script interactif pour gérer les pistes MKV avec installation automatique de MKVToolNix
# Déposer le script dans le répertoire à mettre à jour
# Naviguer en powershell à cet emplacement et lancer le script
# 1. Détecte la présence des mkvpropedit.exe et mkvmerge.exe > DL et install si besoin
# 2. Récupère tous les fichiers et les psites vidéos, audios, sous titre
# 3. Prompt quelle piste choisir par défaut pour tous les .mkv
# 4. Met à jour le fichier avec mkvpropedit.exe


# Chemins par défaut
$mkvToolNixPath = "C:\Program Files\MKVToolNix"
$mkvmerge = Join-Path $mkvToolNixPath "mkvmerge.exe"
$mkvpropedit = Join-Path $mkvToolNixPath "mkvpropedit.exe"

# Fonction pour télécharger et installer MKVToolNix
function Install-MKVToolNix {
    Write-Host "`nMKVToolNix n'est pas installé. Installation en cours..." -ForegroundColor Yellow
    
    # URL de téléchargement (version Windows 64-bit)
    $downloadUrl = "https://mkvtoolnix.download/windows/releases/latest/mkvtoolnix-64-bit-setup.exe"
    $installerPath = Join-Path $env:TEMP "mkvtoolnix-setup.exe"
    
    try {
        Write-Host "Téléchargement depuis mkvtoolnix.download..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
        
        Write-Host "Lancement de l'installateur..." -ForegroundColor Cyan
        Write-Host "IMPORTANT : Suivez les instructions de l'installateur." -ForegroundColor Yellow
        
        Start-Process -FilePath $installerPath -Wait
        
        # Vérifier l'installation
        if (Test-Path $mkvmerge) {
            Write-Host "✓ MKVToolNix installé avec succès!" -ForegroundColor Green
            Remove-Item $installerPath -ErrorAction SilentlyContinue
            return $true
        } else {
            Write-Host "✗ Installation échouée ou annulée." -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "✗ Erreur lors du téléchargement/installation : $_" -ForegroundColor Red
        return $false
    }
}

# Vérifier et installer MKVToolNix si nécessaire
if (-not (Test-Path $mkvmerge) -or -not (Test-Path $mkvpropedit)) {
    if (-not (Install-MKVToolNix)) {
        Write-Host "`nImpossible de continuer sans MKVToolNix." -ForegroundColor Red
        Write-Host "Vous pouvez l'installer manuellement depuis : https://mkvtoolnix.download/" -ForegroundColor Yellow
        exit
    }
}

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Script de configuration des pistes MKV            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Récupérer tous les fichiers MKV
$mkvFiles = Get-ChildItem -Path . -Filter *.mkv

if ($mkvFiles.Count -eq 0) {
    Write-Host "`nAucun fichier MKV trouvé dans ce dossier." -ForegroundColor Red
    exit
}

Write-Host "`nFichiers MKV trouvés : $($mkvFiles.Count)" -ForegroundColor Green

# Analyser le PREMIER fichier pour déterminer la structure
Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Analyse du premier fichier pour configuration" -ForegroundColor Cyan
Write-Host "Fichier : $($mkvFiles[0].Name)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Yellow

try {
    $mkvInfo = & $mkvmerge -J $mkvFiles[0].FullName | ConvertFrom-Json
}
catch {
    Write-Host "Erreur lors de l'analyse du fichier : $_" -ForegroundColor Red
    exit
}
    
    # Afficher les pistes vidéo
    Write-Host "`n--- PISTES VIDÉO ---" -ForegroundColor Magenta
    $videoTracks = $mkvInfo.tracks | Where-Object { $_.type -eq "video" }
    $videoIndex = 1
    foreach ($track in $videoTracks) {
        $codec = $track.codec
        $defaultFlag = if ($track.properties.default_track) { "[PAR DÉFAUT]" } else { "" }
        Write-Host "  [$videoIndex] Vidéo : $codec $defaultFlag" -ForegroundColor White
        $videoIndex++
    }
    
    # Afficher les pistes audio
    Write-Host "`n--- PISTES AUDIO ---" -ForegroundColor Magenta
    $audioTracks = $mkvInfo.tracks | Where-Object { $_.type -eq "audio" }
    $audioIndex = 1
    $audioTrackInfo = @()
    foreach ($track in $audioTracks) {
        $language = $track.properties.language
        $codec = $track.codec
        $name = if ($track.properties.track_name) { $track.properties.track_name } else { "" }
        $defaultFlag = if ($track.properties.default_track) { "[PAR DÉFAUT]" } else { "" }
        Write-Host "  [$audioIndex] Audio : Langue=$language, Codec=$codec, Nom=$name $defaultFlag" -ForegroundColor White
        $audioTrackInfo += @{ Index = $audioIndex; Language = $language; Name = $name }
        $audioIndex++
    }
    
    # Afficher les pistes de sous-titres
    Write-Host "`n--- PISTES SOUS-TITRES ---" -ForegroundColor Magenta
    $subtitleTracks = $mkvInfo.tracks | Where-Object { $_.type -eq "subtitles" }
    $subtitleIndex = 1
    $subtitleTrackInfo = @()
    foreach ($track in $subtitleTracks) {
        $language = $track.properties.language
        $name = if ($track.properties.track_name) { $track.properties.track_name } else { "" }
        $defaultFlag = if ($track.properties.default_track) { "[PAR DÉFAUT]" } else { "" }
        Write-Host "  [$subtitleIndex] Sous-titre : Langue=$language, Nom=$name $defaultFlag" -ForegroundColor White
        $subtitleTrackInfo += @{ Index = $subtitleIndex; Language = $language; Name = $name }
        $subtitleIndex++
    }
    
# Stocker le nombre de pistes pour référence
$audioTrackCount = $audioTracks.Count
$subtitleTrackCount = $subtitleTracks.Count

# Demander à l'utilisateur ce qu'il veut configurer
Write-Host "`n--- CONFIGURATION GLOBALE ---" -ForegroundColor Green
Write-Host "Cette configuration sera appliquée à TOUS les fichiers MKV" -ForegroundColor Yellow

# Piste audio par défaut
if ($audioTracks.Count -gt 0) {
    Write-Host "`nQuelle(s) piste(s) audio voulez-vous définir par défaut?" -ForegroundColor Cyan
    Write-Host "  Entrez les numéros séparés par des virgules (ex: 1,3) ou 'aucune' pour tout désactiver : " -ForegroundColor Cyan -NoNewline
    $audioChoice = Read-Host
    
    $selectedAudio = @()
    if ($audioChoice -ne "aucune" -and $audioChoice -ne "") {
        $selectedAudio = $audioChoice -split "," | ForEach-Object { $_.Trim() }
    }
}

# Piste de sous-titres par défaut
if ($subtitleTracks.Count -gt 0) {
    Write-Host "`nQuelle(s) piste(s) de sous-titres voulez-vous définir par défaut?" -ForegroundColor Cyan
    Write-Host "  Entrez les numéros séparés par des virgules (ex: 1,2) ou 'aucune' pour tout désactiver : " -ForegroundColor Cyan -NoNewline
    $subtitleChoice = Read-Host
    
    $selectedSubtitles = @()
    if ($subtitleChoice -ne "aucune" -and $subtitleChoice -ne "") {
        $selectedSubtitles = $subtitleChoice -split "," | ForEach-Object { $_.Trim() }
    }
}

# Maintenant appliquer ces paramètres à TOUS les fichiers
Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Application aux $($mkvFiles.Count) fichiers..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Yellow

$successCount = 0
$errorCount = 0

foreach ($file in $mkvFiles) {
    Write-Host "`nTraitement de : $($file.Name)" -ForegroundColor White
    
    # Construire les commandes de modification
    $editCommands = @()
    
    # Configurer les pistes audio
    for ($i = 1; $i -le $audioTrackCount; $i++) {
        $editCommands += "--edit"
        $editCommands += "track:a$i"
        $editCommands += "--set"
        if ($selectedAudio -contains $i.ToString()) {
            $editCommands += "flag-default=1"
        } else {
            $editCommands += "flag-default=0"
        }
    }
    
    # Configurer les pistes de sous-titres
    for ($i = 1; $i -le $subtitleTrackCount; $i++) {
        $editCommands += "--edit"
        $editCommands += "track:s$i"
        $editCommands += "--set"
        if ($selectedSubtitles -contains $i.ToString()) {
            $editCommands += "flag-default=1"
        } else {
            $editCommands += "flag-default=0"
        }
    }
    
    # Appliquer les modifications
    if ($editCommands.Count -gt 0) {
        & $mkvpropedit $file.FullName @editCommands 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Modifié avec succès" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "  ✗ Erreur (structure de pistes différente?)" -ForegroundColor Red
            $errorCount++
        }
    }
}
    
Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║            Traitement terminé !                        ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host "`nRésumé :" -ForegroundColor Cyan
Write-Host "  ✓ Fichiers modifiés avec succès : $successCount" -ForegroundColor Green
if ($errorCount -gt 0) {
    Write-Host "  ✗ Fichiers en erreur : $errorCount" -ForegroundColor Red
}