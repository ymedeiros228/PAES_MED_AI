# Bump de versão (1-pager)

Ao shippar `1.0.0+N`, altere **4** lugares:

1. `pubspec.yaml` → `version: 1.0.0+N`
2. `lib/core/app_version.dart` → `kAppVersionLabel = '1.0.0+N'`
3. `empacotar_windows.bat` → `echo 1.0.0+N> "%OUT%\VERSION.txt"`
4. `backend/smoke_test.py` → checks `ciclo_*_version` (e aceitar N nas gates anteriores)

Depois: smoke → `empacotar_windows.bat` (recria Desktop `.lnk` + ico) → commit/push.

Não commitar: `.env`, `*.db`, `dist/`, PDFs grandes, gabaritos.
