import Foundation
import Observation

@MainActor
@Observable
public final class SellerAppModel {
    public private(set) var properties: [SaleProperty] = []
    public private(set) var reviewQueue: [ReviewItem] = []
    public private(set) var listingDrafts: [ListingDraft] = []
    public private(set) var orders: [SaleOrder] = []
    public private(set) var isLoading = false

    private let repository: any EstateSaleRepository

    public init(repository: any EstateSaleRepository = MockEstateSaleRepository()) {
        self.repository = repository
    }

    public var publishableCount: Int {
        reviewQueue.filter(\.isPublishable).count
    }

    public func load() async throws {
        isLoading = true
        defer { isLoading = false }

        let snapshot = try await repository.loadSnapshot()
        properties = snapshot.properties
        reviewQueue = snapshot.reviewQueue
        listingDrafts = snapshot.listingDrafts
        orders = snapshot.orders
    }

    public func approve(itemID: UUID) {
        guard let index = reviewQueue.firstIndex(where: { $0.id == itemID }) else { return }
        if reviewQueue[index].needsPhoto {
            reviewQueue[index].state = .needsPhoto
            return
        }
        reviewQueue[index].state = .approved
    }

    public func reject(itemID: UUID) {
        guard let index = reviewQueue.firstIndex(where: { $0.id == itemID }) else { return }
        reviewQueue[index].state = .rejected
    }
}
