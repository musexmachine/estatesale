export type CandidateItemState =
  | "needs_review"
  | "approved"
  | "rejected"
  | "grouped"
  | "needs_photo";
export type ListingState =
  | "draft"
  | "ready_to_publish"
  | "published"
  | "sold"
  | "delisted"
  | "failed";
export type FulfillmentMode = "shipping" | "local_delivery" | "pickup";
export type OrderState =
  | "awaiting_payment"
  | "paid"
  | "fulfillment_pending"
  | "shipped"
  | "courier_dispatched"
  | "pickup_scheduled"
  | "delivered"
  | "completed";

export interface PropertyRecord {
  id: string;
  name: string;
  city: string;
  state: string;
  saleDeadline: string;
  notes: string;
}

export interface CandidateItem {
  id: string;
  propertyId: string;
  title: string;
  category: string;
  confidence: number;
  state: CandidateItemState;
  needsPhoto: boolean;
  riskFlags: string[];
  fulfillmentMode: FulfillmentMode;
  priceLowCents: number;
  priceHighCents: number;
  conditionSummary: string;
  evidence: Record<string, unknown>;
  groupId?: string;
}

export interface ListingDraft {
  id: string;
  candidateItemId: string;
  title: string;
  description: string;
  listingState: ListingState;
  shippingProfile: Record<string, unknown>;
  externalListingId?: string;
  externalUrl?: string;
}

export interface OrderRecord {
  id: string;
  listingDraftId: string;
  buyerName: string;
  state: OrderState;
  fulfillmentMode: FulfillmentMode;
  salePriceCents: number;
  highValue: boolean;
}

export interface Shipment {
  orderId: string;
  provider: "easypost";
  trackingNumber: string;
  labelUrl: string;
  rate: Record<string, unknown>;
}

export interface CourierDelivery {
  orderId: string;
  provider: "uber_direct";
  trackingUrl: string;
  proofPolicy: Record<string, unknown>;
  feeSnapshot: Record<string, unknown>;
}

export interface PickupAppointment {
  orderId: string;
  scheduledFor: string;
  pickupCode: string;
  instructions: string;
}

export interface DashboardData {
  properties: PropertyRecord[];
  reviewQueue: CandidateItem[];
  listingDrafts: ListingDraft[];
  orders: OrderRecord[];
}
