//
//  ReceiverOrdersView.swift
//  IoTTesting
//

import SwiftUI

struct ReceiverOrdersView: View {
    @StateObject private var viewModel = ReceiverOrdersViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading packages...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else if viewModel.readyForPickupOrders.isEmpty && viewModel.deliveredOrders.isEmpty {
                    emptyView
                } else {
                    orderList
                }
            }
            .navigationTitle("Pick Up Package")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.fetchOrders()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                viewModel.fetchOrders()
            }
        }
    }

    private var orderList: some View {
        List {
            if !viewModel.readyForPickupOrders.isEmpty {
                Section("Ready for Pickup") {
                    ForEach(viewModel.readyForPickupOrders) { order in
                        NavigationLink {
                            ReceiverOrderDetailView(orderId: order.id)
                        } label: {
                            ReceiverOrderRowView(order: order)
                        }
                    }
                }
            }

            if !viewModel.deliveredOrders.isEmpty {
                Section("History") {
                    ForEach(viewModel.deliveredOrders) { order in
                        NavigationLink {
                            ReceiverOrderDetailView(orderId: order.id)
                        } label: {
                            ReceiverOrderRowView(order: order)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No packages waiting for pickup")
                .font(.headline)
                .foregroundStyle(.secondary)
            PrimaryButton(title: "Refresh") {
                viewModel.fetchOrders()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Something went wrong")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            PrimaryButton(title: "Retry") {
                viewModel.fetchOrders()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Row

private struct ReceiverOrderRowView: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Locker \(order.lockerNumber)", systemImage: "lock.rectangle")
                    .font(.headline)
                Spacer()
                statusBadge
            }
            if let description = order.packageDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            HStack(spacing: 4) {
                Image(systemName: "person.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(order.recipientName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        Text(order.status?.displayName ?? "Unknown")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch order.status {
        case .created:          return .blue
        case .waitingForDrop:   return .orange
        case .delivering:       return .purple
        case .delivered:        return .green
        case .waitingForPickup: return .blue
        case .pickingUp:        return .orange
        case .pickedUp:         return .green
        case .expired:          return .red
        case .cancelled:        return .red
        case .unknown:          return .gray
        case .none:             return .gray
        }
    }
}

// MARK: - OrderStatus display helper

private extension OrderStatus {
    var displayName: String {
        switch self {
        case .created:          return "Created"
        case .waitingForDrop:   return "Waiting for Drop"
        case .delivering:       return "Delivering"
        case .delivered:        return "Delivered"
        case .waitingForPickup: return "Ready for Pickup"
        case .pickingUp:        return "Picking Up"
        case .pickedUp:         return "Picked Up"
        case .expired:          return "Expired"
        case .cancelled:        return "Cancelled"
        case .unknown:          return "Unknown"
        }
    }
}

#Preview {
    ReceiverOrdersView()
}
