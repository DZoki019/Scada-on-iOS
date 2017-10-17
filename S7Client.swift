//
//  S7Client.swift
//  PLC HMI
//
//  Created by Djordje Jovic on 10/5/17.
//  Copyright © 2017 Encoded Street. All rights reserved.
//

import Foundation

enum S7Area: Int32 {
    case pe = 0x81
    case pa = 0x82
    case mk = 0x83
    case db = 0x84
    case ct = 0x1C
    case tm = 0x1D
}

enum S7WordLength: Int32 {
    case bit     = 0x01
    case byte    = 0x02
    case word    = 0x4
    case dword   = 0x6
    case real    = 0x8
    case counter = 0x1C
    case timer   = 0x1D
}

protocol S7Convertable {
    func convert() -> Self
}

typealias BIT = Bool
typealias BYTE = UInt8
typealias WORD = UInt16
typealias DWORD = UInt32

extension BIT: S7Convertable {
    func convert() -> BIT {
        return self
    }
}

extension BYTE: S7Convertable {
    func convert() -> BYTE {
        return self
    }
}

extension WORD: S7Convertable {
    func convert() -> WORD {
        return CFSwapInt16(self)
    }
}

extension DWORD: S7Convertable {
    func convert() -> DWORD {
        return CFSwapInt32(self)
    }
}

class S7Client {
    fileprivate let object = Cli_Create()
    fileprivate let dispatchQueue = DispatchQueue(label: "S7Client", attributes: [])

    fileprivate func async(_ handler: @escaping (Void) -> Void) {
        self.dispatchQueue.async(execute: handler)
    }
    
    
    /// Connects with the PLC
    ///
    /// - Parameters:
    ///   - address: Address of the PLC
    ///   - rack: Rack of the PLC
    ///   - slot: Slot of the PLC
    ///   - completion: Completion is called when the connection with PLC has established
    func connect(_ address: String, rack: Int, slot: Int, completion: ((Int) -> Void)?) {
        self.async {
            completion?(Int(Cli_ConnectTo(self.object, address, Int32(rack), Int32(slot))))
        }
    }
    
    /// Disconnects from PLC
    ///
    /// - Parameter completion: Completion is called when disconnected
    func disconnect(_ completion: ((Int) -> Void)?) {
        self.async {
            completion?(Int(Cli_Disconnect(self.object)))
        }
    }
    
    /// Reads data from PLC
    ///
    /// - Parameters:
    ///   - address: Address of the PLC
    ///   - defaultValue: Assumed value
    ///   - completion: Completion is called when the value from PLC has read
    /// - Returns: Returns bool for address check
    func read<T: S7Convertable>(_ address: String, defaultValue: T, completion: ((T, Int32) -> Void)?) -> Bool {
        guard let address = (try? address.toS7Address()) else {
            return false
        }
        
        if address.size != MemoryLayout<T>.size {
            return false
        }
        
        self.async {
            var buffer = defaultValue
            let retn = Cli_ReadArea(self.object, address.type.rawValue, Int32(address.dbNumber), Int32(address.realOffset), Int32(address.size), address.length.rawValue, &buffer)
            completion?(buffer.convert(), retn)
        }
        
        return true
    }
    
    /// Writes data to PLC
    ///
    /// - Parameters:
    ///   - address: Address of the PLC
    ///   - value: Forwarded value
    ///   - completion: Completion is called when the value has written to the PLC
    /// - Returns: Returns bool for address check
    func write<T: S7Convertable>(_ address: String, value: T, completion: ((Int32) -> Void)?) -> Bool {
        guard let address = (try? address.toS7Address()) else {
            return false
        }
        
        if address.size != MemoryLayout<T>.size {
            return false
        }
        
        self.async {
            var buffer = value.convert()
            completion?(Cli_WriteArea(self.object, address.type.rawValue, Int32(address.dbNumber), Int32(address.realOffset), Int32(address.size), address.length.rawValue, &buffer))
        }
        
        return true
    }
}
