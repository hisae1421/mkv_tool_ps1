# mkv_tool_ps1
PowerShell script to batch edit default audio/subtitle tracks in MKV files with automatic MKVToolNix installation

# MKV Batch Track Editor
Script PowerShell pour configurer les pistes audio et sous-titres par défaut dans des fichiers MKV en lot.

## Fonctionnalités
- Installation automatique de MKVToolNix (dernière version)
- Analyse des pistes vidéo, audio et sous-titres
- Configuration interactive des pistes par défaut
- Traitement en lot de plusieurs fichiers
- Gestion intelligente des erreurs

## Utilisation

1. Téléchargez le script `Configure-MKV-Tracks.ps1`
2. Placez-le dans le dossier contenant vos fichiers MKV
3. Clic droit > "Exécuter avec PowerShell"
4. Suivez les instructions à l'écran

## Prérequis

- Windows 10/11
- PowerShell 5.1 ou supérieur

Le script installe automatiquement MKVToolNix si nécessaire.

## Exemple

Le script va :
1. Détecter tous les fichiers `.mkv` dans le dossier
2. Analyser les pistes du premier fichier
3. Vous demander quelle configuration appliquer
4. Appliquer cette configuration à tous les fichiers

## Licence

MIT License - Utilisez librement !

## Contributions

Les pull requests sont les bienvenues !

## Problèmes

Si vous rencontrez un problème, ouvrez une issue.
