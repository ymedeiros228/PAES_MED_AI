import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import services_advanced


def test_indexing_can_run_without_remote_embedding(monkeypatch) -> None:
    def fail_if_called(_text: str) -> list[float]:
        raise AssertionError("embedding remoto não deve ser chamado")

    monkeypatch.setattr(services_advanced, "openai_embedding", fail_if_called)
    result = services_advanced.index_all_questions(limit=300, allow_remote=False)

    assert result["indexed"] > 0
    assert result["model"] == "local-hash-64"
