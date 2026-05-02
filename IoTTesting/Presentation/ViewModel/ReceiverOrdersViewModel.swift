//
//  ReceiverOrdersViewModel.swift
//  IoTTesting
//

import Foundation
import Combine
import Alamofire

@MainActor
final class ReceiverOrdersViewModel: ObservableObject {
    @Published var readyForPickupOrders: [Order] = []
    @Published var deliveredOrders: [Order] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    func fetchOrders() {
        isLoading = true
        errorMessage = nil

        Publishers.Zip(
            APIManager.shared.ordersPublisher(status: "waiting_for_pickup"),
            APIManager.shared.ordersPublisher(status: "delivered")
        )
        .sink { [weak self] completion in
            switch completion {
            case .failure(let error):
                self?.isLoading = false
                self?.errorMessage = error.localizedDescription
                print("ReceiverOrdersViewModel error: \(error)")
            case .finished:
                break
            }
        } receiveValue: { [weak self] readyOrders, delivered in
            guard let self else { return }
            self.isLoading = false
            self.readyForPickupOrders = readyOrders
            self.deliveredOrders = delivered
        }
        .store(in: &cancellables)
    }
}
