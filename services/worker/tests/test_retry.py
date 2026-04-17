from estatesale_worker.jobs import WorkerService
from estatesale_worker.repository import InMemoryEstateSaleRepository
from estatesale_worker.types import JobRecord


class ExplodingWorker(WorkerService):
    def _dispatch(self, job: JobRecord):  # type: ignore[override]
        raise RuntimeError("provider timeout")


def test_job_retries_until_dead_letter() -> None:
    repo = InMemoryEstateSaleRepository(
        jobs=[
            JobRecord(
                id="job-4",
                job_type="ebay_publish",
                organization_id="org-1",
                payload={"listingId": "listing-1"},
                max_attempts=2,
            )
        ]
    )
    service = ExplodingWorker(repository=repo)

    first = service.run_once("worker-a")
    second = service.run_once("worker-a")

    assert first is not None
    assert first.status == "failed"
    assert second is not None
    assert second.status == "failed"
    assert repo.jobs[0].status == "dead_letter"
    assert repo.jobs[0].payload["last_error"] == "provider timeout"
