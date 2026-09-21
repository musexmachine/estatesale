# Scale Readiness Plan — EstateSale MVP to Production

Date: 2026-04-27
Status: Proposed execution plan
Source inputs: `docs/phase-1a-build-checklist-2026-04-16.md`, `docs/mvp-prd-engineering-review-2026-04-16.md`

## Lead Answer
The current plan is directionally strong for MVP, but not yet scale-ready. The missing pieces are explicit SLOs, capacity strategy, data partitioning, async backpressure, and operational runbooks tied to measurable gates. This plan closes those gaps without expanding product scope.

## Goal
Harden Phase 1a so the same architecture can support 10x volume growth without rewrite-level changes.

## Constraints
- Keep product scope fixed to Phase 1a (photo-first, eBay-first, shipping labels, tracking, basic returns).
- Preserve idempotent state transitions and auditability requirements already defined.
- Prefer additive changes that do not block MVP delivery.

## Approach
1. Add non-functional requirements (SLO/SLI/error budget) to each critical workflow.
2. Introduce queue-based async boundaries for external side effects.
3. Add data/storage partitioning and retention policy early.
4. Define observability, on-call, and load-test release gates.
5. Execute in two tracks: **Now (before launch)** and **Next (post-launch hardening)**.

---

## 1) Plan Review — What is solid vs missing

### Solid (keep as-is)
- Dependency ordering from foundations to ops gates is correct.
- State-machine + idempotency contract is correctly prioritized.
- Shipping/tracking instrumentation is already recognized as a business-critical surface.

### Missing for scale
1. No explicit **latency/availability/error budget targets** for publish, labels, tracking, and webhooks.
2. No **capacity model** (expected peak items/day, orders/day, webhook burst behavior).
3. No required **queue semantics** (retry policy, dead-letter queues, poison-message handling).
4. No explicit **database growth strategy** (indexes, partitioning, archival, retention).
5. No **multi-environment progressive rollout strategy** (canary %, rollback SLO triggers).
6. No **incident response runbook** tied to exception queues.

---

## 2) Scale-Ready Target Architecture (Phase 1a compatible)

## A. Workflow boundaries
- Keep `ListingDraft` as source of truth.
- Move external side effects behind queue workers:
  - `publish_requests`
  - `delist_requests`
  - `label_purchase_requests`
  - `tracking_upload_requests`
- API/UI writes intent + immutable event; workers perform side effects idempotently.

## B. Reliability rules
- Every side-effect request carries:
  - `idempotency_key`
  - `correlation_id`
  - `attempt_count`
  - `next_retry_at`
- Retry policy: exponential backoff with bounded attempts.
- Dead-letter queue after max attempts with operator-visible remediation actions.

## C. Data model hardening
- Required unique constraints:
  - `(channel, external_listing_id)` unique where not null.
  - `(event_id)` unique.
  - `(idempotency_key, effect_type)` unique.
- Required indexes:
  - events by `(aggregate_id, occurred_at)`
  - queue jobs by `(status, next_retry_at)`
  - orders by `(state, updated_at)`
- Retention defaults:
  - hot events: 90 days
  - warm archive: 1 year
  - PII minimization and TTL according to compliance policy

## D. Horizontal scaling assumptions
- Stateless API workers behind load balancer.
- Worker pool autoscaled from queue depth + oldest message age.
- Read replicas allowed for analytics/admin reads; writes stay on primary.

---

## 3) SLO/SLI definitions (required before production)

| Surface | SLI | Initial SLO |
|---|---|---|
| Draft publish to eBay | Success ratio of approved drafts publish attempts | >= 99.0% daily |
| Label purchase | Success ratio of label requests | >= 99.0% daily |
| Tracking upload | Success ratio of shipped orders with tracking posted | >= 99.0% daily |
| Webhook processing | Time from webhook receipt to state transition | p95 < 120s |
| Queue health | Oldest non-terminal job age | < 10 minutes |

Error budget policy:
- If weekly error budget burn exceeds 50%, freeze non-critical feature rollout.
- If weekly error budget burn exceeds 100%, trigger rollback to previous stable release.

---

## 4) Delivery Plan

## Track A — Before launch (must-have)
1. **Add scale acceptance criteria to E0/E1/E7**
   - CI includes contract + replay + load smoke tests.
2. **Implement async side-effect queue abstraction**
   - Publish/labels/tracking called from workers, not request thread.
3. **Add idempotency persistence and duplicate suppression metrics**
4. **Create runbooks**
   - queue backlog handling, provider outage mode, replay procedures.
5. **Load test baseline**
   - 10x MVP forecast burst for publish + webhook ingest.

## Track B — Post-launch hardening (first 30 days)
1. Add autoscaling policies tuned by real queue telemetry.
2. Add archive jobs and cold-storage lifecycle.
3. Add canary deployments with automated rollback guardrail.
4. Add chaos tests for provider timeout/5xx scenarios.

---

## 5) Concrete changes to current checklist

Apply these edits to `phase-1a-build-checklist` implementation tasks:

1. **E0.2 CI gates**: include load smoke test and migration drift check.
2. **E1.2 event envelope**: include `attempt_count` and `causation_id`.
3. **E4.2 publish failure**: require DLQ transition after bounded retries.
4. **E5.2 tracking sync**: require queue lag alarms and replay tool.
5. **E7.3 release gate**: require SLO dashboard + paging test + rollback drill.

---

## 6) Risks and tradeoffs

- Queue-based workers add implementation overhead now, but avoid blocking rewrite when volume rises.
- Strong idempotency constraints may surface current hidden data-quality issues; fix now reduces duplicate-sell risk later.
- Load testing before launch may delay timeline by days, but directly validates launch safety and reduces incident cost.

---

## 7) Definition of Scale-Ready (for this phase)

The app is scale-ready for Phase 1a when all are true:
1. All external side effects execute through idempotent async workers.
2. SLOs are instrumented and visible in a live dashboard.
3. Queue backlog alarms and DLQ remediation runbooks are tested.
4. Load test at 10x forecast passes without data-integrity violations.
5. Rollback drill completed in staging with documented evidence.
