import Foundation

// swiftlint:disable identifier_name
/// The dictionary used for XRPL base58 encodings
public let XRPL_ALPHABET: [UInt8] = "rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz".bytes
// swiftlint:enable identifier_name

extension StringProtocol {
    public var data: Data { .init(utf8) }
    public var bytes: [UInt8] { .init(utf8) }
    public var bytesFromHexString: [UInt8] {
        let stringArray = Array(self)
        var data: Data = Data()
        for i in stride(from: 0, to: self.count, by: 2) {
            let pair: String = String(stringArray[i]) + String(stringArray[i + 1])
            if let byteNum = UInt8(pair, radix: 16) {
                let byte = Data([byteNum])
                data.append(byte)
            } else {
                fatalError()
            }
        }
        return [UInt8](data)
    }
}
