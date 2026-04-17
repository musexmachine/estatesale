import Foundation

public protocol EstateSaleRepository: Sendable {
    func loadSnapshot() async throws -> EstateSaleSnapshot
}

public struct MockEstateSaleRepository: EstateSaleRepository {
    public init() {}

    public func loadSnapshot() async throws -> EstateSaleSnapshot {
        let propertyID = UUID(uuidString: "41111111-1111-1111-1111-111111111111")!
        let turntableID = UUID(uuidString: "71111111-1111-1111-1111-111111111111")!
        let tablesID = UUID(uuidString: "71111111-1111-1111-1111-111111111112")!
        let chairsID = UUID(uuidString: "71111111-1111-1111-1111-111111111113")!
        let draftID = UUID(uuidString: "91111111-1111-1111-1111-111111111111")!

        return EstateSaleSnapshot(
            properties: [
                SaleProperty(
                    id: propertyID,
                    name: "Marin Mid-Century Estate",
                    city: "San Rafael",
                    state: "CA",
                    saleDeadline: .now.addingTimeInterval(60 * 60 * 24 * 12),
                    notes: "Use Record Walkaround for rooms, Take Photos for close-up rescue shots."
                )
            ],
            reviewQueue: [
                ReviewItem(
                    id: turntableID,
                    propertyID: propertyID,
                    title: "Pioneer PL-518 turntable",
                    category: "audio",
                    confidence: 0.91,
                    state: .needsReview,
                    needsPhoto: false,
                    riskFlags: [],
                    fulfillmentMode: .shipping,
                    priceLowCents: 18000,
                    priceHighCents: 26000,
                    conditionSummary: "Used with light dust cover wear. Power-on not confirmed."
                ),
                ReviewItem(
                    id: tablesID,
                    propertyID: propertyID,
                    title: "Teak nesting tables",
                    category: "furniture",
                    confidence: 0.42,
                    state: .needsPhoto,
                    needsPhoto: true,
                    riskFlags: ["needs_photo"],
                    fulfillmentMode: .pickup,
                    priceLowCents: 22000,
                    priceHighCents: 34000,
                    conditionSummary: "Transcript matched item mention but hero frame was weak."
                ),
                ReviewItem(
                    id: chairsID,
                    propertyID: propertyID,
                    title: "Set of two teak dining chairs",
                    category: "furniture",
                    confidence: 0.84,
                    state: .approved,
                    needsPhoto: false,
                    riskFlags: [],
                    fulfillmentMode: .localDelivery,
                    priceLowCents: 14000,
                    priceHighCents: 22000,
                    conditionSummary: "Frames are solid; seats need cleaning."
                )
            ],
            listingDrafts: [
                ListingDraft(
                    id: draftID,
                    candidateItemID: turntableID,
                    title: "Pioneer PL-518 Direct Drive Turntable",
                    description: "Vintage Pioneer turntable from a Marin estate. Sold as untested."
                )
            ],
            orders: [
                SaleOrder(
                    id: UUID(uuidString: "b1111111-1111-1111-1111-111111111111")!,
                    listingDraftID: draftID,
                    buyerName: "Sam Collector",
                    fulfillmentMode: .shipping,
                    salePriceCents: 23900,
                    highValue: false
                ),
                SaleOrder(
                    id: UUID(uuidString: "b1111111-1111-1111-1111-111111111112")!,
                    listingDraftID: draftID,
                    buyerName: "Mina Local",
                    fulfillmentMode: .localDelivery,
                    salePriceCents: 18900,
                    highValue: true
                ),
                SaleOrder(
                    id: UUID(uuidString: "b1111111-1111-1111-1111-111111111113")!,
                    listingDraftID: draftID,
                    buyerName: "Jon Pickup",
                    fulfillmentMode: .pickup,
                    salePriceCents: 12000,
                    highValue: false
                )
            ]
        )
    }
}
