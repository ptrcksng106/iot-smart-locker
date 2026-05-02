//
//  PeripheralManager.swift
//  IoTTesting
//
//  Created by Patrick Samuel Owen Saritua Sinaga on 31/03/26.
//

import Combine
import CoreBluetooth

final class PeripheralManager: NSObject, ObservableObject {

    private var peripheralManager: CBPeripheralManager!
    private var characteristic: CBMutableCharacteristic!

    @Published var receivedText: String = ""

    private let serviceUUID: CBUUID
    private let charUUID: CBUUID
    private let advertisementName: String

    /// Initialize PeripheralManager with production UUIDs
    /// - Parameters:
    ///   - serviceUUID: The BLE service UUID (from locker server configuration)
    ///   - characteristicUUID: The BLE characteristic UUID (from locker configuration)
    ///   - advertisementName: The name to advertise (e.g., locker identifier)
    init(serviceUUID: String, characteristicUUID: String, advertisementName: String = "Smart Locker") {
        self.serviceUUID = CBUUID(string: serviceUUID)
        self.charUUID = CBUUID(string: characteristicUUID)
        self.advertisementName = advertisementName
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    /// Convenience initializer for testing only - uses default test UUIDs
    /// WARNING: Do not use in production
    convenience override init() {
        // Default to Device Information Service UUIDs for testing
        self.init(
            serviceUUID: "0000180A-0000-1000-8000-00805F9B34FB",
            characteristicUUID: "00002A29-0000-1000-8000-00805F9B34FB",
            advertisementName: "Test Locker"
        )
    }
}

extension PeripheralManager: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else { return }
        
        characteristic = CBMutableCharacteristic(
            type: charUUID,
            properties: [.write, .writeWithoutResponse],
            value: nil,
            permissions: [.writeable]
        )
        
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [characteristic]
        
        peripheralManager.add(service)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           didAdd service: CBService,
                           error: Error?) {

        guard error == nil else { return }

        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: advertisementName
        ])

        print("--- advertising as: \(advertisementName) with service: \(serviceUUID)")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           didReceiveWrite requests: [CBATTRequest]) {
        
        for request in requests {
            if let data = request.value,
               let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.receivedText = text
                }
            }
            
            peripheral.respond(to: request, withResult: .success)
        }
    }
}
