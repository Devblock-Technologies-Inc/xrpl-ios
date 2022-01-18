import Crypto

public class ED25519Service: CryptoProtocol {
    public func sign(message: [UInt8], privateKey: String) -> [UInt8] {
        return Array<UInt8>()
    }
    
    public func isValidMessage(message: [UInt8], signature: [UInt8], publicKey: [UInt8]) -> Bool {
        return false
    }
    
    /// Derives a key pair in Ed25519 format for use with the XRP Ledger from a seed value.
    ///
    /// - Parameters
    ///     - decodedSeed: The Ed25519 seed to derive a key pair from, as bytes.
    ///     - isValidator: Whether to derive a validator keypair. However, validator signing keys cannot use Ed25519. (See `#3434 <https://github.com/ripple/rippled/issues/3434>`for more information.)
    /// - Returns: A (public key, private key) pair derived from the given seed.
    /// - Throws:`XRPLKeypairsException`: If the keypair is a validator keypair.
    public func deriveKeypair(decodedSeed: [UInt8], isValidator: Bool) throws -> KeyPair {
        let rawPrivateKey = Helpers.getSHA512FirstHalf(decodedSeed)
        let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: rawPrivateKey)
        let privateKeyHex = [UInt8](privateKey.rawRepresentation).toHexString()
        let publicKey = privateKey.publicKey
        let publicKeyHex = [UInt8](publicKey.rawRepresentation).toHexString()
        
        return KeyPair(privateKey: "ED" + privateKeyHex.uppercased(), publicKey: "ED" + publicKeyHex.uppercased())
    }
}

public class Helpers {
    public static func getSHA512FirstHalf(_ data: [UInt8]) -> [UInt8] {
        return Array(SHA512.hash(data: data).prefix(32))
    }
    
//    public func getAccountId(publicKey: [UInt8]) -> [UInt8] {
//        let shaHash = SHA512.hash(data: publicKey)
//
//
//    }
}
