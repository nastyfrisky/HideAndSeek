//
//  CentralManagerService.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 18.11.2022.
//

import CoreBluetooth

protocol CentralManagerServiceDelegate: AnyObject {
    func didUpdateRSSI(rssi: Int)
}

protocol CentralManagerService: AnyObject {
    var delegate: CentralManagerServiceDelegate? { get set }
}

final class CentralManagerServiceImpl: NSObject {
    weak var delegate: CentralManagerServiceDelegate?
    
    private var optionalCentralManager: CBCentralManager?
    private var centralManager: CBCentralManager {
        if let manager = optionalCentralManager { return manager }
        let manager = CBCentralManager(delegate: self, queue: nil)
        optionalCentralManager = manager
        return manager
    }
    
    override init() {
        super.init()
        optionalCentralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

extension CentralManagerServiceImpl: CentralManagerService {
    func rescan() {
        guard centralManager.state == .poweredOn else { return }
        
        centralManager.scanForPeripherals(withServices: [CBUUID(nsuuid: UUID(
            uuidString: "90f52c9e-1b29-4320-a826-e60ad60110bf"
        )!)], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
}

extension CentralManagerServiceImpl: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) { rescan() }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        delegate?.didUpdateRSSI(rssi: Int(truncating: RSSI))
    }
}
