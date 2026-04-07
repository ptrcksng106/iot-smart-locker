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
    
    private let serviceUUID = CBUUID(string: "1234")
    private let charUUID = CBUUID(string: "5678")
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
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
            CBAdvertisementDataLocalNameKey: "iPad BLE"
        ])
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
