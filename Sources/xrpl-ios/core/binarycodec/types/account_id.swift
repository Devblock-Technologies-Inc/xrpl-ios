import Foundation
import CryptoSwift

/// Codec for serializing and deserializing AccountID fields.
///
/// See `AccountID Fields <https://xrpl.org/serialization.html#accountid-fields>`
public class AccountID: Hash160 {
    
    private static let hexRegex = "^[A-F0-9]{40}$"
    private static let addressCodec = AddressCodec()
    
    public override class func fromValue(value: Any) throws -> AccountID {
        guard let stringValue = value as? String else {
            throw XRPLBinaryCodeException.types("Invalid type to construct an AccountID: expected String, received \(type(of: value))")
        }
        
        if stringValue.isEmpty {
            return AccountID()
        }
        
        if hexRegex.fullMatch(stringValue) {
            // hex-encoded case
            return AccountID(bytes: Array<UInt8>.init(hex: stringValue))
        } else if addressCodec.isvalidClassicAddress(stringValue) {
            // base58 case
            return AccountID(bytes: try addressCodec.decodeClassicAddress(stringValue))
        } else if addressCodec.isValidXAddress(xAddress: stringValue) {
            let classicAddress = try addressCodec.xAddresToClassicAddress(xAddress: stringValue).classicAddress
            return AccountID(bytes: try addressCodec.decodeClassicAddress(classicAddress))
        } else {
            throw XRPLBinaryCodeException.types("Invalid value to construct an AccountID: expected valid classic address or X-Address, received \(value)")
        }
    }
    
    /// Return the value of this AccountID encoded as a base58 string.
    ///
    /// - Returns: The JSON representation of the AccountID.
    public override func toJSON() throws -> Any {
        return try AccountID.addressCodec.encodeClassicAddress(bytes)
    }
}

extension String {
    public func fullMatch(_ value: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: self)
            return !regex.matches(in: value, options: .anchored, range: NSRange(location: 0, length: value.count)).isEmpty
        } catch {
            return false
        }
    }
}
