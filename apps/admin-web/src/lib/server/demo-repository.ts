import { createDemoData } from "@/lib/demo-data";
import type {
  CandidateItem,
  CourierDelivery,
  DashboardData,
  ListingDraft,
  PickupAppointment,
  Shipment,
} from "@/lib/types";
import {
  approveItem,
  closeSiblingListings,
  dispatchCourierDelivery,
  groupItems,
  publishListing,
  purchaseShippingLabel,
  rejectItem,
  schedulePickup,
  type CourierDispatchInput,
  type ShippingPurchaseInput,
} from "@/lib/workflows";

const state: DashboardData = createDemoData();

export class DemoEstateSaleRepository {
  async getDashboardData(): Promise<DashboardData> {
    return structuredClone(state);
  }

  async approveItem(itemId: string): Promise<CandidateItem> {
    const item = this.findItem(itemId);
    const approved = approveItem(item);
    this.replaceItem(approved);
    return structuredClone(approved);
  }

  async rejectItem(itemId: string): Promise<CandidateItem> {
    const item = this.findItem(itemId);
    const rejected = rejectItem(item);
    this.replaceItem(rejected);
    return structuredClone(rejected);
  }

  async groupItems(itemIds: string[]): Promise<CandidateItem[]> {
    const items = state.reviewQueue.filter((item) => itemIds.includes(item.id));
    const groupId = `group-${itemIds.join("-")}`;
    const grouped = groupItems(items, groupId);
    grouped.forEach((item) => this.replaceItem(item));
    return structuredClone(grouped);
  }

  async publishListing(listingId: string): Promise<ListingDraft> {
    const draft = this.findDraft(listingId);
    const item = this.findItem(draft.candidateItemId);
    const published = publishListing(item, draft);
    this.replaceDraft(published);
    return structuredClone(published);
  }

  async purchaseShippingLabel(
    orderId: string,
    input: ShippingPurchaseInput,
  ): Promise<Shipment> {
    const order = this.findOrder(orderId);
    return purchaseShippingLabel(order, input);
  }

  async dispatchCourierDelivery(
    orderId: string,
    input: CourierDispatchInput,
  ): Promise<CourierDelivery> {
    const order = this.findOrder(orderId);
    return dispatchCourierDelivery(order, input);
  }

  async schedulePickup(
    orderId: string,
    scheduledFor: string,
    instructions: string,
  ): Promise<PickupAppointment> {
    const order = this.findOrder(orderId);
    return schedulePickup(order, scheduledFor, instructions);
  }

  async recordSale(listingId: string): Promise<ListingDraft[]> {
    const current = state.listingDrafts.filter(
      (draft) => draft.candidateItemId === this.findDraft(listingId).candidateItemId,
    );
    const updated = closeSiblingListings(current, listingId);
    updated.forEach((draft) => this.replaceDraft(draft));
    return structuredClone(updated);
  }

  private findItem(itemId: string) {
    const item = state.reviewQueue.find((candidate) => candidate.id === itemId);
    if (!item) {
      throw new Error(`Unknown item: ${itemId}`);
    }
    return item;
  }

  private findDraft(listingId: string) {
    const draft = state.listingDrafts.find((candidate) => candidate.id === listingId);
    if (!draft) {
      throw new Error(`Unknown listing draft: ${listingId}`);
    }
    return draft;
  }

  private findOrder(orderId: string) {
    const order = state.orders.find((candidate) => candidate.id === orderId);
    if (!order) {
      throw new Error(`Unknown order: ${orderId}`);
    }
    return order;
  }

  private replaceItem(next: CandidateItem) {
    const index = state.reviewQueue.findIndex((item) => item.id === next.id);
    state.reviewQueue[index] = next;
  }

  private replaceDraft(next: ListingDraft) {
    const index = state.listingDrafts.findIndex((draft) => draft.id === next.id);
    state.listingDrafts[index] = next;
  }
}
