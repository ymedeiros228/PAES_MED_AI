"""Smoke test read-only para validar a API sem resetar a base local."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))

from fastapi.testclient import TestClient

from main import app


def main() -> int:
    client = TestClient(app)
    checks: list[tuple[str, bool, str]] = []

    def ok(name: str, cond: bool, detail: str = "") -> None:
        checks.append((name, cond, detail))

    r = client.get("/health")
    health = r.json() if r.status_code == 200 else {}
    ok("health", r.status_code == 200 and health.get("status") == "ok", str(health)[:160])
    ok("questions_count", int(health.get("questions") or 0) > 0, str(health.get("questions")))
    ok("data_dir", bool(health.get("dataDir")), str(health.get("dataDir")))

    r = client.get("/api/questions", params={"limit": 5})
    questions = r.json() if r.status_code == 200 else []
    ok("questions", r.status_code == 200 and isinstance(questions, list), str(questions)[:160])

    r = client.get("/api/dashboard")
    dash = r.json() if r.status_code == 200 else {}
    ok("dashboard", r.status_code == 200 and isinstance(dash, dict), str(dash)[:160])

    r = client.get("/api/backup/last")
    ok("backup_last", r.status_code == 200, r.text[:160])

    r = client.get("/api/backups/summary")
    summary = r.json() if r.status_code == 200 else {}
    ok("backups_summary", r.status_code == 200 and summary.get("ok") is True, str(summary)[:160])

    repo = ROOT.parent
    draft_store = (repo / "lib" / "features" / "essay" / "essay_draft.dart").read_text(
        encoding="utf-8",
        errors="ignore",
    )
    essay_screen = (
        repo / "lib" / "features" / "essay" / "presentation" / "essay_screen.dart"
    ).read_text(encoding="utf-8", errors="ignore")
    ok(
        "essay_draft_offline",
        "saveEssayDraft" in draft_store
        and "loadEssayDraft" in draft_store
        and "_restoreDraft" in essay_screen,
        "draft store + screen wiring",
    )

    failed = [item for item in checks if not item[1]]
    for name, passed, detail in checks:
        status = "OK" if passed else "FAIL"
        print(f"{status:4} {name} {detail}")
    print(f"\n{len(checks) - len(failed)}/{len(checks)} checks OK")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
