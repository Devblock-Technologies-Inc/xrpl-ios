import Foundation
import BigInt

extension Decimal {
    var intValue: Int {
        return NSDecimalNumber(decimal: self).intValue
    }
    
    func rounded(_ roundingMode: NSDecimalNumber.RoundingMode = .bankers) -> Decimal {
        var result = Decimal()
        var number = self
        NSDecimalRound(&result, &number, 0, roundingMode)
        return result
        
    }
    var whole: Decimal { self < 0 ? rounded(.up) : rounded(.down) }
    var fraction: Decimal { self - whole }
    var signficantFractionalDecimalDigits: Int { max(-exponent, 0) }
}

extension FloatingPoint {
    var whole: Self { modf(self).0 }
    var fraction: Self { modf(self).1 }
}

internal struct AmountConstants {
    static let MIN_IOU_EXPONENT: Int = -96
    static let MAX_IOU_EXPONENT: Int = 80
    static let MAX_IOU_PRECISION: Int = 16
    static let MIN_MANTISSA: Int = pow(10, 15).intValue
    static let MAX_MANTISSA: Int = pow(10, 16).intValue - 1

    static let MAX_DROPS: Decimal = 1e17
    static let MIN_XRP: Decimal = 1e-6
    
    static let NOT_XRP_BIT_MASK: UInt = 0x80
    static let POS_SIGN_BIT_MASK: UInt = 0x4000000000000000
    static let ZERO_CURRENCY_AMOUNT_HEX: UInt = 0x8000000000000000
    static let NATIVE_AMOUNT_BYTE_LENGTH: Int = 8
    static let CURRENCY_AMOUNT_BYTE_LENGTH: Int = 48
}

