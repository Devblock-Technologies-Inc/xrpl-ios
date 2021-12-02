import Foundation

/// base58 encodings: https://xrpl.org/base58-encodings.html
public class Codec {
    
    /// Account address (20 bytes)
    private let classicAddressPrefix: [UInt] = [0x0]
    
    /// value is 35; Account public key (33 bytes)
    private let accountPublicKeyPrefix: [UInt] = [0x23]
    
    /// value is 33; Seed value (for secret keys) (16 bytes)
    private static let familySeedPrefix: [UInt] = [0x21]
    
    /// value is 28; Validation public key (33 bytes)
    private let nodePublicKeyPrefix: [UInt] = [0x1C]
    
    /// [1, 225, 75]
    private static let ed25519SeedPrefix: [UInt] = [0x01, 0xE1, 0x4B]

    private let seedLength: UInt = 16

    private let classicAddressLength: UInt = 20
    private let nodePublicKeyLength: UInt = 33
    private let accountPublicKeyLength: UInt = 33
    
    private let algorithmToPrefixMap: [CryptoAlgorithm: [UInt]] = [
        .ED25519: ed25519SeedPrefix,
        .SECP256K1: familySeedPrefix
    ]

    /// - Returns: The base58 encoding of the bytestring, with the given data prefix (which indicates type) and while ensuring the bytestring is the expected length.
    private func encode(byteString: [UInt8], prefix: [UInt], exceptedLength: UInt) throws -> String {
        guard byteString.count == exceptedLength else {
            throw XRPLAddressCodecException.unexpectedPayloadLength
        }
        
        let encodedPrefix = prefix.map { UInt8(_truncatingBits: $0) }
        let payload = encodedPrefix + byteString
        
        return Base58.encodeCheck(payload, alphabet: XRPL_ALPHABET)
    }
    
    /// - Parameter base58String: A base58 value.
    /// - Parameter prefix: The prefix prepended to the bytestring.
    /// - Returns: the byte decoding of the base58-encoded string.
    private func decode(base58String: String, prefix: [UInt8]) throws -> [UInt8] {
        let decoded = try Base58.decodeCheck(base58String, alphabet: XRPL_ALPHABET, prefix: prefix)
        
        guard [UInt8](decoded[0..<prefix.count]) == prefix else {
            throw XRPLAddressCodecException.prefixIncorrect
        }
        
        return [UInt8](decoded[prefix.count..<decoded.count])
    }
    
    /// Returns an encoded seed.
    /// - Parameter entropy: Entropy bytes of SEED_LENGTH.
    /// - Parameter encodingType: Either ED25519 or SECP256K1.
    public func encodeSeed(_ entropy: [UInt8], encodingType: CryptoAlgorithm) throws -> String {
        guard entropy.count == seedLength else {
            throw XRPLAddressCodecException.seedLength(seedLength)
        }
        // swiftlint:disable force_unwrapping
        let prefix = algorithmToPrefixMap[encodingType]!
        // swiftlint:enable force_unwrapping

        return try encode(byteString: entropy, prefix: prefix, exceptedLength: seedLength)
    }
    
    /// Returns (decoded seed, its algorithm).
    /// - Parameter seed: base58 encoding of a seed.
    /// - Returns: (decoded seed, its algorithm).
    /// - Throws: XRPLAddressCodecException.codecException: If the seed is invalid.
    public func decodeSeed(_ seed: String) throws -> ([UInt8], CryptoAlgorithm) {
        for algorithm in CryptoAlgorithm.allCases {
            // swiftlint:disable force_unwrapping
            let prefix = algorithmToPrefixMap[algorithm]!
            // swiftlint:enable force_unwrapping
            let decodedPrefix = prefix.map { UInt8(_truncatingBits: $0) }
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
        return try encode(byteString: byteString, prefix: classicAddressPrefix, exceptedLength: classicAddressLength)
    }
    
    /// Returns the decoded bytes of the classic address.
    /// - Parameter classicAddress: Classic address to be decoded.
    /// - Returns: The decoded bytes of the classic address.
    public func decodeClassicAddress(_ classicAddress: String) throws -> [UInt8] {
        let decodedClassicPrefixAddress = classicAddressPrefix.map { UInt8(_truncatingBits: $0) }
        return try decode(base58String: classicAddress, prefix: decodedClassicPrefixAddress)
    }
    
    /// Returns the node public key encoding of these bytes as a base58 string.
    /// - Parameter byteString: Bytes to be encoded.
    /// - Returns: The node public key encoding of these bytes as a base58 string.
    public func encodeNodePublicKey(_ byteString: [UInt8]) throws -> String {
        return try encode(byteString: byteString, prefix: nodePublicKeyPrefix, exceptedLength: nodePublicKeyLength)
    }
    
    /// Returns the decoded bytes of the node public key.
    /// - Parameter nodePublicKey: Node public key to be decoded.
    /// - Returns: The decoded bytes of the node public key.
    public func decodeNodePublicKey(_ nodePublicKey: String) throws -> [UInt8] {
        let decodedNodePublicKeyPrefix = nodePublicKeyPrefix.map { UInt8(_truncatingBits: $0) }
        return try decode(base58String: nodePublicKey, prefix: decodedNodePublicKeyPrefix)
    }
    
    /// Returns the account public key encoding of these bytes as a base58 string.
    /// - Parameter byteString: Bytes to be encoded.
    /// - Returns: The account public key encoding of these bytes as a base58 string.
    public func encodeAccountPublicKey(_ byteString: [UInt8]) throws -> String {
        return try encode(byteString: byteString, prefix: accountPublicKeyPrefix, exceptedLength: accountPublicKeyLength)
    }
    
    /// Returns the decoded bytes of the account public key.
    /// - Parameter accountPublicKey: Account public key to be decoded.
    /// - Returns: The decoded bytes of the account public key.
    public func decodeAccountPublicKey(_ accountPublicKey: String) throws -> [UInt8] {
        let decodedAccountPublicKeyPrefix = accountPublicKeyPrefix.map { UInt8(bitPattern: Int8($0)) }
        return try decode(base58String: accountPublicKey, prefix: decodedAccountPublicKeyPrefix)
    }
    
    /// Returns whether `classic_address` is a valid classic address.
    /// - Parameter classicAddress: The classic address to validate.
    /// - Returns: Whether `classic_address` is a valid classic address.
    public func isvalidClassicAddress(_ classicAddress: String) -> Bool {
        do {
            _ = try decodeClassicAddress(classicAddress)
            return true
        } catch {
            return false
        }
    }
}
