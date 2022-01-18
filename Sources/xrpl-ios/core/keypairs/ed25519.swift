import Foundation
import Crypto

internal struct ED25519Service: CryptoProtocol {
    
    internal static let prefix = "ED"
    
    /// Signs a message using a given Ed25519 private key.
    ///
    /// - Parameters
    ///     - message: The message to sign, as bytes.
    ///     - privateKey: The private key to use to sign the message.
    /// - Returns: The signature of the message.
    internal static func sign(message: [UInt8], privateKey: String) throws -> [UInt8] {
        let rawPrivateKey = String(privateKey.suffix(privateKey.count - prefix.count))
        let wrappedPrivateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: Array<UInt8>.init(hex: rawPrivateKey))
        let signatureData = try wrappedPrivateKey.signature(for: Data(message))
        
        return [UInt8](signatureData)
    }
    
    /// Verifies the signature on a given message.
    ///
    /// - Parameters:
    ///     - message: The message to validate.
    ///     - signature: The signature of the message.
    ///     - publicKey: The public key to use to verify the message and signature.
    /// - Returns: Whether the message is valid for the given signature and public key.
    internal static func isValidMessage(message: [UInt8], signature: [UInt8], publicKey: String) throws -> Bool {
        let rawPublicKey = String(publicKey.suffix(publicKey.count - prefix.count))
        let wrappedPublicKey = try Curve25519.Signing.PublicKey(rawRepresentation: Array<UInt8>.init(hex: rawPublicKey))
        
        return wrappedPublicKey.isValidSignature(Data(signature), for: Data(message))
    }
    
    /// Derives a key pair in Ed25519 format for use with the XRP Ledger from a seed value.
    ///
    /// - Parameters
    ///     - decodedSeed: The Ed25519 seed to derive a key pair from, as bytes.
    ///     - isValidator: Whether to derive a validator keypair. However, validator signing keys cannot use Ed25519. (See `#3434 <https://github.com/ripple/rippled/issues/3434>`for more information.)
    /// - Returns: A (public key, private key) pair derived from the given seed.
    /// - Throws:`XRPLKeypairsException`: If the keypair is a validator keypair.
    internal static func deriveKeypair(decodedSeed: [UInt8], isValidator: Bool) throws -> KeyPair {
        let rawPrivateKey = KeyPairHelpers.getSHA512FirstHalf(decodedSeed)
        let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: rawPrivateKey)
        let privateKeyHex = [UInt8](privateKey.rawRepresentation).toHexString()
        let publicKey = privateKey.publicKey
        let publicKeyHex = [UInt8](publicKey.rawRepresentation).toHexString()
        
        return KeyPair(privateKey: prefix + privateKeyHex.uppercased(), publicKey: prefix + publicKeyHex.uppercased())
    }
}