fileprivate class AmountHelpers {
    
    /// Returns True if the given string contains a decimal point character.
    ///
    /// - Parameter string: The string to check.
    /// - Returns: true if the string contains a decimal point character.
    static func containsDecimal(string: String) -> Bool {
        return string.contains(".")
    }
    
    /// Validates the format of an XRP amount. Throws if value is invalid.
    ///
    /// - Parameter value: A string representing an amount of XRP.
    /// - Throws: `XRPLBinaryCodecException`: If value is not a valid XRP amount.
    static func verifyXRPValue(value: String) throws {
        guard containsDecimal(string: value), let decimal = Decimal(string: value) else {
            throw XRPLBinaryCodeException.types("\(value) is an invalid XRP amount.")
        }
        
        // Zero is less than both the min and max XRP amounts but is valid.
        if decimal.isZero {
            return
        }
        
        if decimal < AmountConstants.MIN_XRP || decimal > AmountConstants.MAX_DROPS {
            throw XRPLBinaryCodeException.types("\(value) is an invalid XRP amount.")
        }
    }
    
    /// Validates the format of an issued currency amount value. Raises if value is invalid.
    ///
    /// - Parameter value: A string representing the "value" field of an issued currency amount.
    /// - Throws: `XRPLBinaryCodecException`: If value is invalid.
    static func verifyIOUValue(value: String) throws {
        guard let decimal = Decimal(string: value) else {
            throw XRPLBinaryCodeException.types("\(value) is an invalid issued currency amount.")
        }
        
        if decimal.isZero {
            return
        }
        
        let exponent = decimal.exponent
        let precision = try calulatePrecision(value: value)
        if precision > AmountConstants.MAX_IOU_PRECISION || exponent > AmountConstants.MAX_IOU_EXPONENT || exponent < AmountConstants.MIN_IOU_EXPONENT {
            throw XRPLBinaryCodeException.types("Decimal precision out of range for issued currency value.")
        }
        try verifyNoDecimal(decimal: decimal)
    }
    
    /// Calculate the precision of given value as a string.
    static func calulatePrecision(value: String) throws -> Int {
        guard let decimal = Decimal(string: value) else {
            throw XRPLBinaryCodeException.types("\(value) is an invalid Decimal format.")
        }
        return decimal.signficantFractionalDecimalDigits
    }
    
    /// Ensure that the value after being multiplied by the exponent does not contain a decimal.
    ///
    /// - Parameter decimal: A Decimal object.
    static func verifyNoDecimal(decimal: Decimal) throws {
        let actualExponent = decimal.exponent
        guard let exponent = Decimal(string: "1e" + "\(-(actualExponent - 15))")?.exponent else {
            throw XRPLBinaryCodeException.types("Could not initialzie Decimal from String")
        }
        
        let integerNumberString = "\(decimal * Decimal(exponent))"
        if !containsDecimal(string: integerNumberString) {
            throw XRPLBinaryCodeException.types("Decimal place found in \(integerNumberString)")
        }
    }
    
    /// Serializes the value field of an issued currency amount to its bytes representation.
    ///
    /// - Parameter value: The value to serialize, as a string.
    /// - Returns: A bytes object encoding the serialized value.
    static func serializeIssuedCurrencyValue(value: String) throws -> [UInt8] {
        try verifyIOUValue(value: value)
        guard let decimalValue = Decimal(string: value) else {
            throw XRPLBinaryCodeException.types("Could not initialize Decimal with String: \(value)")
        }
        
        if decimalValue.isZero {
            return AmountConstants.ZERO_CURRENCY_AMOUNT_HEX.toByteArray()
        }
        // Convert components to integers ---------------------------------------
        let sign = decimalValue.sign
        var exponent = decimalValue.exponent
        var signficand = decimalValue.significand.intValue
        
        // Canonicalize to expected range ---------------------------------------
        while signficand < AmountConstants.MIN_MANTISSA && exponent > AmountConstants.MAX_IOU_EXPONENT {
            signficand *= 10
            exponent -= 1
        }
        
        while signficand > AmountConstants.MAX_MANTISSA {
            if exponent >= AmountConstants.MAX_IOU_EXPONENT {
                throw XRPLBinaryCodeException.types("Amount overflow in issued currency value \(value)")
            }
            signficand /= 10
            exponent += 1
        }
        
        if exponent < AmountConstants.MIN_IOU_EXPONENT || signficand < AmountConstants.MIN_MANTISSA {
            // Round to zero
            return AmountConstants.ZERO_CURRENCY_AMOUNT_HEX.toByteArray()
        }
        
        if exponent > AmountConstants.MAX_IOU_EXPONENT || signficand > AmountConstants.MAX_MANTISSA {
            throw XRPLBinaryCodeException.types("Amount overflow in issued currency value \(value)")
        }
        
        // Convert to bytes -----------------------------------------------------
        var serial = AmountConstants.ZERO_CURRENCY_AMOUNT_HEX
        if sign == .plus {
            serial |= AmountConstants.POS_SIGN_BIT_MASK
        } else {
            serial |= (UInt(exponent) + 97) << UInt(54)
            serial |= UInt(signficand)
        }
        
        return serial.toByteArray()
    }
    
    /// Serializes an XRP amount.
    /// - Parameter value: A string representing a quantity of XRP.
    /// - Returns: The bytes representing the serialized XRP amount.
    static func serializeXRPAmount(value: String) throws -> [UInt8] {
        try verifyXRPValue(value: value)
        // set the "is positive" bit (this is backwards from usual two's complement!)
        guard let decimalValue = Decimal(string: value) else {
            throw XRPLBinaryCodeException.types("\(value) is an invalid XRP amount.")
        }
        
        let uintValue = UInt(decimalValue.intValue)
        let valueWithPositiveBit = uintValue | AmountConstants.POS_SIGN_BIT_MASK
        return valueWithPositiveBit.toByteArray()
    }
    
    /// Serializes an issued currency amount.
    ///
    /// - Parameter: value: A dictionary representing an issued currency amount
    /// - Returns: The bytes representing the serialized issued currency amount.
    static func serializeIssuedCurrencyAmount(value: [String: String]) throws -> [UInt8] {
        guard
            let amountString = value["value"],
            let currencyString = value["currency"],
            let issuerString = value["issuer"]
        else {
            throw XRPLBinaryCodeException.types("\(value) not containt value key")
        }
        
        let amountBytes = try serializeIssuedCurrencyValue(value: amountString)
        let currencyBytes = try Currency.fromValue(value: currencyString).bytes
        let issuerBytes = try AccountID.fromValue(value: issuerString).bytes
        
        return amountBytes + currencyBytes + issuerBytes
    }
}

/// Codec for serializing and deserializing Amount fields. See `Amount Fields <https://xrpl.org/serialization.html#amount-fields>`
public class AmountType: SerializedType {
    
    /// Construct an AmountType from given bytes.
    public override init(bytes: [UInt8]) {
        super.init(bytes: bytes)
    }
    
