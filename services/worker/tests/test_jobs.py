from estatesale_worker.jobs import WorkerService
from estatesale_worker.repository import InMemoryEstateSaleRepository
from estatesale_worker.types import JobRecord


def test_intake_pipeline_marks_transcript_only_candidates_as_needs_photo() -> None:
    repo = InMemoryEstateSaleRepository(
        jobs=[
            JobRecord(
                id="job-1",
                job_type="intake_pipeline",
                organization_id="org-1",
                property_id="property-1",
                payload={
                    "assetIds": ["asset-1"],
                    "transcriptHints": [
                        {
                            "title": "Teak nesting tables",
                            "category": "furniture",
                            "confidence": 0.41,
                            "transcript_only": True,
                            "duplicate_key": "nesting-tables",
                        }
                    ],
                },
            )
        ]
    )
    service = WorkerService(repository=repo)

    service.run_once("worker-a")

    saved = repo.intake_results["property-1"]["drafts"]
    assert saved[0]["transcript_only"] is True
    assert saved[0]["state"] == "needs_photo"
    assert saved[0]["metadata"]["asset_ids"] == ["asset-1"]


def test_intake_pipeline_groups_duplicate_items() -> None:
    repo = InMemoryEstateSaleRepository(
        jobs=[
            JobRecord(
                id="job-2",
                job_type="intake_pipeline",
                organization_id="org-1",
                property_id="property-1",
                payload={
                    "assetIds": ["asset-2"],
                    "transcriptHints": [
                        {
                            "title": "Teak dining chair",
                            "category": "furniture",
                            "confidence": 0.87,
                            "duplicate_key": "teak-chair",
                        },
                        {
                            "title": "Teak dining chair",
                            "category": "furniture",
                            "confidence": 0.88,
                            "duplicate_key": "teak-chair",
                        },
                    ],
                },
            )
        ]
    )
    service = WorkerService(repository=repo)

    result = service.run_once("worker-a")

    assert result is not None
    assert result.payload["groupCount"] == 1
    assert repo.intake_results["property-1"]["groups"][0]["group_key"] == "teak-chair"


def test_shipping_job_persists_provider_snapshot() -> None:
    repo = InMemoryEstateSaleRepository(
        jobs=[
            JobRecord(
                id="job-3",
                job_type="easypost_purchase_label",
                organization_id="org-1",
                payload={
                    "orderId": "order-1",
                    "rate": {
                        "amountCents": 1895,
                        "service": "USPS Ground Advantage",
                    },
                },
            )
        ]
    )
    service = WorkerService(repository=repo)

    service.run_once("worker-a")

    assert repo.shipments["order-1"]["provider"] == "easypost"
    assert repo.shipments["order-1"]["rate"]["service"] == "USPS Ground Advantage"
