import Foundation

public struct KeyPair {
    let privateKey: String
    let publicKey: String
}

extension CryptoAlgorithm {
    internal var module: CryptoProtocol.Type {
        switch self {
        case .ED25519:
            return ED25519Service.self
        case .SECP256K1:
            return SECP255K1Service.self
        }
    }
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
    ///     - seed: Seed to derive the key pair from.
    ///     - validator: Whether the keypair is a validator keypair.
    /// - Returns: A (private key, public key) pair derived from the given seed.
    /// - Throws: `XRPLKeypairsException`: If the derived keypair did not generate a verifiable signature.
    ///
    /// Use `func` `generateSeed()` to generate an appropriate value.
    /// ```
    ///  let seed = try KeyPairService.generateSeed()
    /// ```
    public static func deriveKeypair(seed: String, validator: Bool = false) throws -> KeyPair {
        let (decodedSeed, algorithm) = try codec.decodeSeed(seed)
        let keypair = try algorithm.module.deriveKeypair(decodedSeed: decodedSeed, isValidator: validator)
        let signature = try algorithm.module.sign(message: verificationMessageString.bytes, privateKey: keypair.privateKey)
        guard try algorithm.module.isValidMessage(message: verificationMessageString.bytes, signature: signature, publicKey: keypair.publicKey) else {
            throw XRPLKeyPairException.deriveKey("Derived keypair did not generate verifiable signature")
        }
        return keypair
    }
    
    /// Derive the XRP Ledger classic address for a given public key.
    ///
    /// - Parameter publicKey: The public key to derive the address from, as hexadecimal.
    /// - Returns: The classic address corresponding to the given public key.
    ///
    /// See `Address Derivation <https://xrpl.org/cryptographic-keys.html#account-id-and-address>`for more information.
    public static func deriveClassicAddress(publicKey: String) throws -> String {
        let accountId = KeyPairHelpers.getAccountId(publicKey: [UInt8](hex: publicKey))
        return try codec.encodeClassicAddress(accountId)
    }
    
    /// Sign a message using a given private key.
    ///
    /// - Parameters:
    ///     - message: The message to sign, as bytes.
    ///     - privateKey: The private key to use to sign the message.
    /// - Returns: Signed message, as hexadecimal.
    public static func sign(message: [UInt8], privateKey: String) throws -> String {
        return try getModuleFromKey(privateKey).sign(message: message, privateKey: privateKey).toHexString().uppercased()
    }
    
    /// Verifies the signature on a given message.
    ///
    /// - Parameters:
    ///     - message: The message to validate.
    ///     - signature: The signature of the message.
    ///     - publicKey: The public key to use to verify the message andsignature.
    /// - Returns: Whether the message is valid for the given signature and public key.
    public static func isValidMessage(message: [UInt8], signature: [UInt8], publicKey: String) throws -> Bool {
        return try getModuleFromKey(publicKey).isValidMessage(message: message, signature: signature, publicKey: publicKey)
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
    
    private static func getModuleFromKey(_ key: String) -> CryptoProtocol.Type {
        if key.hasPrefix(ED25519Service.prefix) {
            return ED25519Service.self
        } else {
            return SECP255K1Service.self
        }
    }
}
