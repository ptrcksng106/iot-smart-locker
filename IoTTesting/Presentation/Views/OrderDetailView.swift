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
                    centralVM.connect(peripheral)
                } label: {
                    Text(peripheral.name ?? "")
                }
            }
            
            if centralVM.connectedPeripheral != nil {
                PrimaryButton(title: "Send code") {
                    let hardcodedPEM = """
                    -----BEGIN PUBLIC KEY-----
                    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlIMPHwD3lyGgUVUrBkx/
                    Bo8SJ0MuN5fZk/s/L86W43iUmOuAK8L1A9h+28p1SXKNiSo6dD/GMuZLMaJ97JyL
                    9KRkSEOagh0A7SCISAzPyOdpdUysrPK+lVbrE6lX79J58SFAGekEcRlokgspjgdg
                    BU3b57ylT8B3Uh5C02rB2Vyh1x0e3IhEtQgbYNYx7UC040t2b+VDdddNqVvI/Ded
                    h3qw+9pn0s8OrPnRBgZY2etq5QqS1cn7pPijrdlmR65fJmY1T6Q5HfTiX+e2T9zE
                    LUfAjGu8gV8kk+xKJ1fJcjY9kzkcode3EDfoMVImPvUuVd5BfiAPyfP96TZDz1v6
                    hQIDAQAB
                    -----END PUBLIC KEY-----
                    """
                    guard let codeToSent = try? viewModel.generateEncryptedPayload(unlockCode: "123456", publicKeyBase64: hardcodedPEM) else { return }
                    
                    centralVM.sendText(codeToSent)
                }
            }
        }
    }
}
