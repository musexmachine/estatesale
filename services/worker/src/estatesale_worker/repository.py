from __future__ import annotations

from copy import deepcopy
from dataclasses import asdict
from typing import Protocol

from .types import CandidateDraft, GroupedDraft, JobRecord, JobResult


class EstateSaleRepository(Protocol):
    def claim_available_job(self, worker_id: str) -> JobRecord | None: ...

    def complete_job(self, job_id: str, result: JobResult) -> None: ...

    def fail_job(self, job_id: str, error: str) -> None: ...

    def save_intake_result(
        self,
        property_id: str,
        drafts: list[CandidateDraft],
        groups: list[GroupedDraft],
    ) -> None: ...

    def publish_listing(self, listing_id: str, payload: dict[str, object]) -> None: ...

    def save_shipment(self, order_id: str, payload: dict[str, object]) -> None: ...

    def save_courier_delivery(self, order_id: str, payload: dict[str, object]) -> None: ...

    def save_pickup_appointment(self, order_id: str, payload: dict[str, object]) -> None: ...


class InMemoryEstateSaleRepository:
    def __init__(self, jobs: list[JobRecord] | None = None) -> None:
        self.jobs = jobs or []
        self.intake_results: dict[str, dict[str, object]] = {}
        self.published_listings: dict[str, dict[str, object]] = {}
        self.shipments: dict[str, dict[str, object]] = {}
        self.courier_deliveries: dict[str, dict[str, object]] = {}
        self.pickups: dict[str, dict[str, object]] = {}

    def claim_available_job(self, worker_id: str) -> JobRecord | None:
        for job in self.jobs:
            if job.status == "pending":
                job.status = "running"
                job.payload["locked_by"] = worker_id
                return job
        return None

    def complete_job(self, job_id: str, result: JobResult) -> None:
        job = self._find_job(job_id)
        job.status = "succeeded"
        job.payload["result"] = asdict(result)

    def fail_job(self, job_id: str, error: str) -> None:
        job = self._find_job(job_id)
        job.attempt_count += 1
        if job.attempt_count >= job.max_attempts:
            job.status = "dead_letter"
        else:
            job.status = "pending"
        job.payload["last_error"] = error

    def save_intake_result(
        self,
        property_id: str,
        drafts: list[CandidateDraft],
        groups: list[GroupedDraft],
    ) -> None:
        self.intake_results[property_id] = {
            "drafts": [{**asdict(draft), "state": draft.state} for draft in drafts],
            "groups": [
                {
                    "group_key": group.group_key,
                    "title": group.title,
                    "items": [{**asdict(item), "state": item.state} for item in group.items],
                }
                for group in groups
            ],
        }

    def publish_listing(self, listing_id: str, payload: dict[str, object]) -> None:
        self.published_listings[listing_id] = deepcopy(payload)

    def save_shipment(self, order_id: str, payload: dict[str, object]) -> None:
        self.shipments[order_id] = deepcopy(payload)

    def save_courier_delivery(self, order_id: str, payload: dict[str, object]) -> None:
        self.courier_deliveries[order_id] = deepcopy(payload)

    def save_pickup_appointment(self, order_id: str, payload: dict[str, object]) -> None:
        self.pickups[order_id] = deepcopy(payload)

    def _find_job(self, job_id: str) -> JobRecord:
        for job in self.jobs:
            if job.id == job_id:
                return job
        raise KeyError(job_id)
