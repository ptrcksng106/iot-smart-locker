//
//  OrderDetailView.swift
//  IoTTesting
//
//  Created by Patrick Samuel Owen Saritua Sinaga on 16/04/26.
//

import SwiftUI

struct OrderDetailView: View {
    let orderId: String
    @StateObject private var viewModel: OrderDetailViewModel
    
    init(orderId: String) {
        self.orderId = orderId
        _viewModel = StateObject(wrappedValue: OrderDetailViewModel())
    }
    
    var body: some View {
        ScrollView {
            VStack {
                Text(viewModel.order?.lockerDetail ?? "")
            }
        }
        .task {
            viewModel.fetchOrderDetail(id: orderId)
        }
    }
}
