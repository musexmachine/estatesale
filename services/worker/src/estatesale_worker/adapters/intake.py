from __future__ import annotations

from collections import defaultdict

from ..types import CandidateDraft, GroupedDraft


class IntakePipelineAdapter:
    def process(
        self,
        property_id: str,
        asset_ids: list[str],
        transcript_hints: list[dict[str, object]] | None = None,
    ) -> tuple[list[CandidateDraft], list[GroupedDraft]]:
        transcript_hints = transcript_hints or []
        drafts = [
            CandidateDraft(
                title=str(hint["title"]),
                category=str(hint.get("category", "general")),
                confidence=float(hint.get("confidence", 0.5)),
                evidence=dict(hint.get("evidence", {})),
                metadata={"property_id": property_id, "asset_ids": asset_ids},
                condition_summary=str(hint.get("condition_summary", "")),
                fulfillment_mode=str(hint.get("fulfillment_mode", "shipping")),  # type: ignore[arg-type]
                price_low_cents=int(hint.get("price_low_cents", 0)),
                price_high_cents=int(hint.get("price_high_cents", 0)),
                transcript_only=bool(hint.get("transcript_only", False)),
                duplicate_key=str(hint["duplicate_key"]) if hint.get("duplicate_key") else None,
            )
            for hint in transcript_hints
        ]
        return drafts, self._group_duplicates(drafts)

    def _group_duplicates(self, drafts: list[CandidateDraft]) -> list[GroupedDraft]:
        grouped: defaultdict[str, list[CandidateDraft]] = defaultdict(list)
        for draft in drafts:
            if draft.duplicate_key:
                grouped[draft.duplicate_key].append(draft)

        return [
            GroupedDraft(group_key=group_key, title=items[0].title, items=items)
            for group_key, items in grouped.items()
            if len(items) > 1
        ]
