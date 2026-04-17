//
//  LockerView.swift
//  IoTTesting
//
//  Created by Patrick Samuel Owen Saritua Sinaga on 16/04/26.
//

import SwiftUI

struct LockerView: View {
    @StateObject private var viewModel = OrdersViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                ZStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                    
                    ForEach(viewModel.orders, id: \.self) { order in
                        NavigationLink {
                            OrderDetailView(orderId: order.lockerServerUuid ?? "")
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(String(order.lockerNumber))
                                            .foregroundStyle(.black)
                                            .font(.headline)
                                        
                                        Text(order.lockerServerUuid ?? "")
                                            .foregroundStyle(.black)
                                            .font(.subheadline)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.black)
                                }
                            }
                        }
                    }
                }
                
                PrimaryButton(title: "Get Lockers") {
                    viewModel.fetchOrders()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .navigationTitle("Smart Locker")
            .padding()
        }
    }
}

#Preview {
    LockerView()
}

