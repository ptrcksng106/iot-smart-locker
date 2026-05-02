//
//  LockerPayloadEncryptor.swift
//  IoTTesting
//

import Foundation
import Security

enum LockerPayloadEncryptor {
    enum Error: Swift.Error, LocalizedError {
        case invalidPublicKey
        case encryptionFailed

        var errorDescription: String? {
            switch self {
            case .invalidPublicKey: return "Could not import the locker public key."
            case .encryptionFailed: return "Payload encryption failed."
            }
        }
    }

    /// Generate RSA-OAEP SHA-256 encrypted payload for verify-payload endpoint.
    /// - Parameters:
    ///   - unlockCode: 6-digit code from create-order / complete-drop response
    ///   - publicKeyBase64: locker_public_key from create-order response
    /// - Returns: base64url-encoded encrypted payload string
    static func encrypt(unlockCode: String, publicKeyBase64: String) throws -> String {
        // 1. Decode base64 PEM -> DER (strip PEM headers)
        let pem = String(
            data: Data(base64Encoded: publicKeyBase64, options: .ignoreUnknownCharacters)!,
            encoding: .utf8
        )!

        let derBase64 = pem
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard let derData = Data(base64Encoded: derBase64) else {
            throw Error.invalidPublicKey
        }

        // 2. Import public key (SPKI/DER format)
        let keyAttrs: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 2048,
        ]
        var cfError: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(derData as CFData, keyAttrs as CFDictionary, &cfError) else {
            throw Error.invalidPublicKey
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
            throw Error.encryptionFailed
        }
        guard let encrypted = SecKeyCreateEncryptedData(secKey, algorithm, payloadData as CFData, &cfError) else {
            throw Error.encryptionFailed
        }

        // 5. base64url encode (no padding)
        let base64url = (encrypted as Data)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        return base64url
    }
}
