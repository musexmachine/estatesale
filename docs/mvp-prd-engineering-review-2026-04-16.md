# Engineering Review — Revised MVP PRD (Estate‑Sale App)

Date: 2026-04-16
Reviewer: Plan/Engineering Review (execution-focused)

## Goal
Evaluate the PRD for technical feasibility, delivery risk, and MVP scope integrity; produce concrete actions to de-risk implementation.

## Executive Summary (Lead Answer)
This is a strong PRD with good scope discipline (eBay-first, assisted Mercari/Poshmark, platform-owned shipping). The highest risks are not product vision—they are execution coupling: (1) computer-vision pipeline complexity in MVP, (2) policy/compliance drift across marketplaces, and (3) shipping/returns edge cases across channels. With three changes—explicit confidence thresholds/fallback flows, an evented state machine contract, and a narrowed launch slice—you can materially raise launch probability without reducing user value.

## What’s Strong

1. **Clear MVP channel strategy**
   - eBay as first-class channel is technically coherent and lowers API uncertainty.
   - Facebook exposure via eBay avoids duplicate listing infrastructure.

2. **Practical fulfillment model**
   - Platform-owned shipping is monetizable and operationally central.
   - Capturing quote/rate snapshots is correct for auditability.

3. **Good state awareness**
   - You already model item and order lifecycles, including stale/disposition states.

4. **User fit (45+) is explicit**
   - Simple actions and reduced cognitive load are represented throughout.

## Top Risks and Required Mitigations

## 1) CV + Listing generation scope is too wide for MVP
**Risk:** Open-vocabulary detection + OCR + embedding retrieval + transcript alignment + quality scoring in one MVP stream is likely schedule risk.

**Mitigation (recommended):**
- Define launch acceptance by confidence bands:
  - **High confidence**: auto-draft + minimal edits.
  - **Medium confidence**: draft + mandatory user confirmation fields.
  - **Low confidence**: “Needs Photo / Manual Entry” only.
- Require **single-item photo flow** parity first; gate walkaround automation behind quality thresholds.
- Add hard launch KPI: “% items entering low-confidence/manual path” with an upper bound target.

## 2) Cross-channel fulfillment/returns logic can leak invariants
**Risk:** Same inventory item represented across channels with different shipping/return rules can cause inconsistent states.

**Mitigation:**
- Make `ListingDraft` the source of truth and treat channel postings as projections.
- Add global invariant: **one sellable item/group can be in at most one terminal sold state**.
- Define idempotent delist workflow on `OrderPaid`/`OrderCompleted` events.
- Add dead-letter/retry strategy for webhook failures.

## 3) Marketplace policy drift can break flows silently
**Risk:** Partner/API behavior and policy constraints can change without notice.

**Mitigation:**
- Add a `ChannelPolicy` versioned config model and effective date.
- Put policy assumptions behind feature flags + admin override.
- Add quarterly policy verification runbook with owner.

## 4) Shipping profitability can be negative without controls
**Risk:** Platform-owned labels can become margin-negative due to dimensional inaccuracies, surcharges, returns, and re-labels.

**Mitigation:**
- Persist estimated vs charged carrier cost deltas.
- Add `shipping_margin_cents` per order and per category dashboards.
- Force package dimension confirmation for large/irregular categories.

## 5) “MVP includes too many operational surfaces”
**Risk:** Capture pipeline, listing, shipping, local courier, returns, admin tools, and cross-channel assistance all in Phase 1 may overextend.

**Mitigation (scope trim):**
- Phase 1a: Photo-first capture, eBay publish, shipping labels, tracking upload, basic returns.
- Phase 1b: Walkaround extraction + Uber Direct + assisted Mercari export.
- Phase 1c: Poshmark guidance and unsold disposition automation.

## Architecture and Data Model Recommendations

## A) Event model (add explicitly)
Add domain events to align state transitions and retries:
- `CandidateItemDetected`
- `ListingDraftCreated`
- `ListingDraftApproved`
- `ChannelListingPublished`
- `ChannelListingSold`
- `OrderPaid`
- `LabelPurchased`
- `ShipmentDelivered`
- `ReturnRequested`
- `ReturnReceived`
- `ItemRelisted`

Each event should have idempotency key, source channel, correlation ID, and event timestamp.

## B) State machine contract tests
Convert mermaid diagrams into executable tests:
- Allowed transitions only.
- Illegal transitions return typed errors.
- Transitions are idempotent when repeated.

## C) “Evidence-first” conditioning
For condition suggestions, store supporting evidence artifacts:
- `evidence_type` (ocr/photo/transcript/manual)
- `confidence`
- `extracted_value`
This improves dispute handling and reduces overclaim risk.

## D) Listing identity model
Use stable internal IDs:
- `item_id` (physical item or grouped set)
- `listing_draft_id`
- `channel_listing_id`
- `order_id`
Never use external marketplace IDs as primary keys.

## Security/Compliance Gaps to Close

1. Add data retention TTLs by object class (video, transcript, labels, tracking, PII).
2. Define PII field-level encryption and key rotation policy.
3. Add explicit audit log requirements for pricing edits and return approvals.
4. Add prohibited-item enforcement checkpoint before publish with human override logging.

## UX/Operations Gaps to Close

1. Add “operator confidence UI” (why this title/condition/price was suggested).
2. Add “batch review mode” with keyboard shortcuts for desktop admin users.
3. Define exception queue for:
   - listing failures
   - label purchase failures
   - webhook reconciliation mismatches

## Suggested MVP Exit Criteria (Engineering)

A release candidate should require all of the following:

1. **Reliability**
   - 99%+ successful eBay publish on approved drafts (excluding policy rejections).
   - 99%+ tracking upload success on shipped orders.

2. **Data correctness**
   - Zero duplicate sells in staged load tests.
   - 100% audit trail coverage for label purchase + cost snapshots.

3. **User efficiency**
   - Median draft review time per item under target.
   - Manual fallback completion under 60 seconds/item.

4. **Operational guardrails**
   - Exception queue SLA defined and monitored.
   - Shipping margin dashboard live before general availability.

## Recommended Immediate Next Steps (2-week plan)

1. Freeze Phase 1a scope and publish a dependency map.
2. Write state-transition contract tests from current diagrams.
3. Define confidence thresholds + fallback rules in PRD appendix.
4. Implement event envelope schema and idempotency policy.
5. Add an “Assumptions Register” with owner/date for each marketplace-policy dependency.

## Decision Log (What to keep as-is)

Keep unchanged for MVP:
- eBay-first publishing strategy.
- Platform-owned shipping model.
- Assisted/manual Mercari + Poshmark handling.
- 45+ usability constraints as hard product requirement.

