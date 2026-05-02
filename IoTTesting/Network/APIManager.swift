//
//  APIManager.swift
//  IoTTesting
//
//  Created by Patrick Samuel Owen Saritua Sinaga on 16/04/26.
//

import Foundation
import Alamofire
import Combine

// MARK: - Request / Response models

struct CompletePickupRequest: Encodable {
    let orderId: String
    let source: String
    let lockerNumber: Int
    let lockerId: String

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case source
        case lockerNumber = "locker_number"
        case lockerId = "locker_id"
    }
}

struct CompletePickupResponse: Decodable {
    let status: String
    let bothConfirmed: Bool
    let message: String

    enum CodingKeys: String, CodingKey {
        case status
        case bothConfirmed = "both_confirmed"
        case message
    }
}

struct CompleteDropRequest: Encodable {
    let orderId: String
    let source: String
    let lockerNumber: Int
    let lockerId: String

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case source
        case lockerNumber = "locker_number"
        case lockerId = "locker_id"
    }
}

struct CompleteDropResponse: Decodable {
    let status: String
    let bothConfirmed: Bool
    let message: String

    enum CodingKeys: String, CodingKey {
        case status
        case bothConfirmed = "both_confirmed"
        case message
    }
}

// MARK: -

final class APIManager {
    static let shared = APIManager()
    private init() {}

    private let baseURL = URL(string: "https://rqcjrdnoalyhnzeagrxo.functions.supabase.co")!
//    private let baseURL = URL(string: "http://192.168.18.242:54321/functions/v1/")!

    private let bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxY2pyZG5vYWx5aG56ZWFncnhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0NzU4NTUsImV4cCI6MjA5MTA1MTg1NX0.nQGi0_FDw8-TROqZFBwX90rqcxzwXd3SkImdXwwjS_Q"

    private var defaultHeaders: HTTPHeaders {
        [
            "Authorization": "Bearer \(bearerToken)",
            "apikey": bearerToken,
            "Accept": "application/json"
        ]
    }

    // MARK: - Courier endpoints

    /// Fetches all orders (no status filter) — used by the courier flow.
    func ordersPublisher() -> AnyPublisher<[Order], AFError> {
        let url = baseURL.appendingPathComponent("orders")
        return AF.request(url, method: .get, headers: defaultHeaders)
            .validate(statusCode: 200..<300)
            .publishDecodable(type: OrderResponse.self)
            .value()
            .map(\.orders)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func orderDetailPublisher(orderId: String) -> AnyPublisher<OrderDetailResponse, AFError> {
        let url = baseURL
            .appendingPathComponent("orders")
            .appendingPathComponent(orderId)

        return AF.request(url, method: .get, headers: defaultHeaders)
            .validate(statusCode: 200..<300)
            .publishDecodable(type: OrderDetailResponse.self)
            .value()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Receiver endpoints

    /// Fetches orders filtered by the given status — used by the receiver flow.
    func ordersPublisher(status: String) -> AnyPublisher<[Order], AFError> {
        let url = baseURL.appendingPathComponent("orders")
        let parameters: Parameters = ["status": status]
        return AF.request(url, method: .get, parameters: parameters, headers: defaultHeaders)
            .validate(statusCode: 200..<300)
            .publishDecodable(type: OrderResponse.self)
            .value()
            .map(\.orders)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Confirms package drop — called after the courier's BLE unlock completes.
    /// Sends source=courier as a query parameter AND the order details in the JSON body.
    func completeDropPublisher(
        orderId: String,
        lockerNumber: Int,
        lockerId: String
    ) -> AnyPublisher<CompleteDropResponse, AFError> {
        var components = URLComponents(url: baseURL.appendingPathComponent("complete-drop"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "source", value: "courier")]

        let body = CompleteDropRequest(
            orderId: orderId,
            source: "courier",
            lockerNumber: lockerNumber,
            lockerId: lockerId
        )
        return AF.request(
            components?.url ?? baseURL.appendingPathComponent("complete-drop"),
            method: .post,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers: defaultHeaders
        )
        .validate(statusCode: 200..<300)
        .publishDecodable(type: CompleteDropResponse.self)
        .value()
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    /// Confirms package pickup — called after the receiver's BLE unlock completes.
    func completePickupPublisher(
        orderId: String,
        lockerNumber: Int,
        lockerId: String
    ) -> AnyPublisher<CompletePickupResponse, AFError> {
        let url = baseURL.appendingPathComponent("complete-pickup")
        let body = CompletePickupRequest(
            orderId: orderId,
            source: "receiver_app",
            lockerNumber: lockerNumber,
            lockerId: lockerId
        )
        return AF.request(
            url,
            method: .post,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers: defaultHeaders
        )
        .validate(statusCode: 200..<300)
        .publishDecodable(type: CompletePickupResponse.self)
        .value()
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
