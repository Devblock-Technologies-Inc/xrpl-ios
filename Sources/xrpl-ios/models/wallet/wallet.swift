import Foundation

public struct Wallet {
    
    public let seed: String
    public let privateKey: String
    public let publicKey: String
    public let classicAddress: String
    public let sequence: Int
    
    /// Generate a new Wallet.
    ///
    /// - Parameters:
    ///     - seed: The seed from which the public and private keys are derived.
    ///     - sequence: The next sequence number for the account.
    ///
    /// ```seed``` The core value that is used to derive all other information about this wallet. MUST be kept secret!
    ///
    /// ```publicKey``` The public key that is used to identify this wallet's signatures, as a hexadecimal string.
    ///
    /// ```publicKey``` The private key that is used to create signatures, as a hexadecimal string. MUST be kept secret!
    ///
    /// ```classicAddress``` The address that publicly identifies this wallet, as a base58 string.
    ///
    /// ```sequence``` The next available sequence number to use for transactions from this wallet.
    /// Must be updated by the user. Increments on the ledger with every successful transaction submission, and stays the same with every failed transaction submission.
    public init(seed: String, sequence: Int) throws {
        self.seed = seed
        let keypair = try KeyPairService.deriveKeypair(seed: seed)
        self.privateKey = keypair.privateKey
        self.publicKey = keypair.publicKey
        self.classicAddress = try KeyPairService.deriveClassicAddress(publicKey: publicKey)
        self.sequence = sequence
    }
    
    /// Generates a new seed and Wallet.
    ///
    /// - Parameter cryptoAlgorithm: The key-generation algorithm to use when generating the seed. The default is Ed25519.
    /// - Returns: The wallet that is generated from the given seed.
    public static func create(cryptoAlgorithm: CryptoAlgorithm = .ED25519) throws -> Wallet {
        let seed = try KeyPairService.generateSeed(algorithm: cryptoAlgorithm)
        return try Wallet(seed: seed, sequence: 0)
    }
    
    /// Returns the X-Address of the Wallet's account.
    ///
    /// - Parameters:
    ///     - tag: the destination tag of the address. Defaults to `0`.
    ///     - isTest: whether the address corresponds to an address on the test network.
    /// - Returns: The X-Address of the Wallet's account.
    public func getXAddress(tag: Int = 0, isTest: Bool = false) throws -> String {
        return try AddressCodec().classicAddressToXAddress(classicAddress: classicAddress, tag: tag, isTestNetwork: isTest)
    }
    
    /// Returns a string representation of a Wallet.
    public func toString() -> String {
        let arrayString = [
            "public_key: \(publicKey)",
            "private_key: -HIDDEN-",
            "classic_address: \(classicAddress)"
        ]
        return arrayString.joined(separator: "\n")
    }
}
