import Foundation
import CoreBluetooth
import os

/// Generic bluetoothtransmitter class that handles scanning, connect, discover services, discover characteristics, subscribe to receive characteristic, reconnect.
///
/// - the connection will be set up and a subscribe to a characteristic will be done
/// - a heartbeat function is called each time there's a disconnect (needed for Dexcom) or if there's data received on the receive characteristic
/// - the class does nothing with the data itself
class BluetoothTransmitter: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    // MARK: - private properties
    
    /// the address of the transmitter.
    private let deviceAddress:String
    
    /// services to be discovered
    private let servicesCBUUIDs:[CBUUID]
    
    /// receive characteristic to which we should subcribe in order to awake the app when the tarnsmitter sends data
    private let CBUUID_ReceiveCharacteristic:String
    
    /// centralManager
    private var centralManager: CBCentralManager?
    
    /// the receive Characteristic
    private var receiveCharacteristic:CBCharacteristic?
    
    /// peripheral, gets value during connect
    private(set) var peripheral: CBPeripheral?
    
    /// for use in trace
    private let categoryBlueToothTransmitter =        "xDripClient.BlueToothTransmitter"
    
    /// to be called when data is received or if there's a disconnect, this is the actual heartbeat.
    private let heartbeat : () -> ()
    
    /// to be called whenever status change important for UI. In fact it can be called whenever there's in interaction with the CGM.
    private let onHeartBeatStatusChange: () -> ()
    
    // MARK: - Initialization
    
    /// - parameters:
    ///     - deviceAddress : the bluetooth Mac address
    ///     - one serviceCBUUID: as string, this is the service to be discovered
    ///     - CBUUID_Receive: receive characteristic uuid as string, to which subscribe should be done
    ///     - onHeartBeatStatusChange : function to call when heartBeat related status changes. This is just to be able to change the UI. Eg when status goes from   scanning to  connected
    ///     - heartbeat  : function to call when data is received on the receive characteristic or when there's a disconnect
    init(deviceAddress: String, servicesCBUUID: String, CBUUID_Receive:String, onHeartBeatStatusChange: @escaping () -> (), heartbeat : @escaping () -> ()) {
        
        self.servicesCBUUIDs = [CBUUID(string: servicesCBUUID)]

        self.CBUUID_ReceiveCharacteristic = CBUUID_Receive
        
        self.deviceAddress = deviceAddress
        
        self.heartbeat  = heartbeat
        
        self.onHeartBeatStatusChange = onHeartBeatStatusChange
        
        let cBCentralManagerOptionRestoreIdentifierKeyToUse = "Loop-" + deviceAddress
        
        super.init()
        
        trace("in initialize, creating centralManager for peripheral with address %{public}@", category: categoryBlueToothTransmitter, deviceAddress)
        
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true, CBCentralManagerOptionRestoreIdentifierKey: cBCentralManagerOptionRestoreIdentifierKeyToUse])
        
        // connect to the device
        connect()

    }
    
    // MARK: - De-initialization
    
    deinit {
        
        trace("deinit called", category: categoryBlueToothTransmitter)
        
        // disconnect the device
        disconnect()
        
    }
    
    // MARK: - public functions
    
    /// will try to connect to the device, first by calling retrievePeripherals, if peripheral not known, then by calling startScanning
    func connect() {
        
        if !retrievePeripherals(centralManager!) {
            
            startScanning()
            
        }

    }
    
    /// disconnect the device
    func disconnect() {
        
        if let peripheral = peripheral {
            
            var name = "unknown"
            if let peripheralName = peripheral.name {
                name = peripheralName
            }
            
            trace("disconnecting from peripheral with name %{public}@", category: categoryBlueToothTransmitter, name)
            
            centralManager!.cancelPeripheralConnection(peripheral)
            
        }
      
    }
    
    /// stops scanning
    func stopScanning() {
        
        trace("in stopScanning", category: categoryBlueToothTransmitter)
        
        self.centralManager!.stopScan()
        
    }
    
    /// calls setNotifyValue for characteristic with value enabled
    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) {
        
        if let peripheral = peripheral {
            
            trace("setNotifyValue, for peripheral with name %{public}@, setting notify for characteristic %{public}@, to %{public}@", category: categoryBlueToothTransmitter, peripheral.name ?? "'unknown'", characteristic.uuid.uuidString, enabled.description)
          peripheral.setNotifyValue(enabled, for: characteristic)
            
        } else {
            
            trace("setNotifyValue, for peripheral with name %{public}@, failed to set notify for characteristic %{public}@, to %{public}@", category: categoryBlueToothTransmitter,  peripheral?.name ?? "'unknown'", characteristic.uuid.uuidString, enabled.description)
            
        }
    }
    
    // MARK: - fileprivate functions
    
    /// start bluetooth scanning for device
    fileprivate func startScanning() {
        
        if centralManager!.state == .poweredOn {
            
            trace("in startScanning", category: categoryBlueToothTransmitter)
            
            centralManager!.scanForPeripherals(withServices: nil, options: nil)
            
        } else {
            
            trace("in startScanning. Not started, state is not poweredOn", category: categoryBlueToothTransmitter)
            
        }
        

    }

    /// stops scanning and connect. To be called after diddiscover
    fileprivate func stopScanAndconnect(to peripheral: CBPeripheral) {
        
        self.centralManager!.stopScan()
        
        self.peripheral = peripheral
        
        // will change info in UI
        onHeartBeatStatusChange()
        
        peripheral.delegate = self
        
        if peripheral.state == .disconnected {
            
            trace("    trying to connect", category: categoryBlueToothTransmitter)
            
            centralManager!.connect(peripheral, options: nil)
            
        } else {
            
            trace("    calling centralManager(newCentralManager, didConnect: peripheral", category: categoryBlueToothTransmitter)
            
            centralManager(centralManager!, didConnect: peripheral)

        }
        
    }
    
    /// try to connect to peripheral to which connection was successfully done previously, and that has a uuid that matches the stored deviceAddress. If such peripheral exists, then try to connect, it's not necessary to start scanning. iOS will connect as soon as the peripheral comes in range, or bluetooth status is switched on, whatever is necessary
    ///
    /// the result of the attempt to try to find such device, is returned
    fileprivate func retrievePeripherals(_ central:CBCentralManager) -> Bool {

        trace("in retrievePeripherals, deviceaddress is %{public}@", category: categoryBlueToothTransmitter, deviceAddress)
        
            if let uuid = UUID(uuidString: deviceAddress) {
                
                trace("    uuid is not nil", category: categoryBlueToothTransmitter)
                
                let peripheralArr = central.retrievePeripherals(withIdentifiers: [uuid])
                
                if peripheralArr.count > 0 {
                    
                    peripheral = peripheralArr[0]
                    
                    // peripheral is assigned a value, heartbeat status text in UI must change
                    onHeartBeatStatusChange()
                    
                    if let peripheral = peripheral {
                        
                        trace("    trying to connect", category: categoryBlueToothTransmitter)
                        
                        peripheral.delegate = self
                        
                        central.connect(peripheral, options: nil)
                        
                        return true
                        
                    } else {
                        
                        trace("     peripheral is nil", category: categoryBlueToothTransmitter)
                        
                    }
                } else {
                    
                    trace("    uuid is not nil, but central.retrievePeripherals returns 0 peripherals", category: categoryBlueToothTransmitter)
                    
                }
                
            } else {
                
                trace("    uuid is nil", category: categoryBlueToothTransmitter)
                
            }

        return false

    }
    
    // MARK: - methods from protocols CBCentralManagerDelegate, CBPeripheralDelegate
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // devicename needed unwrapped for logging
        var deviceName = "unknown"
        if let temp = peripheral.name {
            deviceName = temp
        }
        
        trace("Did discover peripheral with name: %{public}@", category: categoryBlueToothTransmitter, String(describing: deviceName))
        
        // check if stored address not nil, in which case we already connected before and we expect a full match with the already known device name
        if peripheral.identifier.uuidString == deviceAddress {
            
            trace("    stored address matches peripheral address, will try to connect", category: categoryBlueToothTransmitter)
            
            stopScanAndconnect(to: peripheral)
            
        } else {
            
            trace("    stored address does not match peripheral address, ignoring this device", category: categoryBlueToothTransmitter)
            
        }

    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        trace("connected to peripheral with name %{public}@", category: categoryBlueToothTransmitter, peripheral.name ?? "'unknown'")
        
        peripheral.discoverServices(servicesCBUUIDs)
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        if let error = error {
            
            trace("failed to connect, for peripheral with name %{public}@, with error: %{public}@, will try again", category: categoryBlueToothTransmitter, peripheral.name ?? "'unknown'", error.localizedDescription)
            
        } else {
            
            trace("failed to connect, for peripheral with name %{public}@, will try again", category: categoryBlueToothTransmitter,  peripheral.name ?? "'unknown'")
            
        }
        
        centralManager!.connect(peripheral, options: nil)
        
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        trace("in centralManagerDidUpdateState, for peripheral with name %{public}@, new state is %{public}@", category: categoryBlueToothTransmitter, peripheral?.name ?? "'unknown'", "\(central.state.toString())")
        
        /// in case status changed to powered on and if device address known then try to retrieveperipherals
        if central.state == .poweredOn {
            
                /// try to connect to device to which connection was successfully done previously, this attempt is done by callling retrievePeripherals(central)
                _ = retrievePeripherals(central)
                
        }

    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        trace("    didDisconnect peripheral with name %{public}@", category: categoryBlueToothTransmitter , peripheral.name ?? "'unknown'")
        
        // call heartbeat, useful for Dexcom transmitters, after a disconnect, then there's probably a new reading available
        heartbeat()

        if let error = error {
            
            trace("    error: %{public}@", category: categoryBlueToothTransmitter,  error.localizedDescription)
            
        }
        
        // if self.peripheral == nil, then a manual disconnect or something like that has occured, no need to reconnect
        // otherwise disconnect occurred because of other (like out of range), so let's try to reconnect
        if let ownPeripheral = self.peripheral {
            
            trace("    Will try to reconnect", category: categoryBlueToothTransmitter)
            
            centralManager!.connect(ownPeripheral, options: nil)
            
        } else {
            
            trace("    peripheral is nil, will not try to reconnect", category: categoryBlueToothTransmitter)
            
        }

    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        trace("didDiscoverServices for peripheral with name %{public}@", category: categoryBlueToothTransmitter, peripheral.name ?? "'unknown'")
        
        if let error = error {
            trace("    didDiscoverServices error: %{public}@", category: categoryBlueToothTransmitter,   "\(error.localizedDescription)")
        }
        
        if let services = peripheral.services {
            for service in services {
                trace("    Call discovercharacteristics for service with uuid %{public}@", category: categoryBlueToothTransmitter, String(describing: service.uuid))
                peripheral.discoverCharacteristics(nil, for: service)
            }
        } else {
            disconnect()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        trace("didDiscoverCharacteristicsFor for peripheral with name %{public}@, for service with uuid %{public}@", category: categoryBlueToothTransmitter, peripheral.name ?? "'unknown'", String(describing:service.uuid))
        
        if let error = error {
            trace("    didDiscoverCharacteristicsFor error: %{public}@", category: categoryBlueToothTransmitter,  error.localizedDescription)
        }
        
        if let characteristics = service.characteristics {
            
            for characteristic in characteristics {
                
                trace("    characteristic: %{public}@", category: categoryBlueToothTransmitter, String(describing: characteristic.uuid))
                
                if characteristic.uuid == CBUUID(string: CBUUID_ReceiveCharacteristic) {
                    
                    trace("    found receiveCharacteristic", category: categoryBlueToothTransmitter)
                    
                    receiveCharacteristic = characteristic
                    
                    peripheral.setNotifyValue(true, for: characteristic)
                    
                }
                
            }
            
        } else {
            
            trace("    Did discover characteristics, but no characteristics listed. There must be some error.", category: categoryBlueToothTransmitter)
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        if let error = error {
            
            trace("didUpdateNotificationStateFor for peripheral with name %{public}@, characteristic %{public}@, error =  %{public}@", category: categoryBlueToothTransmitter,  peripheral.name ?? "'unkonwn'", String(describing: characteristic.uuid), error.localizedDescription)
            
        }
        
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        trace("didUpdateValueFor for peripheral with name %{public}@", category: categoryBlueToothTransmitter,  peripheral.name ?? "'unknown'")
        
        // call heartbeat
        heartbeat()
        
    }
    
    func centralManager(_ central: CBCentralManager,
                        willRestoreState dict: [String : Any]) {

        // willRestoreState must be defined, otherwise the app would crash (because the centralManager was created with a CBCentralManagerOptionRestoreIdentifierKey)
        // even if it's an empty function
        // trace is called here because it allows us to see in the issue reports if there was a restart after app crash or removed from memory - in all other cases (force closed by user) this function is not called

        trace("in willRestoreState", category: categoryBlueToothTransmitter)
        
    }

}


