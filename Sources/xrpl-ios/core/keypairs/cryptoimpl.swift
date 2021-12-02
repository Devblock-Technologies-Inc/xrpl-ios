import Foundation

/// Protocol for cryptographic algorithms in the XRP Ledger. The classes for all cryptographic algorithms are derived from this protocol.
public protocol CryptoProtocol {
    func deriveKeypair(cryptoAlgorithm: CryptoAlgorithm, decodedSeed: [UInt8], isValidator: Bool) -> (String, String)
    func sign(cryptoAlgorithm: CryptoAlgorithm, message: [UInt8], privateKey: String) -> [UInt8]
    func isValidMessage(cryptoAlgorithm: CryptoAlgorithm, message: [UInt8], signature: [UInt8], publicKey: [UInt8]) -> Bool
}
