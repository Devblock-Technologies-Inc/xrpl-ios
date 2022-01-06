import Foundation

public class FieldIdCodec {
    
    public static let shared = FieldIdCodec()
    
    private init() {}
    
    /// Returns the unique field ID for a given field name. This field ID consists of the type code and field code, in 1 to 3 bytes depending on whether those values are "common" (<16) or "uncommon" (>=16)
    ///
    /// - Parameter fieldName: The name of the field to get the serialization data type for.
    /// - Returns: The serialization data type for the given field name.
    public func encode(fieldName: String) throws -> [UInt8] {
        let definations = try Definations.loadDefinations()
        let fieldHeader = definations.getFieldHeader(from: fieldName)
        return try encodeFieldId(fieldHeader: fieldHeader)
    }
    
    /// Returns the field name represented by the given field ID.
    ///
    /// - Parameter fieldId: The field_id to decode.
    /// - Returns: The field name represented by the given field ID.
    public func decode(fieldId: String) throws -> String {
        let definations = try Definations.loadDefinations()
        let fieldHeader = try decodeFieldId(fieldId: fieldId)
        return definations.getFieldName(from: fieldHeader)
    }
    
    /// Returns the unique field ID for a given field header. This field ID consists of the type code and field code, in 1 to 3 bytes depending on whether those values are "common" (<16) or "uncommon" (>=16)
    private func encodeFieldId(fieldHeader: FieldHeader) throws -> [UInt8] {
        let typeCode = fieldHeader.typeCode
        let fieldCode = fieldHeader.fieldCode
        
        guard typeCode > 0 && typeCode <= 255 && fieldCode > 0 && fieldCode <= 255 else {
            throw XRPLBinaryCodeException.binaryCodec("Codecs must be nonzero and fit in 1 byte.")
        }
        
        if typeCode < 16 && fieldCode < 16 {
            // high 4 bits is the type_code
            // low 4 bits is the field code
            let combinedCodec = (typeCode << 4) | fieldCode
            return UInt8(truncatingIfNeeded: combinedCodec).toByteArray()
        } else if typeCode >= 16 && fieldCode < 16 {
            // first 4 bits are zeroes
            // next 4 bits is field code
            // next byte is type code
            let byte1 = UInt8(truncatingIfNeeded: typeCode).toByteArray()
            let byte2 = UInt8(truncatingIfNeeded: fieldCode).toByteArray()
            return byte1 + byte2
        } else if typeCode < 16 && fieldCode >= 16 {
            // first 4 bits is type code
            // next 4 bits are zeroes
            // next byte is field code
            let byte1 = UInt8(truncatingIfNeeded: typeCode << 4).toByteArray()
            let byte2 = UInt8(truncatingIfNeeded: fieldCode).toByteArray()
            return byte1 + byte2
        } else {
            // both are >= 16
            // first byte is all zeroes
            // second byte is type code
            // third byte is field code
            let byte1 = [UInt8](repeating: 0, count: 1)
            let byte2 = UInt8(truncatingIfNeeded: typeCode).toByteArray()
            let byte3 = UInt8(truncatingIfNeeded: fieldCode).toByteArray()
            return byte1 + byte2 + byte3
        }
    }
    
    /// Returns a FieldHeader object representing the type code and field code of a decoded field ID.
    private func decodeFieldId(fieldId: String) throws -> FieldHeader {
        let byteArray = Array<UInt8>.init(hex: fieldId)
        if byteArray.count == 1 {
            let highBits = byteArray[0] >> 4
            let lowBits = byteArray[0] & 0x0F
            return FieldHeader(typeCode: Int(highBits), fieldCode: Int(lowBits))
        } else if byteArray.count == 2 {
            let firstByte = byteArray[0]
            let secondByte = byteArray[1]
            let firstByteHighBits = firstByte >> 4
            let firstByteLowBits = firstByte & 0x0F
            if firstByteHighBits == 0 {
                return FieldHeader(typeCode: Int(secondByte), fieldCode: Int(firstByteLowBits))
            } else {
                return FieldHeader(typeCode: Int(firstByteHighBits), fieldCode: Int(secondByte))
            }
        } else if byteArray.count == 3 {
            return FieldHeader(typeCode: Int(byteArray[1]), fieldCode: Int(byteArray[2]))
        } else {
            throw XRPLBinaryCodeException.binaryCodec("Field ID must be between 1 and 3 bytes. \nThis field ID contained \(byteArray.count) bytes.")
        }
    }
}

extension FixedWidthInteger {
    public func toByteArray() -> [UInt8] {
        withUnsafeBytes(of: self.bigEndian, Array.init)
    }
}
