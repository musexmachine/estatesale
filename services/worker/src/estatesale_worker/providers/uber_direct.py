from __future__ import annotations


class UberDirectProvider:
    def dispatch_delivery(self, order_id: str, payload: dict[str, object]) -> dict[str, object]:
        return {
            "provider": "uber_direct",
            "orderId": order_id,
            "providerDeliveryId": f"UBR-{order_id}",
            "trackingUrl": f"https://example.com/uber/{order_id}",
            "proofPolicy": payload.get("proofPolicy", {}),
            "feeSnapshot": payload.get("feeSnapshot", {}),
        }
