//
//  String+S7Address.swift
//  PLC HMI
//
//  Created by Djordje Jovic on 10/5/17.
//  Copyright © 2017 Encoded Street. All rights reserved.
//

import Foundation

enum S7AddressParserError: Error {
    case invalidRegEx
    case noMatches
    case parseError
    case rangeError
}

extension S7Area {
    init?(fromString string: String) {
        switch string.uppercased() {
        case "E":
            self = .pe
        case "A":
            self = .pa
        case "M":
            self = .mk
        case "DB":
            self = .db
        default:
            return nil
        }
    }
}

struct S7Address {
    var type: S7Area
    var length: S7WordLength
    var size: Int
    var dbNumber: Int
    var offset: Int
    var bitOffset: Int
    
    // Calculate for I/O-Operations
    var realOffset: Int {
        return self.length == .byte ? self.offset : self.offset * 8 + self.bitOffset
    }
}

extension String {
    subscript(range: NSRange) -> String {
        return (self as NSString).substring(with: range)
    }
    
    func NSRangeFromRange(range : Range<String.Index>) -> NSRange {
        let utf16view = self.utf16
        let from = String.UTF16View.Index(range.lowerBound, within: utf16view)
        let to = String.UTF16View.Index(range.upperBound, within: utf16view)
        return NSMakeRange(utf16view.startIndex.distance(to: from), from!.distance(to: to))
    }
    
    func toS7Address() throws -> S7Address {
        let patterns = [
            "^(E|A|M)(B|W|D)(\\d+)$",               // EB1000, AW4, MD0
            "^(E|A|M)(\\d+)\\.([0-7])$",            // E5.5, A0.0, M100.2
            "^(DB)(\\d+)\\.DB(B|W|D)(\\d+)$",       // DB1000.DBW100
            "^(DB)(\\d+)\\.DBX(\\d+)\\.([0-7])$"    // DB1.DBX5.1
        ]
        
        for (index, pattern) in patterns.enumerated() {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.allowCommentsAndWhitespace, .caseInsensitive]) else {
                throw S7AddressParserError.invalidRegEx
            }
            
            guard let stringRange = self.range(of: self) else {
                throw S7AddressParserError.rangeError
            }
            
            let range = self.NSRangeFromRange(range: stringRange)
            let matches = regex.matches(in: self, options: .anchored, range: range)
            
            if matches.count == 0 {
                continue
            }
            
            let match = matches[0]
            guard let type = S7Area(fromString: self[match.rangeAt(1)]) else {
                throw S7AddressParserError.parseError
            }
            
            let length: S7WordLength
            let size: Int
            switch type {
            case .pe, .pa, .mk:
                switch index {
                case 0:
                    switch self[match.rangeAt(2)] {
                    case "B":
                        size = 1
                        length = .byte
                    case "W":
                        size = 2
                        length = .byte
                    case "D":
                        size = 4
                        length = .byte
                    default:
                        throw S7AddressParserError.parseError
                    }
                case 1:
                    size = 1
                    length = .bit
                    
                default:
                    throw S7AddressParserError.parseError
                }
            case .db:
                switch index {
                case 2:
                    switch self[match.rangeAt(3)] {
                    case "B":
                        size = 1
                        length = .byte
                    case "W":
                        size = 2
                        length = .byte
                    case "D":
                        size = 4
                        length = .byte
                    default:
                        throw S7AddressParserError.parseError
                    }
                case 3:
                    size = 1
                    length = .bit
                default:
                    throw S7AddressParserError.parseError
                }
            default:
                throw S7AddressParserError.parseError
            }
            
            guard let dbNumber = type == .db ? Int(self[match.rangeAt(2)]) : 0 else {
                throw S7AddressParserError.parseError
            }
            
            
            let offset: Int
            switch index {
            case 0:
                offset = Int(self[match.rangeAt(3)])!
            case 1:
                offset = Int(self[match.rangeAt(2)])!
            case 2:
                offset = Int(self[match.rangeAt(4)])!
            case 3:
                offset = Int(self[match.rangeAt(3)])!
            default:
                offset = 0
            }
            
            let bitOffset: Int
            switch index {
            case 1:
                bitOffset = Int(self[match.rangeAt(3)])!
            case 3:
                bitOffset = Int(self[match.rangeAt(4)])!
            default:
                bitOffset = 0
            }
            
            return S7Address(type: type, length: length, size: size, dbNumber: dbNumber, offset: offset, bitOffset: bitOffset)
        }
        
        throw S7AddressParserError.noMatches
    }
}
