//
//  ReceiverOrderDetailView.swift
//  IoTTesting
//

import CoreBluetooth
import SwiftUI

struct ReceiverOrderDetailView: View {
    let orderId: String

    @StateObject private var viewModel = ReceiverOrderDetailViewModel()
    @StateObject private var centralVM = CentralViewModel()

    @State private var showPickupCodeSheet = false
    @State private var bleErrorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Loading order...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else if let order = viewModel.order {
                    orderInfoSection(order: order)
                    bleSection(order: order)
                    pickupStateSection
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .navigationTitle("Pick Up Package")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.fetchOrderDetail(id: orderId)
        }
    }

    // MARK: - Order info

    private func orderInfoSection(order: Order) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Order Details")

            InfoRowView(label: "Recipient", value: order.recipientName)
            InfoRowView(label: "Locker", value: "Locker \(order.lockerNumber)")
            if let detail = order.lockerDetail {
                InfoRowView(label: "Location", value: detail)
            }
            if let description = order.packageDescription {
                InfoRowView(label: "Package", value: description)
            }
            if let tracking = order.trackingNumber {
                InfoRowView(label: "Tracking", value: tracking)
            }
            InfoRowView(label: "Status", value: order.status?.rawValue.replacingOccurrences(of: "_", with: " ").capitalized ?? "—")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Pickup code

    private func pickupCodeSection(order: Order) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Pickup Code")

            if let code = order.pickupUnlockCode {
                HStack {
                    Text(code)
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                        .tracking(8)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = code
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(.blue)
                    }
                }
                Text("Share this 6-digit code only with the courier if requested.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Pickup code not yet available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - BLE section

    private func bleSection(order: Order) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Bluetooth Connection")

            HStack {
                Circle()
                    .fill(centralVM.isBluetoothOn ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(centralVM.isBluetoothOn ? "Bluetooth On" : "Bluetooth Off")
                    .font(.subheadline)
            }

            if centralVM.isBluetoothOn {
                if centralVM.discoveredPeripherals.isEmpty {
                    Text("Scanning for ESP32-CAM...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Select your locker device:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(centralVM.discoveredPeripherals, id: \.identifier) { peripheral in
                        Button {
                            centralVM.connect(peripheral, order: order)
                        } label: {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundStyle(.blue)
                                Text(peripheral.name ?? peripheral.identifier.uuidString)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if centralVM.connectedPeripheral?.identifier == peripheral.identifier {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                        }
                    }
                }

                if let connectedPeripheral = centralVM.connectedPeripheral {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Connected to \(connectedPeripheral.name ?? "device")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.top, 4)
                }
            }

            if let bleError = bleErrorMessage {
                Text(bleError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Pickup state / action

    private var pickupStateSection: some View {
        VStack(spacing: 16) {
            switch viewModel.pickupState {
            case .idle, .loadingOrder, .waitingForBLE:
                pickupButton

            case .sendingPayload:
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Sending unlock payload...")
                        .font(.subheadline)
                }

            case .confirmingPickup:
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Confirming pickup with server...")
                        .font(.subheadline)
                }

            case .success(let message):
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("Pickup Confirmed!")
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()

            case .failure(let message):
                VStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.red)
                    Text("Pickup Failed")
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    PrimaryButton(title: "Try Again") {
                        viewModel.pickupState = .idle
                        bleErrorMessage = nil
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
    }

    private var pickupButton: some View {
        let canPickUp = centralVM.connectedPeripheral != nil
            && viewModel.order?.pickupUnlockCode != nil
            && viewModel.pickupState != .sendingPayload
            && viewModel.pickupState != .confirmingPickup

        return PrimaryButton(title: canPickUp ? "Pick Up Package" : "Connect to Locker First") {
            guard canPickUp else { return }
            initiatePickup()
        }
        .opacity(canPickUp ? 1.0 : 0.5)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pickup orchestration

    private func initiatePickup() {
        bleErrorMessage = nil
        viewModel.pickupState = .sendingPayload

        do {
            let encryptedPayload = try viewModel.generateEncryptedPayload()
            centralVM.sendText(encryptedPayload)
            // After BLE write, proceed to server confirmation
            viewModel.confirmPickup()
        } catch {
            bleErrorMessage = error.localizedDescription
            viewModel.pickupState = .failure(message: error.localizedDescription)
        }
    }
}

// MARK: - Shared helper subviews

private struct SectionHeaderView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

private struct InfoRowView: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        ReceiverOrderDetailView(orderId: "preview-order-id")
    }
}
