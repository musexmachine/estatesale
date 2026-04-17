import type {
  CandidateItem,
  CourierDelivery,
  ListingDraft,
  OrderRecord,
  PickupAppointment,
  Shipment,
} from "@/lib/types";

export interface ShippingPurchaseInput {
  weightOz: number;
  lengthIn: number;
  widthIn: number;
  heightIn: number;
}

export interface CourierDispatchInput {
  feeSnapshot: Record<string, unknown>;
  proofPolicy: {
    signatureRequired?: boolean;
    pinRequired?: boolean;
    photoRequired?: boolean;
  };
}

export function approveItem(item: CandidateItem): CandidateItem {
  return {
    ...item,
    state: item.needsPhoto ? "needs_photo" : "approved",
  };
}

export function rejectItem(item: CandidateItem): CandidateItem {
  return {
    ...item,
    state: "rejected",
  };
}

export function groupItems(items: CandidateItem[], groupId: string): CandidateItem[] {
  return items.map((item) => ({
    ...item,
    state: "grouped",
    groupId,
  }));
}

export function publishListing(item: CandidateItem, draft: ListingDraft): ListingDraft {
  if (item.state !== "approved") {
    throw new Error("Only approved items can be published.");
  }
  if (item.confidence < 0.75) {
    throw new Error("Low-confidence items must stay in review.");
  }
  if (item.riskFlags.length > 0) {
    throw new Error("Risk-flagged items require manual clearance before publish.");
  }
  return {
    ...draft,
    listingState: "published",
    externalListingId: `EBY-${draft.id}`,
    externalUrl: `https://www.ebay.com/itm/EBY-${draft.id}`,
  };
}

export function purchaseShippingLabel(
  order: OrderRecord,
  input: ShippingPurchaseInput,
): Shipment {
  if (order.fulfillmentMode !== "shipping") {
    throw new Error("Shipping labels are only valid for shipping orders.");
  }
  if (input.weightOz <= 0 || input.lengthIn <= 0 || input.widthIn <= 0 || input.heightIn <= 0) {
    throw new Error("Dimensions and weight are required before buying a label.");
  }

  return {
    orderId: order.id,
    provider: "easypost",
    trackingNumber: `9400${order.id.replace(/[^0-9]/g, "").padEnd(18, "1")}`,
    labelUrl: `https://labels.example.com/${order.id}.pdf`,
    rate: {
      amountCents: 1895,
      service: "USPS Ground Advantage",
      input,
    },
  };
}

export function dispatchCourierDelivery(
  order: OrderRecord,
  input: CourierDispatchInput,
): CourierDelivery {
  if (order.fulfillmentMode !== "local_delivery") {
    throw new Error("Courier dispatch is only valid for local delivery orders.");
  }
  if (order.highValue && !input.proofPolicy.pinRequired && !input.proofPolicy.signatureRequired) {
    throw new Error("High-value local deliveries require signature or PIN proof.");
  }

  return {
    orderId: order.id,
    provider: "uber_direct",
    trackingUrl: `https://tracking.example.com/uber/${order.id}`,
    proofPolicy: input.proofPolicy,
    feeSnapshot: input.feeSnapshot,
  };
}

export function schedulePickup(
  order: OrderRecord,
  scheduledFor: string,
  instructions: string,
): PickupAppointment {
  if (order.fulfillmentMode !== "pickup") {
    throw new Error("Pickup scheduling is only valid for pickup orders.");
  }
  return {
    orderId: order.id,
    scheduledFor,
    pickupCode: `PK-${order.id.toUpperCase()}`,
    instructions,
  };
}

export function closeSiblingListings(
  listings: ListingDraft[],
  soldListingId: string,
): ListingDraft[] {
  return listings.map((listing) => {
    if (listing.id === soldListingId) {
      return {
        ...listing,
        listingState: "sold",
      };
    }

    return listing.listingState === "published"
      ? {
          ...listing,
          listingState: "delisted",
        }
      : listing;
  });
}
