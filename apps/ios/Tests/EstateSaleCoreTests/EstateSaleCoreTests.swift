import EstateSaleCore
import XCTest

@MainActor
final class EstateSaleCoreTests: XCTestCase {
    func testApproveLeavesNeedsPhotoItemsBlocked() async throws {
        let model = SellerAppModel(repository: MockEstateSaleRepository())

        try await model.load()

        let needsPhotoID = model.reviewQueue.first(where: { $0.needsPhoto })!.id
        model.approve(itemID: needsPhotoID)

        XCTAssertEqual(model.reviewQueue.first(where: { $0.id == needsPhotoID })?.state, .needsPhoto)
    }

    func testApprovePromotesReviewableItems() async throws {
        let model = SellerAppModel(repository: MockEstateSaleRepository())

        try await model.load()

        let reviewableID = model.reviewQueue.first(where: { !$0.needsPhoto })!.id
        model.approve(itemID: reviewableID)

        XCTAssertEqual(model.reviewQueue.first(where: { $0.id == reviewableID })?.state, .approved)
    }

    func testPublishableCountReflectsApprovedLowRiskItems() async throws {
        let model = SellerAppModel(repository: MockEstateSaleRepository())

        try await model.load()

        XCTAssertEqual(model.publishableCount, 1)
    }
}
