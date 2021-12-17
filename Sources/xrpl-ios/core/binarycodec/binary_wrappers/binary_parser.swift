import Foundation
import CryptoSwift

/// Constants used in length prefix decoding
internal enum BinaryParserConstants: Int {
    /// Max length that can be represented in a single byte per XRPL serialization restrictions
    case MAX_SINGLE_BYTE_LENGTH = 192
    
    /// Max length that can be represented in 2 bytes per XRPL serialization restrictions
    case MAX_DOUBLE_BYTE_LENGTH = 12481
    
    /// Max value that can be used in the second byte of a length field
    case MAX_SECOND_BYTE_VALUE = 240
    
    /// Max value that can be represented using one 8-bit byte (2^8)
    case MAX_BYTE_VALUE = 256
    
    /// Max value that can be represented in using two 8-bit bytes (2^16)
    case MAX_DOUBLE_BYTE_VALUE = 65536
    
    /// 1 byte encodes to 2 characters in hex
    case BYTE_HEX_LENGTH = 2
    
    /// maximum length that can be encoded in a length prefix per XRPL serialization encoding
    case MAX_LENGTH_VALUE = 918744
}

/// Deserializes from hex-encoded XRPL binary format to JSON fields and values.
public class BinaryParser {
    
    private let hex: String
    public var bytes: [UInt8]
    
    private let numberBytesUInt8 = 1
    private let numberBytesUInt16 = 2
    private let numberBytesUInt32 = 4
    
    public init(hex: String) {
        self.hex = hex
        self.bytes = Array<UInt8>.init(hex: hex)
    }

    /// Return the number of bytes in this parser's buffer.
    private var length: Int {
        return bytes.count
    }
    
    /// Peek the first byte of the BinaryParser.
    /// - Returns: The first byte of the BinaryParser.
    public func peek() -> UInt8? {
        return bytes.first
    }
    
    /// Consume the first n bytes of the BinaryParser.
    /// - Parameter n: The number of bytes to consume.
    /// - Throws: XRPLBinaryCodecException: If n bytes can't be skipped.
    public func skip(n: Int) throws {
        guard length >= n else {
            throw XRPLBinaryCodeException.binaryParser("BinaryParser can't skip \(n) bytes, only contains \(length).")
        }
        self.bytes = Array(bytes[n..<length])
    }
    
    /// Consume and return the first n bytes of the BinaryParser.
    /// - Parameter n: The number of bytes to read.
    /// - Returns: The bytes read.
    public func read(n: Int) throws -> [UInt8] {
        let firstNBytes = Array(bytes[0..<n])
        try skip(n: n)
        return firstNBytes
    }
    
    /// Read 1 byte from parser and return as unsigned int.
    /// - Returns: The byte read.
    public func readUInt8() throws -> Int {
        let read1Byte = try read(n: numberBytesUInt8)
        let bigEndianValue = read1Byte.withUnsafeBufferPointer { $0.baseAddress!.withMemoryRebound(to: Int.self, capacity: 1) { $0 } }.pointee
        return Int(bigEndian: bigEndianValue)
    }
    
    /// Read 2 bytes from parser and return as unsigned int.
    /// - Returns: The bytes read.
    public func readUInt16() throws -> Int {
        let read2Bytes = try read(n: numberBytesUInt16)
        let bigEndianValue = read2Bytes.withUnsafeBufferPointer { $0.baseAddress!.withMemoryRebound(to: Int.self, capacity: 1) { $0 } }.pointee
        return Int(bigEndian: bigEndianValue)
    }
    
    /// Read 4 bytes from parser and return as unsigned int.
    /// - Returns: The bytes read.
    public func readUInt32() throws -> Int {
        let read4Bytes = try read(n: numberBytesUInt32)
        let bigEndianValue = read4Bytes.withUnsafeBufferPointer { $0.baseAddress!.withMemoryRebound(to: Int.self, capacity: 1) { $0 } }.pointee
        return Int(bigEndian: bigEndianValue)
    }
    
    /// Returns whether the binary parser has finished parsing (e.g. there is nothing left in the buffer that needs to be processed).
    /// - Parameter customEnd: An ending byte-phrase.
    /// - Returns: Whether or not it's the end.
    public func isEnd(customEnd: Int = 0) -> Bool {
        return length == 0 || (customEnd != 0 && length <= customEnd)
    }
    
    /// Reads and returns variable length encoded bytes.
    /// - Returns: The bytes read.
    public func readVariableLength() throws -> [UInt8] {
        return try read(n: try readLengthPrefix())
    }
    
    /// Reads a variable length encoding prefix and returns the encoded length.
    ///
    /// The formula for decoding a length prefix is described in: `Length Prefixing <https://xrpl.org/serialization.html#length-prefixing>`
    private func readLengthPrefix() throws -> Int {
        let byte1 = try readUInt8()
        
        if byte1 <= BinaryParserConstants.MAX_SINGLE_BYTE_LENGTH.rawValue {
            // If the field contains 0 to 192 bytes of data, the first byte defines
            // the length of the contents
            return byte1
        } else if byte1 <= BinaryParserConstants.MAX_SECOND_BYTE_VALUE.rawValue {
            // If the field contains 193 to 12480 bytes of data, the first two bytes
            // indicate the length of the field with the following formula:
            // 193 + ((byte1 - 193) * 256) + byte2
            let byte2 = try readUInt8()
            return (BinaryParserConstants.MAX_SINGLE_BYTE_LENGTH.rawValue + 1) + ((byte1 - (BinaryParserConstants.MAX_SINGLE_BYTE_LENGTH.rawValue + 1)) * BinaryParserConstants.MAX_BYTE_VALUE.rawValue) + byte2
        } else if byte1 <= 254 {
            // If the field contains 12481 to 918744 bytes of data, the first three
            // bytes indicate the length of the field with the following formula:
            // 12481 + ((byte1 - 241) * 65536) + (byte2 * 256) + byte3
            let byte2 = try readUInt8()
            let byte3 = try readUInt8()
            return BinaryParserConstants.MAX_DOUBLE_BYTE_LENGTH.rawValue + ((byte1 - (BinaryParserConstants.MAX_SECOND_BYTE_VALUE.rawValue + 1)) * BinaryParserConstants.MAX_DOUBLE_BYTE_VALUE.rawValue) + (byte2 * BinaryParserConstants.MAX_BYTE_VALUE.rawValue) + byte3
        } else {
            throw XRPLBinaryCodeException.binaryParser("Length prefix must contain between 1 and 3 bytes.")
        }
    }
    
    /// Reads field ID from BinaryParser and returns as a FieldHeader object.
    /// - Returns: The field header.
    /// - Throws `XRPLBinaryCodecException`: If the field ID cannot be read.
    public func readFieldHeader() throws -> FieldHeader {
        var typeCode = try readUInt8()
        var fieldCode = typeCode & 15
        typeCode >>= 4
        
        if typeCode == 0 {
            typeCode = try readUInt8()
            if typeCode == 0 || typeCode < 16 {
                throw XRPLBinaryCodeException.binaryParser("Cannot read field ID, type_code out of range.")
            }
        }
        
        if fieldCode == 0 {
            fieldCode = try readUInt8()
            if fieldCode == 0 || fieldCode < 16 {
                throw XRPLBinaryCodeException.binaryParser("Cannot read field ID, field_code out of range.")
            }
        }
        
        return FieldHeader(typeCode: typeCode, fieldCode: fieldCode)
    }
    
    public func 
}
