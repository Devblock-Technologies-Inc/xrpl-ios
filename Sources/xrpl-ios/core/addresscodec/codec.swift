import Foundation

internal struct CodecConstants {
    
    /// Account address (20 bytes)
    static let classicAddressPrefix: [UInt8] = [0x0]
    
    /// value is 35; Account public key (33 bytes)
    static let accountPublicKeyPrefix: [UInt8] = [0x23]
    
    /// value is 33; Seed value (for secret keys) (16 bytes)
    static let familySeedPrefix: [UInt8] = [0x21]
    
    /// value is 28; Validation public key (33 bytes)
    static let nodePublicKeyPrefix: [UInt8] = [0x1C]
    
    /// [1, 225, 75]
    static let ed25519SeedPrefix: [UInt8] = [0x01, 0xE1, 0x4B]
    
    static let seedLength: UInt = 16

    static let classicAddressLength: UInt = 20
    static let nodePublicKeyLength: UInt = 33
    static let accountPublicKeyLength: UInt = 33
    
    static let algorithmToPrefixMap: [CryptoAlgorithm: [UInt8]] = [
        .ED25519: ed25519SeedPrefix,
        .SECP256K1: familySeedPrefix
    ]
}

/// base58 encodings: https://xrpl.org/base58-encodings.html
public class Codec {

    /// - Returns: The base58 encoding of the bytestring, with the given data prefix (which indicates type) and while ensuring the bytestring is the expected length.
    private func encode(byteString: [UInt8], prefix: [UInt8], exceptedLength: UInt) throws -> String {
        guard byteString.count == exceptedLength else {
            throw XRPLAddressCodecException.unexpectedPayloadLength
        }
        
        let payload = prefix + byteString
        return XBase58Check.encode(Data(payload))
    }
    
    /// - Parameter base58String: A base58 value.
    /// - Parameter prefix: The prefix prepended to the bytestring.
    /// - Returns: the byte decoding of the base58-encoded string.
    private func decode(base58String: String, prefix: [UInt8]) throws -> [UInt8] {
        let decoded = try XBase58Check.decode(base58String)
        
        guard [UInt8](decoded[0..<prefix.count]) == prefix else {
            throw XRPLAddressCodecException.prefixIncorrect
        }
        
        return [UInt8](decoded[prefix.count..<decoded.count])
    }
    
    /// Returns an encoded seed.
    /// - Parameter entropy: Entropy bytes of SEED_LENGTH.
    /// - Parameter encodingType: Either ED25519 or SECP256K1.
    public func encodeSeed(_ entropy: [UInt8], encodingType: CryptoAlgorithm) throws -> String {
        guard entropy.count == CodecConstants.seedLength else {
            throw XRPLAddressCodecException.seedLength(CodecConstants.seedLength)
        }
        // swiftlint:disable force_unwrapping
        let prefix = CodecConstants.algorithmToPrefixMap[encodingType]!
        // swiftlint:enable force_unwrapping

        return try encode(byteString: entropy, prefix: prefix, exceptedLength: CodecConstants.seedLength)
    }
    
    /// Returns (decoded seed, its algorithm).
    /// - Parameter seed: base58 encoding of a seed.
    /// - Returns: (decoded seed, its algorithm).
    /// - Throws: XRPLAddressCodecException.codecException: If the seed is invalid.
    public func decodeSeed(_ seed: String) throws -> ([UInt8], CryptoAlgorithm) {
        for algorithm in CryptoAlgorithm.allCases {
            // swiftlint:disable force_unwrapping
            let prefix = CodecConstants.algorithmToPrefixMap[algorithm]!
            // swiftlint:enable force_unwrapping
            let decodedPrefix = prefix
            do {
                let decoded = try decode(base58String: seed, prefix: decodedPrefix)
                return (decoded, algorithm)
            } catch {
                continue
            }
        }
        
        throw XRPLAddressCodecException.codecException("Invalid seed; could not determine encoding algorithm")
    }
    
    /// Returns the classic address encoding of these bytes as a base58 string.
    /// - Parameter bytestring: Bytes to be encoded.
    /// - Returns: The classic address encoding of these bytes as a base58 string.
    public func encodeClassicAddress(_ byteString: [UInt8]) throws -> String {
        return try encode(byteString: byteString, prefix: CodecConstants.classicAddressPrefix, exceptedLength: CodecConstants.classicAddressLength)
    }
    
    /// Returns the decoded bytes of the classic address.
    /// - Parameter classicAddress: Classic address to be decoded.
    /// - Returns: The decoded bytes of the classic address.
    public func decodeClassicAddress(_ classicAddress: String) throws -> [UInt8] {
        let decodedClassicPrefixAddress = CodecConstants.classicAddressPrefix
        return try decode(base58String: classicAddress, prefix: decodedClassicPrefixAddress)
    }
    
    /// Returns the node public key encoding of these bytes as a base58 string.
    /// - Parameter byteString: Bytes to be encoded.
    /// - Returns: The node public key encoding of these bytes as a base58 string.
    public func encodeNodePublicKey(_ byteString: [UInt8]) throws -> String {
        return try encode(byteString: byteString, prefix: CodecConstants.nodePublicKeyPrefix, exceptedLength: CodecConstants.nodePublicKeyLength)
    }
    
    /// Returns the decoded bytes of the node public key.
    /// - Parameter nodePublicKey: Node public key to be decoded.
    /// - Returns: The decoded bytes of the node public key.
    public func decodeNodePublicKey(_ nodePublicKey: String) throws -> [UInt8] {
        let decodedNodePublicKeyPrefix = CodecConstants.nodePublicKeyPrefix
        return try decode(base58String: nodePublicKey, prefix: decodedNodePublicKeyPrefix)
    }
    
    /// Returns the account public key encoding of these bytes as a base58 string.
    /// - Parameter byteString: Bytes to be encoded.
    /// - Returns: The account public key encoding of these bytes as a base58 string.
    public func encodeAccountPublicKey(_ byteString: [UInt8]) throws -> String {
        return try encode(byteString: byteString, prefix: CodecConstants.accountPublicKeyPrefix, exceptedLength: CodecConstants.accountPublicKeyLength)
    }
    
    /// Returns the decoded bytes of the account public key.
    /// - Parameter accountPublicKey: Account public key to be decoded.
    /// - Returns: The decoded bytes of the account public key.
    public func decodeAccountPublicKey(_ accountPublicKey: String) throws -> [UInt8] {
        let decodedAccountPublicKeyPrefix = CodecConstants.accountPublicKeyPrefix
        return try decode(base58String: accountPublicKey, prefix: decodedAccountPublicKeyPrefix)
    }
    
    /// Returns whether `classic_address` is a valid classic address.
    /// - Parameter classicAddress: The classic address to validate.
    /// - Returns: Whether `classic_address` is a valid classic address.
    public func isvalidClassicAddress(_ classicAddress: String) -> Bool {
        return (try? decodeClassicAddress(classicAddress)) != nil
    }
}
