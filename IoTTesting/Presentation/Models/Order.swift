//
//  Order.swift
//  IoTTesting
//
//  Created by Patrick Samuel Owen Saritua Sinaga on 16/04/26.
//

import Foundation

struct OrderResponse: Codable, Hashable {
    let orders: [Order]
    let total: Int?
    let limit: Int?
    let offset: Int?
}

struct Order: Codable, Identifiable, Hashable {
    let id: String
    let lockerId: String?
    let lockerServerId: String?
    let lockerNumber: Int
    let lockerDetail: String?
    let lockerPublicKey: String
    let status: OrderStatus?
    let recipientName: String
    let courierName: String?
    let packageDescription: String?
    let trackingNumber: String?
    let dropUnlockCode: String?
    let pickupUnlockCode: String?

    // Timestamps
    let createdAt: String?
    let expiresAt: String?
    let deliveredAt: String?
    let pickedUpAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case lockerId = "locker_id"
        case lockerServerId = "locker_server_id"
        case lockerNumber = "locker_number"
        case lockerDetail = "locker_detail"
        case lockerPublicKey = "locker_public_key"
        case status
        case recipientName = "recipient_name"
        case courierName = "courier_name"
        case packageDescription = "package_description"
        case trackingNumber = "tracking_number"
        case dropUnlockCode = "drop_unlock_code"
        case pickupUnlockCode = "pickup_unlock_code"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case deliveredAt = "delivered_at"
        case pickedUpAt = "picked_up_at"
    }
}

enum LockerState: String, Codable, Hashable {
    case available
    case assigned
    case waitingForDrop = "waiting_for_drop"
    case occupied
    case waitingForPickup = "waiting_for_pickup"
    case maintenance
}

enum OrderStatus: String, Codable, Hashable {
    case created
    case waitingForDrop = "waiting_for_drop"
    case delivering
    case delivered
    case waitingForPickup = "waiting_for_pickup"
    case pickingUp = "picking_up"
    case pickedUp = "picked_up"
    case expired
    case cancelled
}
