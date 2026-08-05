#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
command -v flutter >/dev/null || { echo "Flutter não encontrado no PATH."; exit 1; }
flutter create --platforms=android,web,linux --project-name paes_med_ai .
flutter pub get
flutter analyze
echo "Projeto preparado com sucesso."
