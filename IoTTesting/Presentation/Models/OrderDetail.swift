//
//  OrderDetail.swift
//  IoTTesting
//
//  Created by Patrick Samuel Owen Saritua Sinaga on 16/04/26.
//

import Foundation

struct OrderDetailResponse: Codable {
    let order: Order
    let videos: [VideoRecording]
    let logs: [DeliveryLog]
}

struct VideoRecording: Codable, Identifiable, Hashable {
    let id: String
    let orderId: String?
    let lockerId: String?
    let lockerServerId: String?
    let recordingType: String
    let filePath: String?
    let fileSizeBytes: Int64?
    let durationSeconds: Int?
    let cloudUrl: String?
    let uploadedAt: String?
    let startedAt: String?
    let stoppedAt: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case lockerId = "locker_id"
        case lockerServerId = "locker_server_id"
        case recordingType = "recording_type"
        case filePath = "file_path"
        case fileSizeBytes = "file_size_bytes"
        case durationSeconds = "duration_seconds"
        case cloudUrl = "cloud_url"
        case uploadedAt = "uploaded_at"
        case startedAt = "started_at"
        case stoppedAt = "stopped_at"
        case createdAt = "created_at"
    }
}

struct DeliveryLog: Codable, Identifiable, Hashable {
    let id: String
    let orderId: String?
    let lockerId: String?
    let lockerServerId: String?
    let source: String
    let eventType: String
    let success: Bool?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case lockerId = "locker_id"
        case lockerServerId = "locker_server_id"
        case source
        case eventType = "event_type"
        case success
        case createdAt = "created_at"
    }
}
