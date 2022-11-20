//
//  PeripheralManagerService.swift
//  BlueStationTest
//
//  Created by Анастасия Ступникова on 18.11.2022.
//

import CoreBluetooth

protocol PeripheralManagerServiceDelegate: AnyObject {
    
}

final class PeripheralManagerService: NSObject {
    weak var delegate: PeripheralManagerServiceDelegate?
    
    private var optionalPeripheralManager: CBPeripheralManager?
    private var peripheralManager: CBPeripheralManager {
        if let manager = optionalPeripheralManager { return manager }
        let manager = CBPeripheralManager(delegate: self, queue: nil)
        optionalPeripheralManager = manager
        return manager
    }
    
    override init() {
        super.init()
        optionalPeripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    private func startAdvertising() {
        let serviceUUID = CBUUID(nsuuid: UUID(uuidString: "90f52c9e-1b29-4320-a826-e60ad60110bf")!)
        
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = []
        peripheralManager.add(service)
        
        peripheralManager.startAdvertising([
            CBAdvertisementDataLocalNameKey: "Hider",
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID]
        ])
        
        peripheralManager.publishL2CAPChannel(withEncryption: false)
    }
}

extension PeripheralManagerService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            startAdvertising()
        }
    }
}
