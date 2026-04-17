//
//  OrdersViewModel.swift
//  IoTTesting
//
//  Created by Patrick Samuel Owen Saritua Sinaga on 16/04/26.
//

import Foundation
import Combine
import Alamofire

@MainActor
final class OrdersViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    func fetchOrders() {
        isLoading = true
        errorMessage = nil

        APIManager.shared.ordersPublisher()
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.isLoading = false
                    //TODO: handle error here
                    print("--- error: \(error)")
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.isLoading = false
                self.orders = response
            }
            .store(in: &cancellables)

    }
}
