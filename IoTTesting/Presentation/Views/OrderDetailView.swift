//
//  OrderDetailView.swift
//  IoTTesting
//
//  Created by Patrick Samuel Owen Saritua Sinaga on 16/04/26.
//

import CoreBluetooth
import SwiftUI

struct OrderDetailView: View {
    let orderId: String

    @StateObject private var viewModel: OrderDetailViewModel
    @StateObject private var centralVM = CentralViewModel()

    @State private var courierStep: CourierFlowStep = .connectAndSend
    @State private var bleErrorMessage: String?

    init(orderId: String) {
        self.orderId = orderId
        _viewModel = StateObject(wrappedValue: OrderDetailViewModel())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Loading order...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else if let order = viewModel.order {
                    orderInfoSection(order: order)

                    switch courierStep {
                    case .connectAndSend:
                        connectAndSendSection(order: order)
                    case .completeDrop:
                        completeDropSection(order: order)
                    case .completed:
                        completedSection
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                if let bleError = bleErrorMessage {
                    Text(bleError)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .navigationTitle("Delivery")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.fetchOrderDetail(id: orderId)
        }
        .onChange(of: viewModel.order) { _, order in
            guard let order else { return }
            courierStep = CourierFlowStep(for: order.status)

            // Start automatic BLE scan with order context
            centralVM.startScan(with: order)
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
            if let courier = order.courierName {
                InfoRowView(label: "Courier", value: courier)
            }
            if let server = order.lockerServer, let location = server.location {
                InfoRowView(label: "Server", value: location)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Step 1: Connect & Send

    private func connectAndSendSection(order: Order) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Step 1: Connect & Unlock Locker")

            // Bluetooth status
            HStack {
                Circle()
                    .fill(centralVM.isBluetoothOn ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(centralVM.isBluetoothOn ? "Bluetooth On" : "Bluetooth Off")
                    .font(.subheadline)
            }

            if centralVM.isBluetoothOn {
                // Peripheral list
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

                // Connection status
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

                // Send code button
                if centralVM.connectedPeripheral != nil {
                    PrimaryButton(title: viewModel.isSendingCode ? "Sending..." : "Send Unlock Code") {
                        guard !viewModel.isSendingCode else { return }
                        sendCode(order: order)
                    }
                    .disabled(viewModel.isSendingCode)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Step 2: Complete Drop

    private func completeDropSection(order: Order) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Success indicator
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
                Text("Unlock code sent successfully")
                    .font(.headline)
                    .foregroundStyle(.green)
            }
            .padding(.bottom, 4)

            Divider()

            SectionHeaderView(title: "Step 2: Confirm Package Drop")

            VStack(alignment: .leading, spacing: 8) {
                Text("📦 Place the package in Locker \(order.lockerNumber)")
                    .font(.subheadline)

                Text("🔒 Close the locker door securely")
                    .font(.subheadline)

                Text("✅ Tap \"Complete Drop\" to confirm delivery")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let response = viewModel.dropCompleteResponse {
                if response.bothConfirmed {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        Text("Delivery Confirmed!")
                            .font(.headline)
                        Text(response.message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                courierStep = .completed
                            }
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.orange)
                        Text("Waiting for Pi Confirmation")
                            .font(.headline)
                        Text(response.message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()

                    PrimaryButton(title: "Check Status Again") {
                        viewModel.completeDrop(
                            orderId: order.id,
                            lockerNumber: order.lockerNumber,
                            lockerId: order.lockerId ?? ""
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            } else if viewModel.isCompletingDrop {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Confirming drop with server...")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if let error = viewModel.dropError {
                VStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.red)
                    Text("Failed to confirm drop")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    PrimaryButton(title: "Try Again") {
                        viewModel.completeDrop(
                            orderId: order.id,
                            lockerNumber: order.lockerNumber,
                            lockerId: order.lockerId ?? ""
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                PrimaryButton(title: "Complete Drop") {
                    viewModel.completeDrop(
                        orderId: order.id,
                        lockerNumber: order.lockerNumber,
                        lockerId: order.lockerId ?? ""
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Step 3: Completed

    private var completedSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Drop Complete!")
                .font(.title2)
                .fontWeight(.bold)
            Text("The package has been delivered to the locker.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Send code

    private func sendCode(order: Order) {
        bleErrorMessage = nil

        do {
            let encryptedPayload = try viewModel.generateEncryptedPayload()
            centralVM.sendText(encryptedPayload)

            // Transition to complete drop step
            withAnimation {
                courierStep = .completeDrop
            }
        } catch {
            bleErrorMessage = error.localizedDescription
        }
    }
}

// MARK: - Shared helper subviews (duplicated from ReceiverOrderDetailView for availability)

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

// MARK: - Flow step

private enum CourierFlowStep {
    case connectAndSend
    case completeDrop
    case completed

    init(for status: OrderStatus?) {
        guard let status else {
            self = .connectAndSend
            return
        }
        switch status {
        case .created, .waitingForDrop:
            self = .connectAndSend
        case .delivering:
            self = .completeDrop
        default:
            self = .completed
        }
    }
}

#Preview {
    NavigationStack {
        OrderDetailView(orderId: "preview-order-id")
    }
}
