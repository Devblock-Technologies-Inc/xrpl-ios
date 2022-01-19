import Foundation

// swiftlint:disable identifier_name
/// The dictionary used for XRPL base58 encodings
public let XRPL_ALPHABET: [UInt8] = "rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz".bytes
// swiftlint:enable identifier_name

extension StringProtocol {
    public var data: Data { .init(utf8) }
    public var bytes: [UInt8] { .init(utf8) }
}
