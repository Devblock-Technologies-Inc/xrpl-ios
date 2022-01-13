import Foundation

/// Codec for encoding objects into the XRP Ledger's canonical binary format and decoding them.
public class BinaryCodec {
    
    private static let TRANSACTION_SIGNATURE_PREFIX = 0x53545800.toByteArray()
    private static let PAYMENT_CHANNEL_CLAIM_PREFIX = 0x434C4D00.toByteArray()
    private static let TRANSACTION_MULTISIGN_PREFIX = 0x534D5400.toByteArray()
    
    /// Encode a transaction or other object into the canonical binary format.
    ///
    /// - Parameter json: A JSON-like dictionary representation of an object.
    /// - Returns: The binary-encoded object, as a hexadecimal string.
    public static func encode(json: Dictionary<String, Any>) throws -> String {
        return try serializeJSON(json: json)
    }
    
    /// Encode a transaction into binary format in preparation for signing. (Only encodes fields that are intended to be signed.)
    ///
    /// - Parameter json: A JSON-like dictionary representation of a transaction.
    /// - Returns: The binary-encoded transaction, ready to be signed.
    public static func encodeForSigning(json: Dictionary<String, Any>) throws -> String {
        return try serializeJSON(json: json, prefix: TRANSACTION_SIGNATURE_PREFIX, signingOnly: true)
    }
    
    /// Encode a `payment channel <https://xrpl.org/payment-channels.html>` Claim to be signed.
    ///
    /// - Parameter json: A JSON-like dictionary representation of a Claim.
    /// - Returns: The binary-encoded claim, ready to be signed.
    public static func encodeForSigningClaim(json: Dictionary<String, Any>) throws -> String {
        guard let channelValue = json["channel"] else {
            throw XRPLBinaryCodeException.types("Input dictionary not contain 'channel' value")
        }
        guard let amountValue = json["amount"] else {
            throw XRPLBinaryCodeException.types("Input dictionary not contain 'amount' value")
        }
        let prefix = PAYMENT_CHANNEL_CLAIM_PREFIX
        let channel = try Hash160.fromValue(value: channelValue)
        let amount = try UInt16Type.fromValue(value: amountValue)
        let buffer = prefix + channel.bytes + amount.bytes
        
        return buffer.toHexString().uppercased()
    }
    
    /// Encode a transaction into binary format in preparation for providing one signature towards a multi-signed transaction. (Only encodes fields that are intended to be signed.)
    ///
    /// - Parameters:
    ///     - json: A JSON-like dictionary representation of a transaction.
    ///     - signingAccount: The address of the signer who'll provide the signature.
    /// - Returns: A hex string of the encoded transaction.
    public static func encodeForMultiSigning(json: Dictionary<String, Any>, signingAccount: String) throws -> String {
        let signingAccountId = try AccountID.fromValue(value: signingAccount).bytes
        return try serializeJSON(json: json, prefix: TRANSACTION_MULTISIGN_PREFIX, suffix: signingAccountId, signingOnly: true)
    }
    
    /// Decode a transaction from binary format to a JSON-like dictionary representation.
    ///
    /// - Parameter buffer: The encoded transaction binary, as a hexadecimal string.
    /// - Returns: A JSON-like dictionary representation of the transaction.
    public static func decode(buffer: String) throws -> Dictionary<String, Any> {
        let parser = try BinaryParser(hex: buffer)
        guard
            let parsedType = try parser.readType(SerializedDictType.self) as? SerializedDictType,
            let jsonDecoded = try parsedType.toJSON() as? Dictionary<String, Any>
        else {
            throw XRPLBinaryCodeException.types("Could not cast to SerializeDictType")
        }
        return jsonDecoded
    }
    
    private static func serializeJSON(json: [String: Any], prefix: [UInt8]? = nil, suffix: [UInt8]? = nil, signingOnly: Bool = false) throws -> String {
        var buffer = [UInt8]()
        if let prefix = prefix {
            buffer += prefix
        }
        buffer += try SerializedDictType.fromValue(value: json, onlySigning: signingOnly).bytes
        if let suffix = suffix {
            buffer += suffix
        }
        return buffer.toHexString().uppercased()
    }
}
