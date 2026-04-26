//
//  OrderDetailViewModel.swift
//  IoTTesting
//
//  Created by Patrick Samuel Owen Saritua Sinaga on 16/04/26.
//

import Foundation
import Security
import Combine

final class OrderDetailViewModel: ObservableObject {
    @Published var order: Order? = nil
    @Published var videos: [VideoRecording] = []
    @Published var logs: [DeliveryLog] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
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
    
    enum LockerPayloadError: Error {
        case invalidPublicKey
        case encryptionFailed
    }
    
    /// Generate RSA-OAEP SHA-256 encrypted payload for verify-payload endpoint.
    /// - Parameters:
    ///   - unlockCode: 6-digit code from create-order / complete-drop response
    ///   - publicKeyBase64: locker_public_key from create-order response
    /// - Returns: base64url-encoded encrypted payload string
    func generateEncryptedPayload(unlockCode: String, publicKeyBase64: String) throws -> String {
        // 1. Decode base64 PEM → DER (strip PEM headers)
        let pem = String(data: Data(base64Encoded: publicKeyBase64, options: .ignoreUnknownCharacters)!, encoding: .utf8)!
        
//        let hardcodedPEM = """
//        -----BEGIN PUBLIC KEY-----
//        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlIMPHwD3lyGgUVUrBkx/
//        Bo8SJ0MuN5fZk/s/L86W43iUmOuAK8L1A9h+28p1SXKNiSo6dD/GMuZLMaJ97JyL
//        9KRkSEOagh0A7SCISAzPyOdpdUysrPK+lVbrE6lX79J58SFAGekEcRlokgspjgdg
//        BU3b57ylT8B3Uh5C02rB2Vyh1x0e3IhEtQgbYNYx7UC040t2b+VDdddNqVvI/Ded
//        h3qw+9pn0s8OrPnRBgZY2etq5QqS1cn7pPijrdlmR65fJmY1T6Q5HfTiX+e2T9zE
//        LUfAjGu8gV8kk+xKJ1fJcjY9kzkcode3EDfoMVImPvUuVd5BfiAPyfP96TZDz1v6
//        hQIDAQAB
//        -----END PUBLIC KEY-----
//        """
        
        let derBase64 = pem
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        guard let derData = Data(base64Encoded: derBase64) else {
            throw LockerPayloadError.invalidPublicKey
        }
        
        // 2. Import public key (SPKI/DER format)
        let keyAttrs: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 2048,
        ]
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(derData as CFData, keyAttrs as CFDictionary, &error) else {
            throw LockerPayloadError.invalidPublicKey
        }
        
        // 3. Build payload JSON
        let payload: [String: Any] = [
            "unlock_code": unlockCode,
            "nonce": UUID().uuidString,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
        ]
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        
        // 4. Encrypt RSA-OAEP SHA-256
        let algorithm = SecKeyAlgorithm.rsaEncryptionOAEPSHA256
        guard SecKeyIsAlgorithmSupported(secKey, .encrypt, algorithm) else {
            throw LockerPayloadError.encryptionFailed
        }
        guard let encrypted = SecKeyCreateEncryptedData(secKey, algorithm, payloadData as CFData, &error) else {
            throw LockerPayloadError.encryptionFailed
        }
        
        // 5. base64url encode (no padding)
        let base64url = (encrypted as Data).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        return base64url
    }
}
