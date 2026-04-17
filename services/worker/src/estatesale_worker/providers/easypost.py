from __future__ import annotations


class EasyPostProvider:
    def purchase_label(self, order_id: str, payload: dict[str, object]) -> dict[str, object]:
        return {
            "provider": "easypost",
            "orderId": order_id,
            "providerShipmentId": f"ezp-shp-{order_id}",
            "trackingNumber": "9400111899223847182634",
            "labelUrl": "https://example.com/labels/test-label.pdf",
            "rate": payload,
        }
