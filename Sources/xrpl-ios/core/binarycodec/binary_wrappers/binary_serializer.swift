import Foundation
import CryptoSwift

/// Serializes JSON to XRPL binary format.
public class BinarySerializer {
    public var bytesSink = [UInt8]()
    
    private func byteArray<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
        withUnsafeBytes(of: value.bigEndian, Array.init)
    }
    
    /// Helper function for length-prefixed fields including Blob types and some AccountID types. Calculates the prefix of variable length bytes.
    ///
    /// The length of the prefix is 1-3 bytes depending on the length of the contents:
    /// Content length <= 192 bytes: prefix is 1 byte
    /// 192 bytes < Content length <= 12480 bytes: prefix is 2 bytes
    /// 12480 bytes < Content length <= 918744 bytes: prefix is 3 bytes
    ///
    ///`See Length Prefixing <https://xrpl.org/serialization.html#length-prefixing>`
    private func encodeVariableLengthPrefix(length: Int) throws -> [UInt8] {
        var length = length
        if length <= BinaryParserConstants.MAX_SINGLE_BYTE_LENGTH.rawValue {
            return byteArray(from: length)
        } else if length < BinaryParserConstants.MAX_DOUBLE_BYTE_LENGTH.rawValue {
            length -= BinaryParserConstants.MAX_SINGLE_BYTE_LENGTH.rawValue + 1
            let byte1 = byteArray(from: (length >> 8) + (BinaryParserConstants.MAX_SINGLE_BYTE_LENGTH.rawValue + 1))
            let byte2 = byteArray(from: (length & 0xFF))
            return byte1 + byte2
        } else if length <= BinaryParserConstants.MAX_LENGTH_VALUE.rawValue {
            length -= BinaryParserConstants.MAX_DOUBLE_BYTE_LENGTH.rawValue
            let byte1 = byteArray(from: (BinaryParserConstants.MAX_SECOND_BYTE_VALUE.rawValue + 1) + (length >> 16))
            let byte2 = byteArray(from: (length >> 8) & 0xFF)
            let byte3 = byteArray(from: (length & 0xFF))
            return byte1 + byte2 + byte3
        } else {
            throw XRPLBinaryCodeException.binarySerializer("VariableLength field must be <= \(BinaryParserConstants.MAX_BYTE_VALUE.rawValue) bytes long")
        }
    }
    
    /// Write given bytes to this BinarySerializer's bytesink.
    ///
    /// - Parameter bytesObject: The bytes to write to bytesink.
    public func append(bytesObject: [UInt8]) {
        bytesSink += bytesObject
    }
    
    /// Write a variable length encoded value to the BinarySerializer.
    ///
    /// - Parameter value: The SerializedType object to write to bytesink.
    public func writeLengthEncoded(value: SerializedType) throws {
        var bytesObject = [UInt8]()
        value.toByteSink(byteSink: &bytesObject)
        let lengthPrefix = try encodeVariableLengthPrefix(length: value.length())
        bytesSink += lengthPrefix
        bytesSink += bytesObject
    }
    
    /// Write field and value to the buffer.
    ///
    /// - Parameters
    ///     - field: The field to write to the buffer.
    ///     - value: The value to write to the buffer.
    public func writeFieldAndValue(field: FieldInstance, value: SerializedType) throws {
        bytesSink += field.fieldHeader.bytes
        if field.fieldInfo.isVLEncoded {
            try writeLengthEncoded(value: value)
        } else {
            bytesSink += value.bytes
        }
    }
}
