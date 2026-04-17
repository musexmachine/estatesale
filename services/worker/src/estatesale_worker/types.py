from __future__ import annotations

from dataclasses import dataclass, field
from datetime import UTC, datetime
from typing import Any, Literal

JobType = Literal[
    "intake_pipeline",
    "ebay_publish",
    "easypost_purchase_label",
    "uber_dispatch",
    "pickup_schedule",
]
JobStatus = Literal["pending", "running", "succeeded", "failed", "dead_letter"]
CandidateState = Literal["needs_review", "approved", "rejected", "grouped", "needs_photo"]


@dataclass(slots=True)
class JobRecord:
    id: str
    job_type: JobType
    payload: dict[str, Any]
    organization_id: str
    property_id: str | None = None
    attempt_count: int = 0
    max_attempts: int = 5
    status: JobStatus = "pending"


@dataclass(slots=True)
class CandidateDraft:
    title: str
    category: str
    confidence: float
    evidence: dict[str, Any] = field(default_factory=dict)
    metadata: dict[str, Any] = field(default_factory=dict)
    condition_summary: str = ""
    fulfillment_mode: Literal["shipping", "local_delivery", "pickup"] = "shipping"
    price_low_cents: int = 0
    price_high_cents: int = 0
    transcript_only: bool = False
    duplicate_key: str | None = None

    @property
    def state(self) -> CandidateState:
        if self.transcript_only or self.evidence.get("hero_frame_quality", 1.0) < 0.45:
            return "needs_photo"
        return "needs_review"


@dataclass(slots=True)
class GroupedDraft:
    group_key: str
    title: str
    items: list[CandidateDraft]


@dataclass(slots=True)
class ProviderSnapshot:
    provider: str
    payload: dict[str, Any]


@dataclass(slots=True)
class JobResult:
    status: Literal["succeeded", "failed"]
    message: str
    payload: dict[str, Any] = field(default_factory=dict)
    completed_at: datetime = field(default_factory=lambda: datetime.now(UTC))
