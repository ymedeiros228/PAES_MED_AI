# AGENTS.md

## Cursor Cloud specific instructions

PAES MED AI is a local, offline-first study app: a **Flutter** desktop client (`lib/`, primary target Windows) + a **Python FastAPI** backend (`backend/`) backed by an embedded **SQLite** DB (`data/paes_med_ai.db`). The client talks to the backend at `http://127.0.0.1:8000` (see `lib/core/data/api_client.dart`).

### Toolchain / versions (non-obvious)
- The project pins **Flutter 3.24.5 / Dart 3.5.4** in `.metadata` (revision `dec2ee5c1f98f8e84a7d5380c05eb8a3d0a81668`). This matters: newer stable Flutter (e.g. 3.44) fails to compile the code (`CardTheme` → `CardThemeData`, `CupertinoPageTransitionsBuilder` removed). The SDK is installed at `/opt/flutter-sdk/flutter` and added to `PATH` via the agent's `~/.bashrc`. Do not `flutter upgrade`.
- The repo ships only the `windows/` platform folder. To run on this Linux VM, the `web/` platform scaffolding is generated with `flutter create --platforms=web .` (committed). There is no `linux/`/`web/` desktop tooling beyond that.

### Backend (required service)
- Runs from `backend/`. Deps live in a venv at `backend/.venv` (`requirements.txt`). Start with: `.venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000` (add `--reload` for hot reload during dev).
- On startup it auto-creates data dirs, runs `init_db()` and `seed()`, and indexes questions — no manual migration needed. Health check: `curl http://127.0.0.1:8000/health` (also lists seeded question count). Swagger UI at `/docs`; ~110 endpoints.
- `backend/.env` is required (copy from `backend/.env.example`). All AI/media keys (`OPENAI_API_KEY`, `YOUTUBE_API_KEY`, `SERPER_API_KEY`) are OPTIONAL — every path degrades gracefully to offline/local behavior when keys are the placeholder `cole_sua_chave_aqui` or absent.
- Large end-to-end API smoke test: `backend/.venv/bin/python smoke_test.py` (run from `backend/`, backend need not be running — it imports the app).

### Frontend (client)
- Install deps: `flutter pub get`. Lint: `flutter analyze` (currently ~11 pre-existing info/warning lints, no errors). Tests: `flutter test`.
- Note: the sole widget test `test/widget_test.dart` is pre-existing and brittle — it does a single `pump()` while `go_router`'s async `redirect` reads `SharedPreferences`, so navigation hasn't settled and the `find.textContaining('PAES')` assertion fails. This is a test-code issue, not an environment problem.
- Run on this VM (web): `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:8000`, then open `http://127.0.0.1:8080`. The backend must be running first. First-run shows onboarding (persisted via `onboarding_done_v1` in SharedPreferences); after finishing it, the app routes to `/dashboard`.
- The intended Windows one-click flow (`PAES_MED_AI_Iniciar.bat`, `tools/*.bat`) uses hardcoded Windows paths and does not apply on Linux; run the underlying `uvicorn`/`flutter` commands directly instead.
