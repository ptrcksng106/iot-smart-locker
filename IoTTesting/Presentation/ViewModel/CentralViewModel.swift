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
    @Published var isLoading = false

    private var centralManager: CBCentralManager!
    private var targetCharacteristic: CBCharacteristic?
    private var targetCharUuid: CBUUID?

    // Current order for auto-connection
    private(set) var currentOrder: Order? = nil
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScan() {
        startScan(with: self.currentOrder)
    }

    func startScan(with order: Order?) {
        guard centralManager.state == .poweredOn else { return }

        print("--- start scanning")

        discoveredPeripherals.removeAll()
        currentOrder = order

        // If order has a locker server ID, filter scan by service UUID
        var serviceUUIDs: [CBUUID]? = nil
        if let lockerServerId = order?.lockerServerId {
            serviceUUIDs = [CBUUID(string: lockerServerId)]
            print("--- filtering scan by service UUID: \(lockerServerId)")
        }

        print("--- locker: \(order?.lockerServerId ?? "None")")
        print("--- filters: \(serviceUUIDs?.count ?? 0)")
        
        centralManager.scanForPeripherals(
            withServices: serviceUUIDs,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }
    
    func stopScan() {
        centralManager.stopScan()
    }
    
    func connect(_ peripheral: CBPeripheral, order: Order? = nil) {
        print("--- connecting to:", peripheral.name ?? "")

        guard order != nil else {
            return
        }

        guard let charId = order?.lockerId else {
            return
        }

        self.targetCharUuid = CBUUID(string: charId)
        self.currentOrder = order

        // Stop scanning before connecting
        centralManager.stopScan()

        self.centralManager.connect(peripheral, options: nil)
        self.isLoading = false
    }
    
    func sendText(_ text: String) {
        guard let characteristic = targetCharacteristic,
              let data = text.data(using: .utf8),
              let peripheral = connectedPeripheral else { return }
        
        print("Send data: \(data)")
        
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}

// MARK: - CBCentralManagerDelegate
extension CentralViewModel: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            self.isBluetoothOn = (central.state == .poweredOn)
        }

        // Only auto-scan if no order is set (prevents interference with order-based scans)
        print("currentOrder: \(currentOrder)")
        if central.state == .poweredOn && currentOrder != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.startScan()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {

        DispatchQueue.main.async {
            if !self.discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                guard let name = peripheral.name, !name.isEmpty else { return }
                self.discoveredPeripherals.append(peripheral)

                // Auto-connect if we have an order with matching service UUID
                if let order = self.currentOrder,
                   let lockerServerId = order.lockerServerId,
                   let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {

                    // Check if peripheral advertises the service UUID we're looking for
                    let targetServiceUUID = CBUUID(string: lockerServerId)
                    if serviceUUIDs.contains(targetServiceUUID) {
                        print("--- auto-connecting to matching peripheral: \(name)")
                        self.connect(peripheral, order: order)
                    }
                }
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
            if characteristic.uuid == targetCharUuid {
                targetCharacteristic = characteristic
                print("--- found target characteristic: \(characteristic.uuid)")

                // Verify we have the correct locker if auto-connected
                if let order = currentOrder {
                    print("--- verified locker connection for order: \(order.id)")
                }
            }
        }
    }
}
