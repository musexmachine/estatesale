import EstateSaleCore
import SwiftUI

public struct SellerDashboardView: View {
    @State private var model: SellerAppModel

    public init(model: SellerAppModel = SellerAppModel()) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    intakeCard
                    reviewCard
                    fulfillmentCard
                }
                .padding(20)
            }
            .navigationTitle("EstateSale")
            .task {
                if model.properties.isEmpty {
                    try? await model.load()
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seller Workflow")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(model.properties.first?.name ?? "Loading estate...")
                .font(.largeTitle.bold())
            Text("One property, one intake flow, one review queue, one set of fulfillment tools.")
                .foregroundStyle(.secondary)

            HStack {
                metric(title: "Review", value: "\(model.reviewQueue.count)")
                metric(title: "Ready", value: "\(model.publishableCount)")
                metric(title: "Orders", value: "\(model.orders.count)")
            }
        }
        .padding(20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var intakeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Intake")
                .font(.title2.bold())
            Text("Choose the lightweight capture mode first, then use the other only to rescue weak detections.")
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                intakeButton(title: "Take Photos", subtitle: "Single-item rescue shots and label closeups")
                intakeButton(title: "Record Walkaround", subtitle: "Room-scale intake for multi-item passes")
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review Queue")
                .font(.title2.bold())
            ForEach(model.reviewQueue) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.title)
                            .font(.headline)
                        Spacer()
                        Text(item.state.rawValue.replacingOccurrences(of: "_", with: " "))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.12), in: Capsule())
                    }

                    Text(item.conditionSummary)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("Confidence \(Int(item.confidence * 100))%")
                        Spacer()
                        Text(item.fulfillmentMode.rawValue.replacingOccurrences(of: "_", with: " "))
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    HStack {
                        Button("Looks Good") {
                            model.approve(itemID: item.id)
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Not Selling") {
                            model.reject(itemID: item.id)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var fulfillmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fulfillment")
                .font(.title2.bold())
            ForEach(model.orders) { order in
                HStack {
                    VStack(alignment: .leading) {
                        Text(order.buyerName)
                            .font(.headline)
                        Text(order.fulfillmentMode.rawValue.replacingOccurrences(of: "_", with: " "))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(order.salePriceCents, format: .currency(code: "USD"))
                }
                .padding(.vertical, 6)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func intakeButton(title: String, subtitle: String) -> some View {
        Button {
            // App shell wiring comes next; the feature package keeps the seller-facing flows testable now.
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}
