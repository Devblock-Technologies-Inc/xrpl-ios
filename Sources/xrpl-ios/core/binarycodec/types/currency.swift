import Foundation

public class Currency: Hash160 {
    
    private static let currencyCodeLength = 20
    
    private var iso: String?
    
    public override init() {
        super.init(bytes: [UInt8](repeating: 0, count: Currency.currencyCodeLength))
        self.iso = try? isoCurrency(bytes: self.bytes)
    }
    
    public override init(bytes: [UInt8]) {
        super.init(bytes: bytes)
        self.iso = try? isoCurrency(bytes: self.bytes)
    }
    
    private func isoCurrency(bytes: [UInt8]) throws -> String? {
        let codeBytes = Array(bytes[12..<15])
        if bytes[0] != 0 {
            return nil
        } else if codeBytes.toHexString() == "000000" {
            return "XRP"
        } else {
            return try Currency.isoCodeFromHex(value: codeBytes)
        }
    }
    
    /// Tests if value is a valid 3-char iso code.
    private static func isISOCode(value: String) -> Bool {
        return ISO_CURRENCY_REGEX.fullMatch(value)
    }
    
    private static func isoCodeFromHex(value: [UInt8]) throws -> String? {
        let candidateISO = String(bytes: value, encoding: .ascii)
        if candidateISO == "XRP" {
            throw XRPLBinaryCodeException.types("Disallowed currency code: to indicate the currency XRP you must use 20 bytes of 0s")
        }
        
        if let candidateISO = candidateISO, isISOCode(value: candidateISO) {
            return candidateISO
        } else {
            return nil
        }
    }
    
    /// Tests if value is a valid 40-char hex string.
    private static func isHex(value: String) -> Bool {
        return HEX_CURRENCY_REGEX.fullMatch(value)
    }
    
    /// Convert an ISO code to a 160-bit (20 byte) encoded representation.
    ///
    /// See "Currency codes" subheading in `Amount Fields <https://xrpl.org/serialization.html#amount-fields>`
    private static func isoToBytes(iso: String) throws -> [UInt8] {
        guard isISOCode(value: iso) else {
            throw XRPLBinaryCodeException.types("Invalid ISO code: \(iso)")
        }
        
        if iso == "XRP" {
            // This code (160 bit all zeroes) is used to indicate XRP in
            // rare cases where a field must specify a currency code for XRP.
            return [UInt8](repeating: 0, count: Currency.currencyCodeLength)
        }
        
        guard let isoData = iso.data(using: .ascii) else {
            throw XRPLBinaryCodeException.types("Invalid ISO code: \(iso), could not decode to ASCII")
        }
        
        let isoBytes = [UInt8](isoData)
        
        // Currency Codes: https://xrpl.org/currency-formats.html#standard-currency-codes
        // 160 total bits:
        // 8 bits type code (0x00)
        // 88 bits reserved (0's)
        // 24 bits ASCII
        // 16 bits version (0x00)
        // 24 bits reserved (0's)
        
        return [UInt8](repeating: 0, count: 12) + isoBytes + [UInt8](repeating: 0, count: 5)
    }
    
    /// Construct a Currency object from a string representation of a currency.
    ///
    /// - Parameter value: The string to construct a Currency object from.
    /// - Returns: A Currency object constructed from value.
    /// - Throws: `XRPLBinaryCodecException` If the Currency representation is invalid.
    public override class func fromValue(value: Any) throws -> Currency {
        guard let stringValue = value as? String else {
            throw XRPLBinaryCodeException.types("Invalid type to construct a Currency: expected str, received \(type(of: value))")
        }
        
        if Currency.isISOCode(value: stringValue) {
            return Currency(bytes: try Currency.isoToBytes(iso: stringValue))
        } else if Currency.isHex(value: stringValue) {
            return Currency(bytes: [UInt8].init(hex: stringValue))
        } else {
            throw XRPLBinaryCodeException.types("Unsupported Currency representation: \(stringValue)")
        }
    }
    
    /// Returns the JSON representation of a currency.
    ///
    /// - Returns: The JSON representation of a Currency.
    public override func toJSON() throws -> Any {
        if let iso = self.iso {
            return iso
        } else {
            return self.bytes.toHexString().uppercased()
        }
    }
}
