import Foundation

public enum ReviewState: String, Codable, Sendable {
    case needsReview = "needs_review"
    case approved = "approved"
    case rejected = "rejected"
    case grouped = "grouped"
    case needsPhoto = "needs_photo"
}

public enum FulfillmentMode: String, Codable, Sendable {
    case shipping
    case localDelivery = "local_delivery"
    case pickup
}

public struct SaleProperty: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var name: String
    public var city: String
    public var state: String
    public var saleDeadline: Date
    public var notes: String

    public init(id: UUID, name: String, city: String, state: String, saleDeadline: Date, notes: String) {
        self.id = id
        self.name = name
        self.city = city
        self.state = state
        self.saleDeadline = saleDeadline
        self.notes = notes
    }
}

public struct ReviewItem: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var propertyID: UUID
    public var title: String
    public var category: String
    public var confidence: Double
    public var state: ReviewState
    public var needsPhoto: Bool
    public var riskFlags: [String]
    public var fulfillmentMode: FulfillmentMode
    public var priceLowCents: Int
    public var priceHighCents: Int
    public var conditionSummary: String

    public init(
        id: UUID,
        propertyID: UUID,
        title: String,
        category: String,
        confidence: Double,
        state: ReviewState,
        needsPhoto: Bool,
        riskFlags: [String],
        fulfillmentMode: FulfillmentMode,
        priceLowCents: Int,
        priceHighCents: Int,
        conditionSummary: String
    ) {
        self.id = id
        self.propertyID = propertyID
        self.title = title
        self.category = category
        self.confidence = confidence
        self.state = state
        self.needsPhoto = needsPhoto
        self.riskFlags = riskFlags
        self.fulfillmentMode = fulfillmentMode
        self.priceLowCents = priceLowCents
        self.priceHighCents = priceHighCents
        self.conditionSummary = conditionSummary
    }

    public var isPublishable: Bool {
        state == .approved && riskFlags.isEmpty && confidence >= 0.75
    }
}

public struct ListingDraft: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var candidateItemID: UUID
    public var title: String
    public var description: String
    public var externalListingID: String?
    public var externalURL: URL?

    public init(
        id: UUID,
        candidateItemID: UUID,
        title: String,
        description: String,
        externalListingID: String? = nil,
        externalURL: URL? = nil
    ) {
        self.id = id
        self.candidateItemID = candidateItemID
        self.title = title
        self.description = description
        self.externalListingID = externalListingID
        self.externalURL = externalURL
    }
}

public struct SaleOrder: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var listingDraftID: UUID
    public var buyerName: String
    public var fulfillmentMode: FulfillmentMode
    public var salePriceCents: Int
    public var highValue: Bool

    public init(
        id: UUID,
        listingDraftID: UUID,
        buyerName: String,
        fulfillmentMode: FulfillmentMode,
        salePriceCents: Int,
        highValue: Bool
    ) {
        self.id = id
        self.listingDraftID = listingDraftID
        self.buyerName = buyerName
        self.fulfillmentMode = fulfillmentMode
        self.salePriceCents = salePriceCents
        self.highValue = highValue
    }
}

public struct EstateSaleSnapshot: Sendable, Equatable {
    public var properties: [SaleProperty]
    public var reviewQueue: [ReviewItem]
    public var listingDrafts: [ListingDraft]
    public var orders: [SaleOrder]

    public init(properties: [SaleProperty], reviewQueue: [ReviewItem], listingDrafts: [ListingDraft], orders: [SaleOrder]) {
        self.properties = properties
        self.reviewQueue = reviewQueue
        self.listingDrafts = listingDrafts
        self.orders = orders
    }
}
