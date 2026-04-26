//
//  OrderDetailView.swift
//  IoTTesting
//
//  Created by Patrick Samuel Owen Saritua Sinaga on 16/04/26.
//

import CoreBluetooth
import SwiftUI

struct OrderDetailView: View {
    let orderId: String
    
    @StateObject private var viewModel: OrderDetailViewModel
    @StateObject private var centralVM = CentralViewModel()
    
    init(orderId: String) {
        self.orderId = orderId
        _viewModel = StateObject(wrappedValue: OrderDetailViewModel())
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(viewModel.order?.lockerDetail ?? "")
            
            Text("Currently connect to: \(centralVM.connectedPeripheral?.name ?? "")")
                .font(.headline)
            
            centralView
        }
        .task {
            viewModel.fetchOrderDetail(id: orderId)
        }
        .padding()
    }
    
    // MARK: - CENTRAL UI
    var centralView: some View {
        VStack {
            List(centralVM.discoveredPeripherals, id: \.identifier) { peripheral in
                Button {
                    centralVM.connect(peripheral, order: viewModel.order)
                } label: {
                    Text(peripheral.name ?? "")
                }
            }
            
            if centralVM.connectedPeripheral != nil {
                PrimaryButton(title: "Send code") {
                    guard let order = viewModel.order else {
                        print("Order is empty")
                        return
                    }
                    
                    let payload = try? viewModel.generateEncryptedPayload(
                        unlockCode: order.dropUnlockCode ?? "",
                        publicKeyBase64: order.lockerPublicKey
                    )
                    
                    guard let codeToSent = payload else {
                        print("Code is empty")
                        return
                    }
                    
                    centralVM.sendText(codeToSent)
                }
            }
        }
    }
}
