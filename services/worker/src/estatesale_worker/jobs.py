from __future__ import annotations

from .adapters.intake import IntakePipelineAdapter
from .providers.easypost import EasyPostProvider
from .providers.ebay import EbayProvider
from .providers.uber_direct import UberDirectProvider
from .repository import EstateSaleRepository
from .types import CandidateDraft, GroupedDraft, JobRecord, JobResult


class WorkerService:
    def __init__(
        self,
        repository: EstateSaleRepository,
        intake_adapter: IntakePipelineAdapter | None = None,
        ebay_provider: EbayProvider | None = None,
        easypost_provider: EasyPostProvider | None = None,
        uber_provider: UberDirectProvider | None = None,
    ) -> None:
        self.repository = repository
        self.intake_adapter = intake_adapter or IntakePipelineAdapter()
        self.ebay_provider = ebay_provider or EbayProvider()
        self.easypost_provider = easypost_provider or EasyPostProvider()
        self.uber_provider = uber_provider or UberDirectProvider()

    def run_once(self, worker_id: str) -> JobResult | None:
        job = self.repository.claim_available_job(worker_id)
        if job is None:
            return None

        try:
            result = self._dispatch(job)
            self.repository.complete_job(job.id, result)
            return result
        except Exception as exc:  # pragma: no cover - defensive wrapper
            self.repository.fail_job(job.id, str(exc))
            return JobResult(status="failed", message=str(exc))

    def _dispatch(self, job: JobRecord) -> JobResult:
        match job.job_type:
            case "intake_pipeline":
                drafts, groups = self._run_intake(job)
                return JobResult(
                    status="succeeded",
                    message=f"Processed {len(drafts)} candidate items",
                    payload={
                        "draftCount": len(drafts),
                        "groupCount": len(groups),
                    },
                )
            case "ebay_publish":
                snapshot = self.ebay_provider.publish_listing(
                    listing_id=str(job.payload["listingId"]),
                    payload=dict(job.payload.get("listingPayload", {})),
                )
                self.repository.publish_listing(str(job.payload["listingId"]), snapshot)
                return JobResult(status="succeeded", message="Published eBay listing", payload=snapshot)
            case "easypost_purchase_label":
                snapshot = self.easypost_provider.purchase_label(
                    order_id=str(job.payload["orderId"]),
                    payload=dict(job.payload.get("rate", {})),
                )
                self.repository.save_shipment(str(job.payload["orderId"]), snapshot)
                return JobResult(status="succeeded", message="Purchased shipping label", payload=snapshot)
            case "uber_dispatch":
                snapshot = self.uber_provider.dispatch_delivery(
                    order_id=str(job.payload["orderId"]),
                    payload=dict(job.payload),
                )
                self.repository.save_courier_delivery(str(job.payload["orderId"]), snapshot)
                return JobResult(status="succeeded", message="Dispatched local delivery", payload=snapshot)
            case "pickup_schedule":
                payload = {
                    "scheduledFor": job.payload["scheduledFor"],
                    "pickupCode": job.payload["pickupCode"],
                    "instructions": job.payload["instructions"],
                }
                self.repository.save_pickup_appointment(str(job.payload["orderId"]), payload)
                return JobResult(status="succeeded", message="Scheduled pickup", payload=payload)
            case _:
                raise ValueError(f"Unsupported job type: {job.job_type}")

    def _run_intake(self, job: JobRecord) -> tuple[list[CandidateDraft], list[GroupedDraft]]:
        drafts, groups = self.intake_adapter.process(
            property_id=str(job.property_id or job.payload["propertyId"]),
            asset_ids=list(job.payload.get("assetIds", [])),
            transcript_hints=list(job.payload.get("transcriptHints", [])),
        )
        self.repository.save_intake_result(str(job.property_id or job.payload["propertyId"]), drafts, groups)
        return drafts, groups
