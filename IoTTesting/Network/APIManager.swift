//
//  APIManager.swift
//  IoTTesting
//
//  Created by Patrick Samuel Owen Saritua Sinaga on 16/04/26.
//

import Foundation
import Alamofire
import Combine

final class APIManager {
    static let shared = APIManager()
    private init() {}
    
//    private let baseURL = URL(string: "https://rqcjrdnoalyhnzeagrxo.functions.supabase.co")!
    private let baseURL = URL(string: "http://192.168.18.230:54321/functions/v1/")!
    
    private let bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxY2pyZG5vYWx5aG56ZWFncnhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0NzU4NTUsImV4cCI6MjA5MTA1MTg1NX0.nQGi0_FDw8-TROqZFBwX90rqcxzwXd3SkImdXwwjS_Q"
    
    private var defaultHeaders: HTTPHeaders {
        [
            "Authorization": "Bearer \(bearerToken)",
            "apikey": bearerToken,
            "Accept": "application/json"
        ]
    }
    
    func ordersPublisher() -> AnyPublisher<[Order], AFError> {
        let url = baseURL.appendingPathComponent("orders")
        return AF.request(url, method: .get, headers: defaultHeaders)
            .validate(statusCode: 200..<300)
            .publishDecodable(type: OrderResponse.self)
            .value()
            .map { response in
                return response.orders
            }
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
}
