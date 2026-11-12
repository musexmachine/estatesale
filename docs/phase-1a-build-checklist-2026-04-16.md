# Phase 1a Build Checklist — Estate‑Sale App MVP

Date: 2026-04-16
Scope: **Phase 1a only** (photo-first capture, eBay publish, shipping labels, tracking upload, basic returns)
Owner: Engineering + Product + Ops

## Goal
Start implementation immediately with a dependency-ordered checklist containing epics, stories, and acceptance criteria.

## Constraints
- Keep MVP narrow: no walkaround automation, no Uber Direct, no Mercari/Poshmark publishing automation.
- Preserve 45+ UX simplicity (minimal taps, plain language, high-contrast UI).
- Enforce idempotent state transitions and auditability for listing + shipping events.

## Approach
- Build from system foundations → listing pipeline → shipping/returns → reliability hardening.
- Ship each epic behind flags where risk exists.
- Treat this document as execution contract for sprint planning.

---

## Dependency Order (critical path)

1. **E0 Foundations**
2. **E1 Domain State Machine + Events**
3. **E2 Photo Intake + CandidateItem**
4. **E3 ListingDraft Review + Approval**
5. **E4 eBay Publish + Delist Guardrails**
6. **E5 Shipping Labels + Tracking Upload**
7. **E6 Basic Returns + Inventory Reconciliation**
8. **E7 Ops, Metrics, and Release Gates**

> Rule: do not start E4+ in production mode until E1 contract tests are passing.

---

## E0 — Foundations (repo, env, CI, flags)

### Story E0.1 — Project skeleton and package boundaries
**Acceptance criteria**
- [ ] `Packages/` exists with `Core`, `Data`, `Features`, `UIComponents` modules scaffolded.
- [ ] Build passes in CI with module boundaries enforced.
- [ ] README includes local run/test commands.

### Story E0.2 — CI gates and quality checks
**Acceptance criteria**
- [ ] CI runs lint (`swift-format`, `SwiftLint`) and tests (`XCTest`) on each PR.
- [ ] Merge is blocked on failing lint/tests.
- [ ] CI artifacts include unit test report and coverage output.

### Story E0.3 — Feature flags + environment config
**Acceptance criteria**
- [ ] Runtime flags exist for publish, label purchase, and returns flows.
- [ ] Staging/prod configs are isolated; secrets are not in source.
- [ ] Kill switch can disable publish/labels without app redeploy.

---

## E1 — Domain state machine + event contract

### Story E1.1 — Item/order canonical states
**Acceptance criteria**
- [ ] Item and order states implemented as typed enums + transition functions.
- [ ] Illegal transitions return typed errors.
- [ ] Transitions are idempotent for repeated events.

### Story E1.2 — Event envelope + idempotency
**Acceptance criteria**
- [ ] Event envelope includes `event_id`, `event_type`, `source`, `correlation_id`, `occurred_at`.
- [ ] Idempotency key policy documented and implemented for external side effects.
- [ ] Duplicate event processing verified by tests.

### Story E1.3 — Contract tests from state diagrams
**Acceptance criteria**
- [ ] Transition matrix tests cover allowed + forbidden transitions.
- [ ] Replay tests prove no duplicate sell/delist on repeated webhooks.
- [ ] Test suite runs in CI and is blocking.

---

## E2 — Photo intake + CandidateItem pipeline (photo-first)

### Story E2.1 — Capture flow (single-item photos)
**Acceptance criteria**
- [ ] User can capture multiple photos per item with clear “main photo + detail photo” guidance.
- [ ] If confidence is low, UI prompts for retake/extra close-up.
- [ ] Capture flow works offline and syncs when back online.

### Story E2.2 — CandidateItem creation
**Acceptance criteria**
- [ ] Photo set produces `CandidateItem` with confidence score.
- [ ] Low-confidence items route to `NeedsPhoto` / manual path.
- [ ] Evidence fields stored (`source`, `confidence`, extracted hints).

### Story E2.3 — Prohibited-item precheck
**Acceptance criteria**
- [ ] Pre-publish prohibited-item check runs on all approved drafts.
- [ ] Block reason is visible to user and logged for audit.
- [ ] Manual override requires explicit reason and is permission-gated.

---

## E3 — ListingDraft review + approval UX

### Story E3.1 — Review queue UI
**Acceptance criteria**
- [ ] Card UI supports `Looks Good`, `Fix`, `Not Selling`.
- [ ] Bulk navigation exists (next/previous) with large touch targets.
- [ ] Advanced fields are hidden by default.

