import Foundation

public struct KeyPair {
    let privateKey: String
    let publicKey: String
}

public class KeyPairService {
    
    private static let verificationMessageString = "This test message should verify."
    private static let codec = Codec()
    
    /// Generate a seed value that cryptographic keys can be derived from.
    ///
    /// - Parameters:
    ///     - entropy: Must be at least addresscodec.SEED_LENGTH bytes long and will be truncated to that length
    ///     - algorithm: CryptoAlgorithm to use for seed generation. The  default is :data:`CryptoAlgorithm.ED25519 <xrpl.CryptoAlgorithm.ED25519>`.
    /// - Returns: A seed value that can be used to derive a key pair with the given cryptographic algorithm.
    public static func generateSeed(entropy: String? = nil, algorithm: CryptoAlgorithm = .ED25519) throws -> String {
        var parsedEntropy: [UInt8]
        if let entropyBytes = entropy?.bytes, entropyBytes.count >= CodecConstants.seedLength {
            parsedEntropy = [UInt8](entropyBytes.prefix(upTo: Array<UInt8>.Index(CodecConstants.seedLength)))
        } else {
            parsedEntropy = try secureRandomBytes(length: Int(CodecConstants.seedLength))
        }
        
        return try codec.encodeSeed(parsedEntropy, encodingType: algorithm)
    }
    
    /// Derive the public and private keys from a given seed value.
    ///
    /// - Parameters:
    ///     - seed: Seed to derive the key pair from. Use :func:`generate_seed() <xrpl.core.keypairs.generate_seed>` to generate an appropriate value.
    ///     - validator: Whether the keypair is a validator keypair.
    /// - Returns: A (private key, public key) pair derived from the given seed.
    /// - Throws: `XRPLKeypairsException`: If the derived keypair did not generate a verifiable signature.
    public static func deriveKeypair(seed: String, validator: Bool = false) throws -> KeyPair {
        let (decodedSeed, _) = try codec.decodeSeed(seed)
        // MARK: - TODO: will replace 'ED25519Service' to algorithm when finished secp255k1 service
        let keypair = try ED25519Service().deriveKeypair(decodedSeed: decodedSeed, isValidator: validator)
        // verify signature
        return keypair
    }
    
    private static func secureRandomBytes(length: Int) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        if status == errSecSuccess {
            return bytes
        } else {
            throw XRPLKeyPairException.secRandom("Failed - Generates an array of cryptographically secure random bytes.")
        }
    }
}
