import Foundation

/// A container class for simultaneous storage of a field's type code and field code.
/// `See Field Order <https://xrpl.org/serialization.html#canonical-field-order>`
public struct FieldHeader: Hashable, Equatable {
    
    public let typeCode: Int
    public let fieldCode: Int
    
    public static func ==(lhs: FieldHeader, rhs: FieldHeader) -> Bool {
        return lhs.typeCode == rhs.typeCode && lhs.fieldCode == rhs.fieldCode
    }
    
    /// Get the bytes representation of a FieldHeader.
    public var bytes: [UInt8] {
        var header: [UInt8] = []
        if typeCode < 16 {
            if fieldCode < 16 {
                header.append(UInt8(_truncatingBits: UInt(typeCode << 4) | UInt(fieldCode)))
            } else {
                header.append(UInt8(_truncatingBits: UInt(typeCode << 4)))
                header.append(UInt8(_truncatingBits: UInt(fieldCode)))
            }
        } else if fieldCode < 16 {
            header += [UInt8(_truncatingBits: UInt(fieldCode)), UInt8(_truncatingBits: UInt(typeCode))]
        } else {
            header += [0, UInt8(_truncatingBits: UInt(typeCode)), UInt8(_truncatingBits: UInt(fieldCode))]
        }
        
        return header
    }
}
