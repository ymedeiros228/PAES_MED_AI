"""Modelos de request/response da API."""

from __future__ import annotations

from typing import (
    Any,
    Literal,
)

from pydantic import (
    BaseModel,
    Field,
)


class ChatMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=12000)

class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=12000)
    history: list[ChatMessage] = Field(default_factory=list, max_length=20)
    style: str | None = Field(
        default="professor",
        description="professor|medico|crianca|analogia|mapa|resumo|macete|flashcard",
    )

class ChatResponse(BaseModel):
    answer: str
    model: str
    usedRag: bool = True
    citations: list[dict[str, Any]] = Field(default_factory=list)
    ragMode: str | None = None
    hasLocalBase: bool = True
    uncited: bool = False


class AIProviderConfigRequest(BaseModel):
    provider: Literal["gemini", "openai"]
    apiKey: str = Field(min_length=1, max_length=512)
    model: str | None = Field(default=None, max_length=160)


class AIProviderTestRequest(BaseModel):
    provider: Literal["gemini", "openai"] | None = None


class AnswerRequest(BaseModel):
    questionId: str
    correct: bool
    subject: str
    topic: str
    errorType: str | None = None
    timeMs: int | None = None

class SimulationRequest(BaseModel):
    mode: str = "prova_completa"
    subject: str | None = None
    topic: str | None = None
    difficulty: str | None = None
    year: int | None = None
    limit: int = 10

class GradeRequest(BaseModel):
    answers: list[dict[str, Any]]

class LessonTextRequest(BaseModel):
    title: str
    transcript: str = Field(min_length=20, max_length=200000)
    sourceType: str = "legenda"
    sourceRef: str | None = None

class EssayRequest(BaseModel):
    theme: str
    text: str = Field(min_length=50, max_length=20000)
    persona: str | None = None
    focusAxis: str | None = None

class PlanRequest(BaseModel):
    days: int = 30
    examDate: str | None = None

class GenerateQuestionRequest(BaseModel):
    subject: str
    topic: str

class ApprovalRequest(BaseModel):
    questionId: str
    approve: bool = True

class CurationPromoteRequest(BaseModel):
    limit: int = Field(default=8, ge=1, le=40)

class ExamDatePayload(BaseModel):
    examDate: str | None = None

class MarkReadPayload(BaseModel):
    subject: str = Field(min_length=1, max_length=120)
    topic: str = Field(min_length=1, max_length=200)

class GapRecoverRequest(BaseModel):
    subject: str
    topic: str

class CommitIngestRequest(BaseModel):
    previewId: str
    questions: list[dict[str, Any]] | None = None
    highConfidenceOnly: bool = False
    minConfidence: float = 0.55
    autoProfessor: bool = True
    allowWithoutGabarito: bool = False

class UpdatePreviewRequest(BaseModel):
    previewId: str
    questions: list[dict[str, Any]]

class IngestFromDataRequest(BaseModel):
    kind: Literal["prova", "gabarito", "edital"]
    filename: str
    year: int | None = None
    subject: str = "Geral"

class ApplyGabaritoRequest(BaseModel):
    year: int

class ImportYearRequest(BaseModel):
    year: int = Field(ge=1900, le=2100)
    commit: bool = False

class ImportYearSafeRequest(BaseModel):
    year: int = Field(ge=1900, le=2100)
    commit: bool = True
    minConfidence: float = 0.55
    skipIfCommitted: bool = False

class MediaOpenPayload(BaseModel):
    url: str = Field(min_length=8, max_length=2000)
    kind: str | None = Field(default=None, description="video|article|auto")
    subject: str | None = None
    topic: str | None = None
    title: str | None = None

class MediaMarkReadPayload(BaseModel):
    url: str = Field(min_length=8, max_length=2000)
    subject: str | None = None
    topic: str | None = None
    title: str | None = None

class MediaPrefsPayload(BaseModel):
    suggestVideos: bool | None = None
    suggestArticles: bool | None = None

