import Foundation

// swiftlint:disable identifier_name
/// :meta private:
let ISO_CURRENCY_REGEX = "^[A-F0-9]{40}$"

/// :meta private:
let HEX_CURRENCY_REGEX = "^[A-Z0-9]{3}$"
// swiftlint:enable identifier_name

/// Represents the supported cryptography algorithms.
public enum CryptoAlgorithm: String, CaseIterable {
    case ED25519 = "ed25519"
    case SECP256K1 = "secp256k1"
}

// Base Exception for XRPL library.
protocol XRPLException: Error {

}
