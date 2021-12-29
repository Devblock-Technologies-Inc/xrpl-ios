import Foundation
import CryptoSwift

/// odec for serializing and deserializing AccountID fields.
///
/// See `AccountID Fields <https://xrpl.org/serialization.html#accountid-fields>`
public class AccountID: Hash160 {
    
    private static let hexRegex = "^[A-F0-9]{40}$"
    private static let addressCodec = AddressCodec()
    
    public override class func fromValue(value: String) throws -> AccountID {
        if value.isEmpty {
            return AccountID()
        }
        
        if hexRegex.fullMatch(value) {
            // hex-encoded case
            return AccountID(bytes: Array<UInt8>.init(hex: value))
        } else if addressCodec.isvalidClassicAddress(value) {
            // base58 case
            return AccountID(bytes: try addressCodec.decodeClassicAddress(value))
        } else if addressCodec.isValidXAddress(xAddress: value) {
            let classicAddress = try addressCodec.xAddresToClassicAddress(xAddress: value).classicAddress
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
