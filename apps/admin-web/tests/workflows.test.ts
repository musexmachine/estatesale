import {
  closeSiblingListings,
  dispatchCourierDelivery,
  publishListing,
  purchaseShippingLabel,
  schedulePickup,
} from "@/lib/workflows";

const approvedItem = {
  id: "item-1",
  propertyId: "property-1",
  title: "Pioneer PL-518 turntable",
  category: "audio",
  confidence: 0.91,
  state: "approved" as const,
  needsPhoto: false,
  riskFlags: [],
  fulfillmentMode: "shipping" as const,
  priceLowCents: 18000,
  priceHighCents: 26000,
  conditionSummary: "Used with light dust cover wear.",
  evidence: {},
};

const publishableDraft = {
  id: "draft-1",
  candidateItemId: "item-1",
  title: "Pioneer PL-518 Direct Drive Turntable",
  description: "Vintage Pioneer turntable.",
  listingState: "ready_to_publish" as const,
  shippingProfile: {},
};

describe("admin web workflows", () => {
  it("publishes approved, unflagged items", () => {
    const listing = publishListing(approvedItem, publishableDraft);
    expect(listing.listingState).toBe("published");
    expect(listing.externalListingId).toBe("EBY-draft-1");
  });

  it("blocks publish when risk flags are present", () => {
    expect(() =>
      publishListing({ ...approvedItem, riskFlags: ["untested"] }, publishableDraft),
    ).toThrow("Risk-flagged items require manual clearance before publish.");
  });

  it("requires package dimensions before buying a shipping label", () => {
    expect(() =>
      purchaseShippingLabel(
        {
          id: "order-1",
          listingDraftId: "draft-1",
          buyerName: "Sam Collector",
          state: "paid",
          fulfillmentMode: "shipping",
          salePriceCents: 23900,
          highValue: false,
        },
        { weightOz: 0, lengthIn: 18, widthIn: 14, heightIn: 10 },
      ),
    ).toThrow("Dimensions and weight are required before buying a label.");
  });

  it("requires proof for high-value local delivery", () => {
    expect(() =>
      dispatchCourierDelivery(
        {
          id: "order-2",
          listingDraftId: "draft-2",
          buyerName: "Mina Local",
          state: "paid",
          fulfillmentMode: "local_delivery",
          salePriceCents: 18900,
          highValue: true,
        },
        { feeSnapshot: {}, proofPolicy: {} },
      ),
    ).toThrow("High-value local deliveries require signature or PIN proof.");
  });

  it("creates pickup codes for pickup orders", () => {
    const pickup = schedulePickup(
      {
        id: "order-3",
        listingDraftId: "draft-2",
        buyerName: "Jon Pickup",
        state: "paid",
        fulfillmentMode: "pickup",
        salePriceCents: 12000,
        highValue: false,
      },
      "2026-04-20T14:00:00Z",
      "Ring side gate buzzer.",
    );

    expect(pickup.pickupCode).toBe("PK-ORDER-3");
  });

  it("closes sibling listings after a sale lands", () => {
    const updated = closeSiblingListings(
      [
        { ...publishableDraft, id: "draft-a", listingState: "published" },
        { ...publishableDraft, id: "draft-b", listingState: "published" },
      ],
      "draft-a",
    );

    expect(updated[0].listingState).toBe("sold");
    expect(updated[1].listingState).toBe("delisted");
  });
});
