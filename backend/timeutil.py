"""Relógio único do backend.

O app é single-user e offline: tudo (fila do dia, streak, fechamento de dia/semana,
revisões) é organizado pelo dia do calendário local do aluno, não por UTC. Por isso
o relógio é local e as datas gravadas no banco continuam sem offset — trocar para UTC
mudaria a virada do dia e quebraria as comparações de string com o que já está gravado.
"""

from __future__ import annotations

from datetime import date, datetime, timedelta

ISO_TIMESPEC = "seconds"


def now() -> datetime:
    """Agora no fuso local do aluno."""
    return datetime.now()


def now_iso(timespec: str = ISO_TIMESPEC) -> str:
    """Carimbo usado nas colunas *_at / next_due."""
    return now().isoformat(timespec=timespec)


def iso_in(days: int = 0, timespec: str = ISO_TIMESPEC) -> str:
    """Carimbo daqui a `days` dias (agendamento de revisão)."""
    return (now() + timedelta(days=days)).isoformat(timespec=timespec)


def today() -> date:
    return now().date()


def today_iso() -> str:
    return today().isoformat()


def file_stamp() -> str:
    """Sufixo de arquivo/pasta: 20260807_093000."""
    return now().strftime("%Y%m%d_%H%M%S")
