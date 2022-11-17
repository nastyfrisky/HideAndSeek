////
////  ViewController.swift
////  HideAndSeek
////
////  Created by Анастасия Ступникова on 16.11.2022.
////
//
//import UIKit
//import CoreBluetooth
//
//final class ViewController: UIViewController {
//
//    private let serviceUUID = UUID(uuidString: "B17843CE-478A-4C9D-A6E5-BCAE47CE4CC6")!
//
//    private var centralManager: CBCentralManager?
//
//    @IBOutlet var label: UILabel!
//    private var peripheral: CBPeripheral?
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        centralManager = CBCentralManager(delegate: self, queue: nil)
//    }
//
//    func rssiToMeters(rssi: NSNumber) -> Int {
//        let power: Double = (-56 - Double(truncating: rssi)) / (10 * 2)
//        return Int(pow(10, power) * 3.2808)
//    }
//}
//
//extension ViewController: CBCentralManagerDelegate {
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        switch central.state {
//        case .poweredOn:
//            centralManager?.scanForPeripherals(withServices: [
//                CBUUID(nsuuid: serviceUUID)
//            ])
//        default: break
//        }
//    }
//
//    func centralManager(
//        _ central: CBCentralManager,
//        didDiscover peripheral: CBPeripheral,
//        advertisementData: [String : Any],
//        rssi RSSI: NSNumber
//    ) {
//        peripheral.delegate = self
//        self.peripheral = peripheral
//        central.connect(peripheral)
//        label.text = "\(rssiToMeters(rssi: RSSI))"
//    }
//
//    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//        peripheral.readRSSI()
//    }
//}
//
//extension ViewController: CBPeripheralDelegate {
//    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
//        label.text = "\(rssiToMeters(rssi: RSSI))"
//        peripheral.readRSSI()
//    }
//}
//
