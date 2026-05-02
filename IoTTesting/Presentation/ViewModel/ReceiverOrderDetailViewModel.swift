//
//  ReceiverOrderDetailViewModel.swift
//  IoTTesting
//

import Foundation
import Combine

// MARK: - Pickup state machine

enum PickupState: Equatable {
    case idle
    case loadingOrder
    case waitingForBLE          // order loaded, tapped "Pick Up", waiting for BLE send
    case sendingPayload         // writing encrypted payload to BLE characteristic
    case confirmingPickup       // calling POST /complete-pickup
    case success(message: String)
    case failure(message: String)
}

final class ReceiverOrderDetailViewModel: ObservableObject {
    @Published var order: Order?
    @Published var videos: [VideoRecording] = []
    @Published var logs: [DeliveryLog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var pickupState: PickupState = .idle
    @Published var pickupResponse: CompletePickupResponse?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Fetch order detail

    func fetchOrderDetail(id: String) {
        isLoading = true
        errorMessage = nil

        APIManager.shared.orderDetailPublisher(orderId: id)
            .sink { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("ReceiverOrderDetailViewModel error: \(error)")
                }
            } receiveValue: { [weak self] response in
                self?.order = response.order
                self?.videos = response.videos
                self?.logs = response.logs
            }
            .store(in: &cancellables)
    }

    // MARK: - Payload encryption

    /// Builds and RSA-OAEP SHA-256 encrypts the pickup payload.
    /// Returns a base64url-encoded string ready to be written to the BLE characteristic.
    func generateEncryptedPayload() throws -> String {
        guard let unlockCode = order?.pickupUnlockCode, !unlockCode.isEmpty else {
            throw LockerPayloadEncryptor.Error.invalidPublicKey
        }
        guard let publicKeyBase64 = order?.lockerPublicKey, !publicKeyBase64.isEmpty else {
            throw LockerPayloadEncryptor.Error.invalidPublicKey
        }
        return try LockerPayloadEncryptor.encrypt(
            unlockCode: unlockCode,
            publicKeyBase64: publicKeyBase64
        )
    }

    // MARK: - Confirm pickup with backend

    func confirmPickup() {
        guard let order else {
            pickupState = .failure(message: "Order data is missing.")
            return
        }
        guard let lockerId = order.lockerId else {
            pickupState = .failure(message: "Locker ID is missing from the order.")
            return
        }

        pickupState = .confirmingPickup

        APIManager.shared.completePickupPublisher(
            orderId: order.id,
            lockerNumber: order.lockerNumber,
            lockerId: lockerId
        )
        .sink { [weak self] completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                self?.pickupState = .failure(message: error.localizedDescription)
                print("completePickup error: \(error)")
            }
        } receiveValue: { [weak self] response in
            self?.pickupResponse = response
            self?.pickupState = .success(message: response.message)
        }
        .store(in: &cancellables)
    }
}
