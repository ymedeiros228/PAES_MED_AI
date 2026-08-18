"""Runtime hook do PyInstaller — redireciona stdout/stderr para arquivo.

Quando o backend e congelado com console=False (modo windowed), o
PyInstaller usa runw.exe que nao aloca console. Python entao seta
sys.stdout e sys.stderr para None. Qualquer print() crasha com:
    AttributeError: 'NoneType' object has no attribute 'write'

Este hook roda ANTES do codigo do app e redireciona stdout/stderr
para um arquivo de log, garantindo que:
1. print() nao crasha o backend
2. temos logs para diagnostico na maquina do cliente

O log vai para <PAES_DATA_DIR>/logs/backend_stdout.log ou, se
PAES_DATA_DIR nao estiver setado, para <exe_dir>/../data/logs/.
"""

import os
import sys
from pathlib import Path


def _resolve_log_dir() -> Path:
    """Descobre onde colocar o log de stdout/stderr."""
    # 1) PAES_DATA_DIR (setado pelo launcher Flutter) — deve ser gravavel.
    data_dir = os.environ.get("PAES_DATA_DIR", "").strip().strip('"')
    if data_dir:
        p = Path(data_dir) / "logs"
        try:
            p.mkdir(parents=True, exist_ok=True)
            # Testa se e gravavel.
            test = p / ".write_test"
            test.write_text("ok", encoding="utf-8")
            test.unlink(missing_ok=True)
            return p
        except Exception:
            pass  # cai para fallback
    # 2) %LOCALAPPDATA%\PAES_MED_AI\data\logs (instalacao em Program Files)
    local_app_data = os.environ.get("LOCALAPPDATA", "").strip()
    if local_app_data:
        p = Path(local_app_data) / "PAES_MED_AI" / "data" / "logs"
        try:
            p.mkdir(parents=True, exist_ok=True)
            return p
        except Exception:
            pass
    # 3) Relativo ao exe: <install_dir>/data/logs/
    exe_dir = Path(sys.executable).resolve().parent
    for candidate in (exe_dir.parent / "data", exe_dir / "data"):
        try:
            (candidate / "logs").mkdir(parents=True, exist_ok=True)
            return candidate / "logs"
        except Exception:
            continue
    # 4) Fallback: temp dir
    import tempfile
    return Path(tempfile.gettempdir())


def _open_log():
    """Abre arquivo de log para stdout/stderr. Retorna file handle ou None."""
    try:
        log_dir = _resolve_log_dir()
        log_path = log_dir / "backend_stdout.log"
        f = open(str(log_path), "a", encoding="utf-8", buffering=1)
        f.write(f"\n{'='*60}\n")
        f.write(f"[{__import__('datetime').datetime.now().isoformat()}] "
                f"Backend iniciando (PID={os.getpid()})\n")
        f.write(f"sys.executable={sys.executable}\n")
        f.write(f"PAES_DATA_DIR={os.environ.get('PAES_DATA_DIR', '(nao setado)')}\n")
        f.write(f"{'='*60}\n")
        return f
    except Exception:
        return None


# Redireciona stdout/stderr se forem None (modo console=False).
if sys.stdout is None:
    _log_file = _open_log()
    if _log_file is not None:
        sys.stdout = _log_file
        sys.stderr = _log_file
    else:
        # Ultimo recurso: descarta saida silenciosamente.
        class _NullStream:
            def write(self, *a, **kw): pass
            def flush(self, *a, **kw): pass
            def close(self, *a, **kw): pass
        sys.stdout = _NullStream()
        sys.stderr = _NullStream()