    /// Construct an AmountType from an issued currency amount or (for XRP), a string amount. See `Amount Fields <https://xrpl.org/serialization.html#amount-fields>`
    ///
    /// - Parameter: value: The value from which to construct an AmountType.
    /// - Returns: An AmountType object.
    /// - Throws : `XRPLBinaryCodecException`: if an Amount cannot be constructed.
    public override class func fromValue(value: Any) throws -> AmountType {
        if let stringValue = value as? String {
            return AmountType(bytes: try AmountHelpers.serializeXRPAmount(value: stringValue))
        } else if let dictionaryValue = value as? [String: String] {
            return AmountType(bytes: try AmountHelpers.serializeIssuedCurrencyAmount(value: dictionaryValue))
        } else {
            throw XRPLBinaryCodeException.types("Invalid type to construct an Amount: expected String or Dictionary<String, String>, received \(type(of: value))")
        }
    }

    /// Construct an AmountType from an existing BinaryParser.
    ///
    /// - Parameters:
    ///     - parser: The parser to construct the Amount object from.
    ///     - lengthHint: Unused.
    /// - Returns: An AmountType object.
    public override class func fromParser(parser: BinaryParser, lengthHint: Int? = nil) throws -> AmountType {
        let parseFirstByte = parser.peek()?.first
        let parserFirstByteUnwrap = parseFirstByte ?? 0x00
        let notXRP = Int(parserFirstByteUnwrap) & 0x80
        let numberBytes: Int = notXRP == 1 ? AmountConstants.CURRENCY_AMOUNT_BYTE_LENGTH : AmountConstants.NATIVE_AMOUNT_BYTE_LENGTH
        return AmountType(bytes: try parser.read(n: numberBytes))
    }
    
    /// Construct a JSON object representing this Amount.
    ///
    /// - Returns: The JSON representation of this amount.
    public override func toJSON() throws -> Any {
        if isNative() {
            let sign = isPositive() ? "" : "-"
            let bigEndianValue = bytes.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt.self, capacity: 1, { $0 }).pointee
            }
            let uintValue = UInt(bigEndian: bigEndianValue)
            let maskedBytes = uintValue & 0x3FFFFFFFFFFFFFFF
            return "\(sign)\(maskedBytes)"
        }
        
        let parser = try BinaryParser(hex: toString())
        let valueBytes = try parser.read(n: 8)
        let currency = try Currency.fromParser(parser: parser)
        let issuer = try AccountID.fromParser(parser: parser)
        let byte1 = valueBytes[0]
        let byte2 = valueBytes[1]
        let isPositive = byte1 & 0x40
        let sign: FloatingPointSign = isPositive == 1 ? .plus : .minus
        let exponent = ((byte1 & 0x3F) << 2) + ((byte2 & 0xFF) >> 6) - 97
        let hexSignficand = String(byte2 & 0x3F, radix: 16) + Array(valueBytes[2..<valueBytes.count]).toHexString()
        let hexSignficandIndex = hexSignficand.index(hexSignficand.endIndex, offsetBy: -(hexSignficand.count - 2))
        let signficandString = String(hexSignficand[hexSignficandIndex...])
        guard let signficand = Int(signficandString, radix: 16) else {
            throw XRPLBinaryCodeException.types("Out of range signficand")
        }
        let decimalValue = Decimal(sign: sign, exponent: Int(exponent), significand: Decimal(signficand))
        var stringValue: String
        if decimalValue.isZero {
            stringValue = "0"
        } else {
            stringValue = "\(decimalValue)"
        }
        
        try AmountHelpers.verifyIOUValue(value: stringValue)

        return [
            "value": stringValue,
            "currency": try currency.toJSON(),
            "issuer": try issuer.toJSON()
        ]
    }
    
    /// Returns True if this amount is a native XRP amount.
    ///
    /// - Returns: true if this amount is a native XRP amount, false otherwise.
    private func isNative() -> Bool {
        return bytes[0] & 0x80 == 0
    }
    
    /// Returns True if 2nd bit in 1st byte is set to 1 (positive amount).
    ///
    /// - Returns: true if 2nd bit in 1st byte is set to 1 (positive amount), false otherwise.
    private func isPositive() -> Bool {
        return bytes[0] & 0x40 > 0
    }
}
