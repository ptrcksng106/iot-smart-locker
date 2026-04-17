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
    let status: OrderStatus?
    let lockerPublicKey: String
    let lockerDetail: String?
    let lockerServerUuid: String?
    let recipientName: String
    let recipientPhone: String?
    let recipientEmail: String?
    let courierName: String?
    let courierPhone: String?
    let packageDescription: String?
    let trackingNumber: String?
    
    // Timestamps
    let courierConfirmedAt: String?
    let piDropConfirmedAt: String?
    let receiverConfirmedAt: String?
    let piPickupConfirmedAt: String?
    let createdAt: String?
    let updatedAt: String?
    let deliveredAt: String?
    let pickedUpAt: String?
    let expiresAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case lockerId = "locker_id"
        case lockerServerId = "locker_server_id"
        case lockerNumber = "locker_number"
        case status
        case lockerPublicKey = "locker_public_key"
        case lockerDetail = "locker_detail"
        case lockerServerUuid = "locker_server_uuid"
        case recipientName = "recipient_name"
        case recipientPhone = "recipient_phone"
        case recipientEmail = "recipient_email"
        case courierName = "courier_name"
        case courierPhone = "courier_phone"
        case packageDescription = "package_description"
        case trackingNumber = "tracking_number"
        
        case courierConfirmedAt = "courier_confirmed_at"
        case piDropConfirmedAt = "pi_drop_confirmed_at"
        case receiverConfirmedAt = "receiver_confirmed_at"
        case piPickupConfirmedAt = "pi_pickup_confirmed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deliveredAt = "delivered_at"
        case pickedUpAt = "picked_up_at"
        case expiresAt = "expires_at"
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
