from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_pack_copies_backend_recursively_without_local_secrets() -> None:
    text = (ROOT / "empacotar_windows.bat").read_text(encoding="utf-8")

    assert 'robocopy "backend" "%OUT%\\backend" /E' in text
    assert '/XF ".env"' in text
    assert '/XD "__pycache__" ".venv"' in text
    assert 'if not exist "%OUT%\\backend\\routers\\ai.py"' in text
    assert 'if not exist "%OUT%\\backend\\requirements.txt"' in text


def test_launcher_installs_package_dependencies_and_blocks_app_without_health() -> None:
    text = (ROOT / "PAES_MED_AI_Iniciar.bat").read_text(encoding="utf-8")

    assert 'python -m venv "%HERE%\\.venv"' in text
    assert '"%PY%" -m pip install -r "%BACKEND%\\requirements.txt"' in text
    assert 'echo ERRO: faltam dependencias do backend' in text
    assert "Get-Content '%LOG%' -Tail 12" in text
    assert text.index("goto health_fail") < text.index('start "" "%EXE%"')
