from __future__ import annotations


class EbayProvider:
    def publish_listing(self, listing_id: str, payload: dict[str, object]) -> dict[str, object]:
        return {
            "provider": "ebay",
            "listingId": listing_id,
            "providerListingId": f"EBY-{listing_id}",
            "shippingEnabled": True,
            "facebookCrossPostEligible": True,
            "payload": payload,
        }