class FlashcardCreate(BaseModel):
    front: str
    back: str
    subject: str | None = None
    topic: str | None = None

class FlashcardReview(BaseModel):
    remembered: bool

class PlanDoneRequest(BaseModel):
    days: int
    day: int
    done: bool = True

class AdaptiveRequest(BaseModel):
    subject: str
    topic: str
    nSimilar: int = 10
    nHarder: int = 20
    nGenerated: int = 0

class AcervoFetchRequest(BaseModel):
    year: int
    dryRun: bool = False
    overwrite: bool = False

class AcervoFetchAvailableRequest(BaseModel):
    dryRun: bool = False
    overwrite: bool = False

class AcervoBootstrapRequest(BaseModel):
    dryRun: bool = False
    overwrite: bool = False
    year: int | None = None

class AcervoBootstrapCommitRequest(BaseModel):
    dryRun: bool = False
    overwrite: bool = False
    year: int | None = None
    minConfidence: float = 0.55
    autoProfessor: bool = True

class AcervoBatchCommitRequest(BaseModel):
    dryRun: bool = False
    overwrite: bool = False
    minConfidence: float = 0.55
    skipCommitted: bool = True
    autoProfessor: bool = True

class AcervoCommitOnDiskRequest(BaseModel):
    dryRun: bool = False
    minConfidence: float = 0.55
    skipCommitted: bool = True
    autoProfessor: bool = True

class AcervoImportAllCompleteRequest(BaseModel):
    minConfidence: float = 0.55
    skipIfCommitted: bool = False
    classifyAfter: bool = True

class OpenFolderRequest(BaseModel):
    folder: Literal["provas", "gabaritos", "edital", "root"] = "provas"

class OpenPathRequest(BaseModel):
    path: str = Field(min_length=2, max_length=2000)

class ExportDayPayload(BaseModel):
    markdown: str = Field(default="", max_length=200_000)
    filename: str | None = Field(default=None, max_length=120)

class OpenUrlRequest(BaseModel):
    url: str = Field(min_length=8, max_length=2000)

class SessionCheckpointRequest(BaseModel):
    phaseIndex: int = 0
    qIndex: int = 0
    answeredIds: list[str] = Field(default_factory=list)
    elapsedMs: int = 0
    correctCount: int = 0
    sessionErrors: list[str] = Field(default_factory=list)
    phaseName: str | None = None
    questionIds: list[str] = Field(default_factory=list)
    started: bool = True

class SimCheckpointRequest(BaseModel):
    mode: str = "dia_prova"
    limit: int = 10
    subject: str | None = None
    startedAt: str | None = None
    answers: dict[str, Any] = Field(default_factory=dict)
    errorTypes: dict[str, Any] = Field(default_factory=dict)
    questionIds: list[str] = Field(default_factory=list)
    questions: list[dict[str, Any]] = Field(default_factory=list)
    currentIndex: int = 0
    elapsedSec: int = 0
    examLocked: bool = False
    preflightDone: bool = False
    basis: str | None = None
    warning: str | None = None
    started: bool = True

class ScheduleGapsRequest(BaseModel):
    gaps: list[dict[str, Any]] = Field(default_factory=list)

class ProfessorBatchRequest(BaseModel):
    limit: int = 20
    preferUema: bool = True
    uemaOnly: bool = False

class ProfessorGenerateRequest(BaseModel):
    questionId: str

class ProfessorAcceptRequest(BaseModel):
    questionId: str
    resolution: str
    bancaIntent: str
    macete: str
    pegadinha: str
    relatedTopics: list[str] = Field(default_factory=list)

class FlashcardsFromQuestionRequest(BaseModel):
    questionId: str
    count: int = Field(default=5, ge=1, le=10)

class ProfessorQueueActionRequest(BaseModel):
    questionId: str

class ParseGateRequest(BaseModel):
    yearHealth: dict[str, Any] | None = None
    pending: dict[str, Any] | None = None
