//
//  CentralViewModel.swift
//  IoTTesting
//
//  Created by Patrick Samuel Owen Saritua Sinaga on 31/03/26.
//

import Combine
import CoreBluetooth

final class CentralViewModel: NSObject, ObservableObject {
    
    @Published var isBluetoothOn = false
    @Published var discoveredPeripherals: [CBPeripheral] = []
    @Published var connectedPeripheral: CBPeripheral?
    
    private var centralManager: CBCentralManager!
    private var targetCharacteristic: CBCharacteristic?
    
    private let serviceUUID = CBUUID(string: "1234")
    private let charUUID = CBUUID(string: "5678")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScan() {
        guard centralManager.state == .poweredOn else { return }
        
        print("--- start scanning")
        
        discoveredPeripherals.removeAll()
        
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    func stopScan() {
        centralManager.stopScan()
    }
    
    func connect(_ peripheral: CBPeripheral) {
        print("--- connecting to:", peripheral.name ?? "")
        centralManager.connect(peripheral, options: nil)
    }
    
    func sendText(_ text: String) {
        guard let characteristic = targetCharacteristic,
              let data = text.data(using: .utf8),
              let peripheral = connectedPeripheral else { return }
        
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}

// MARK: - CBCentralManagerDelegate
extension CentralViewModel: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            self.isBluetoothOn = (central.state == .poweredOn)
        }
        
        if central.state == .poweredOn {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.startScan()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        
        print("--- found:", peripheral.name ?? "")
        
        DispatchQueue.main.async {
            if !self.discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                self.discoveredPeripherals.append(peripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        
        print("--- connected to:", peripheral.name ?? "")
        
        DispatchQueue.main.async {
            self.connectedPeripheral = peripheral
        }
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
}

// MARK: - CBPeripheralDelegate
extension CentralViewModel: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == charUUID {
                targetCharacteristic = characteristic
            }
        }
    }
}
