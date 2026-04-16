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
}
