//
//  ContentView.swift
//  IoTTesting
//
//  Created by Patrick Samuel Owen Saritua Sinaga on 31/03/26.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    
//    let mode: BLEMode = .central // iPhone
     let mode: BLEMode = .peripheral // iPad
    
    @StateObject private var centralVM = CentralViewModel()
    @StateObject private var peripheralVM = PeripheralManager()
    @StateObject private var viewModel = OrdersViewModel()
    
    @State private var textToSend = ""
    
    var body: some View {
        NavigationView {
            VStack {
                
                if mode == .central {
                    centralView
                } else {
                    peripheralView
                }
            }
            .navigationTitle("BLE Testing")
            .task {
                viewModel.fetchOrders()
            }
        }
    }
    
    // MARK: - CENTRAL UI
    var centralView: some View {
        VStack {
            
            Text(centralVM.isBluetoothOn ? "bluetooth on" : "bluetooth off")
            
            List(centralVM.discoveredPeripherals, id: \.identifier) { peripheral in
                Button {
                    centralVM.connect(peripheral)
                } label: {
                    Text(peripheral.name ?? "")
                }
            }
            .onAppear {
                print("--- list: \(centralVM.discoveredPeripherals)")
            }
            
            if centralVM.connectedPeripheral != nil {
                
                TextField("Input text", text: $textToSend)
                    .textFieldStyle(.roundedBorder)
                
                Button("Send Text") {
                    centralVM.sendText(textToSend)
                }
            }
        }
    }
    
    // MARK: - PERIPHERAL UI
    var peripheralView: some View {
        VStack(spacing: 20) {
            Text("Advertising as Peripheral")
            
            Text("Received:")
            Text(peripheralVM.receivedText)
                .font(.title)
                .foregroundColor(.blue)
        }
    }
}
