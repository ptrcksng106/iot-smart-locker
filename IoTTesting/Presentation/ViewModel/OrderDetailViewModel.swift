//
//  OrderDetailViewModel.swift
//  IoTTesting
//
//  Created by Patrick Samuel Owen Saritua Sinaga on 16/04/26.
//

import Foundation
import Combine

final class OrderDetailViewModel: ObservableObject {
    @Published var order: Order? = nil
    @Published var videos: [VideoRecording] = []
    @Published var logs: [DeliveryLog] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    // MARK: - Complete drop state

    @Published var isSendingCode = false
    @Published var codeSentSuccessfully = false
    @Published var isCompletingDrop = false
    @Published var dropCompleteResponse: CompleteDropResponse? = nil
    @Published var dropError: String? = nil

    private var cancellables = Set<AnyCancellable>()
    
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
                    //TODO: handle error here
                    print("--- error: \(error)")
                }
            } receiveValue: { [weak self] response in
                print("--- response: \(response)")
                self?.order = response.order
                self?.videos = response.videos
                self?.logs = response.logs
            }
            .store(in: &cancellables)
    }

    // MARK: - Encryption delegate

    /// Validates order data and encrypts the drop unlock code via LockerPayloadEncryptor.
    /// - Returns: base64url-encoded encrypted payload string
    func generateEncryptedPayload() throws -> String {
        guard let unlockCode = order?.dropUnlockCode, !unlockCode.isEmpty else {
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

    // MARK: - Complete drop

    func completeDrop(orderId: String, lockerNumber: Int, lockerId: String) {
        isCompletingDrop = true
        dropError = nil

        APIManager.shared.completeDropPublisher(
            orderId: orderId,
            lockerNumber: lockerNumber,
            lockerId: lockerId
        )
        .sink { [weak self] completion in
            self?.isCompletingDrop = false
            if case .failure(let error) = completion {
                self?.dropError = error.localizedDescription
            }
        } receiveValue: { [weak self] response in
            self?.dropCompleteResponse = response
        }
        .store(in: &cancellables)
    }
}