### Story E3.2 — Edit flow and validation
**Acceptance criteria**
- [ ] User can edit title, condition, price, quantity before approval.
- [ ] Required listing fields validated before `DraftReady`.
- [ ] Validation errors are plain-language and actionable.

### Story E3.3 — Grouping and duplicate protection
**Acceptance criteria**
- [ ] User can group duplicate/set items into one listing draft.
- [ ] One sellable group maps to one active sale target at a time.
- [ ] Grouping actions are reversible until publish.

---

## E4 — eBay publish + delist guardrails

### Story E4.1 — eBay listing publish
**Acceptance criteria**
- [ ] `DraftReady` listing publishes to eBay sandbox successfully.
- [ ] Required category/condition/item specifics mapped with conservative defaults.
- [ ] Publish response persisted with external IDs + timestamps.

### Story E4.2 — Publish failure handling
**Acceptance criteria**
- [ ] External API failures move listing to retryable error state.
- [ ] Retry is idempotent and does not create duplicate listings.
- [ ] Operator sees error reason and can retry from admin queue.

### Story E4.3 — Sold event and global delist
**Acceptance criteria**
- [ ] On sold event, sibling active channel listings are delisted/closed.
- [ ] Delist workflow is idempotent under duplicate webhooks.
- [ ] Audit log shows source event and actions taken.

---

## E5 — Shipping labels + tracking upload

### Story E5.1 — Rate quote + label purchase
**Acceptance criteria**
- [ ] System requests rates, selects service by configured rule, purchases label.
- [ ] Stores quote snapshot, selected rate, label URL, tracking number, and charges.
- [ ] Label purchase failure produces retryable state with operator alert.

### Story E5.2 — Tracking sync to eBay
**Acceptance criteria**
- [ ] Purchased tracking is uploaded to eBay order successfully.
- [ ] Upload retries are idempotent.
- [ ] Status visible in order timeline.

### Story E5.3 — Shipping margin telemetry
**Acceptance criteria**
- [ ] Captures expected vs charged carrier cost fields.
- [ ] Dashboard/report exposes per-order shipping margin.
- [ ] Negative-margin orders are filterable for ops review.

---

## E6 — Basic returns + inventory reconciliation

### Story E6.1 — Return request intake
**Acceptance criteria**
- [ ] Return request can be created from shipped order.
- [ ] Return reason and channel policy context are stored.
- [ ] Return state transitions follow E1 contract.

### Story E6.2 — Return label + receipt
**Acceptance criteria**
- [ ] Return label can be generated for eligible orders.
- [ ] Received return updates inventory to `Returned` then `Relisted` or `Refunded`.
- [ ] Return actions are audit-logged.

### Story E6.3 — Refund/relist guardrails
**Acceptance criteria**
- [ ] Prevents both refund and relist being finalized twice.
- [ ] Duplicate webhook/input attempts are no-op with logged event.
- [ ] Operator UI shows final resolution clearly.

---

## E7 — Ops, metrics, and release gates

### Story E7.1 — Exception queues
**Acceptance criteria**
- [ ] Queues exist for publish failures, label failures, webhook mismatches.
- [ ] Each queue item has severity, owner, first-seen, and retry action.
- [ ] SLA targets defined and visible.

### Story E7.2 — MVP metrics instrumentation
**Acceptance criteria**
- [ ] Tracks time upload→reviewable draft, review edit rate, publish success, tracking success.
- [ ] Metrics segmented by category and confidence band.
- [ ] Dashboard available before production launch.

### Story E7.3 — Release checklist / go-live gate
**Acceptance criteria**
- [ ] 99%+ publish success in staging test window.
- [ ] 99%+ tracking upload success in staging test window.
- [ ] Zero duplicate-sell incidents in replay/load tests.
- [ ] Kill switches tested in staging.

---

## Definition of Done (Phase 1a)

Phase 1a is done only when all are true:
- [ ] E0–E7 stories marked complete with evidence links.
- [ ] State machine contract tests passing in CI.
- [ ] Sandbox-to-staging eBay + shipping end-to-end runbook executed.
- [ ] On-call + exception handling SOP documented.
- [ ] Product sign-off on 45+ usability acceptance pass.

## Out of Scope for Phase 1a
- Walkaround video auto-extraction.
- Uber Direct/local courier flow.
- Mercari import tooling automation.
- Poshmark publishing automation.
- Advanced ranking/recommendation models.
