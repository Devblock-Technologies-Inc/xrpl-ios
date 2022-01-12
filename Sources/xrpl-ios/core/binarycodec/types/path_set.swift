import Foundation

private struct PathSetConstants {
    static let typeAccount: Int = 0x01
    static let typeCurrency: Int = 0x10
    static let typeIssuer: Int = 0x20
    static let pathSetEndByte: Int = 0x00
    static let pathSeparatorByte: Int = 0xFF
}

/// Serialize and deserialize a single step in a Path.
public class PathStepType: SerializedType {
    
    /// Helper function to determine if a dictionary represents a valid path step.
    fileprivate static func isPathStep(value: [String: String]) -> Bool {
        return value.keys.contains("issuer") || value.keys.contains("account") || value.keys.contains("currency")
    }
    
    /// Construct a PathStepType object from a dictionary.
    ///
    /// - Parameter value: The dictionary to construct a PathStepType object from.
    /// - Returns: The PathStepType constructed from value.
    /// - Throws: `XRPLBinaryCodecException` If the supplied value is of the wrong type.
    public override class func fromValue(value: Any) throws -> PathStepType {
        guard let dictionaryValue = value as? [String: String] else {
            throw XRPLBinaryCodeException.types("Invalid type to construct a PathStep: expected Dictionary<String, String>, received \(Swift.type(of: value))")
        }
        
        var dataType = 0x00
        var buffer = [UInt8]()
        
        if let accountValue = dictionaryValue["account"] {
            let accountId = try AccountID.fromValue(value: accountValue)
            buffer += accountId.bytes
            dataType |= PathSetConstants.typeAccount
        }
        
        if let currencyValue = dictionaryValue["currency"] {
            let currency = try Currency.fromValue(value: currencyValue)
            buffer += currency.bytes
            dataType |= PathSetConstants.typeCurrency
        }
        
        if let issuerValue = dictionaryValue["issuer"] {
            let issuer = try AccountID.fromValue(value: issuerValue)
            buffer += issuer.bytes
            dataType |= PathSetConstants.typeIssuer
        }
        
        return PathStepType(bytes: [UInt8(truncatingIfNeeded: dataType)] + buffer)
    }
    
    /// Construct a PathStepType object from an existing BinaryParser.
    ///
    /// - Parameter parser: The parser to construct a PathStepType from.
    /// - Returns: The PathStepType constructed from parser.
    public override class func fromParser(parser: BinaryParser, lengthHint: Int? = nil) throws -> PathStepType {
        let dataType = try parser.readUInt8()
        var buffer = [UInt8]()
        
        if dataType & PathSetConstants.typeAccount == 1 {
            let accountId = try parser.read(n: AccountID.width)
            buffer += accountId
        }
        
        if dataType & PathSetConstants.typeCurrency == 1 {
            let currency = try parser.read(n: Currency.width)
            buffer += currency
        }
        
        if dataType & PathSetConstants.typeIssuer == 1 {
            let issuer = try parser.read(n: AccountID.width)
            buffer += issuer
        }
        
        return PathStepType(bytes: [UInt8(truncatingIfNeeded: dataType)] + buffer)
    }
    
    /// Returns the JSON representation of a PathStepType.
    ///
    /// - Returns: The JSON representation of a PathStepType.
    public override func toJSON() throws -> Any {
        let parser = try BinaryParser(hex: bytes.toHexString())
        let dataType = try parser.readUInt8()
        var json = [String: Any]()
        
        if dataType & PathSetConstants.typeAccount == 1 {
            let accountId = try AccountID.fromParser(parser: parser).toJSON()
            json["account"] = accountId
        }
        
        if dataType & PathSetConstants.typeCurrency == 1 {
            let currency = try Currency.fromParser(parser: parser).toJSON()
            json["currency"] = currency
        }
        
        if dataType & PathSetConstants.typeIssuer == 1 {
            let issuer = try AccountID.fromParser(parser: parser).toJSON()
            json["issuer"] = issuer
        }
        
        return json
    }
    
    /// Get a number representing the type of this PathStepType.
    /// - Returns: a number to be bitwise and-ed with TYPE_ constants to describe the types in the PathStepType.
    public func type() -> Int {
        return Int(bytes[0])
    }
}

/// Class for serializing/deserializing Paths.
public class PathType: SerializedType {
    
    /// Construct a PathType from an array of dictionaries describing PathSteps.
    ///
    /// - Parameter value: The array to construct a PathType object from.
    /// - Returns: The PathType constructed from value.
    /// - Throws: `XRPLBinaryCodecException` If the supplied value is of the wrong type.
    public override class func fromValue(value: Any) throws -> PathType {
        guard let listValue = value as? [[String: String]] else {
            throw XRPLBinaryCodeException.types("Invalid type to construct a PathType: expected Array<Dictionary<String, String>>, received \(type(of: value))")
        }
        
        var buffer = [UInt8]()
        
        for dictionaryValue in listValue {
            let pathStepType = try PathStepType.fromValue(value: dictionaryValue)
            buffer += pathStepType.bytes
        }
        
        return PathType(bytes: buffer)
    }
    
    /// Construct a PathType object from an existing BinaryParser.
    ///
    /// - Parameter parser: The parser to construct a PathType from.
    /// - Returns: The PathType constructed from parser.
    public override class func fromParser(parser: BinaryParser, lengthHint: Int? = nil) throws -> PathType {
        var buffer = [UInt8]()
        
        while !parser.isEnd() {
            let pathStepType = try PathSetType.fromParser(parser: parser)
            buffer += pathStepType.bytes
            if parser.peek() == [UInt8(truncatingIfNeeded: PathSetConstants.pathSetEndByte)] || parser.peek() == [UInt8(truncatingIfNeeded: PathSetConstants.pathSeparatorByte)] {
                break
            }
        }
        
        return PathType(bytes: buffer)
    }
    
    /// Returns the JSON representation of a PathType.
    ///
    /// - Returns: The JSON representation of a PathType.
    public override func toJSON() throws -> Any {
        var json = [Any]()
        let pathTypeParser = try BinaryParser(hex: self.bytes.toHexString())
        
        while !pathTypeParser.isEnd() {
            let pathStepType = try PathStepType.fromParser(parser: pathTypeParser)
            json.append(try pathStepType.toJSON())
        }
        return json
    }
}

/// Codec for serializing and deserializing PathSet fields. See `PathSet Fields <https://xrpl.org/serialization.html#pathset-fields>`
public class PathSetType: SerializedType {
    
    /// Helper function to determine if a list represents a valid path set.
    fileprivate static func isPathSetType(value: [[[String: String]]]) -> Bool {
        return value.count == 0 || value[0].count == 0 || PathStepType.isPathStep(value: value[0][0])
    }
    
    /// Construct a PathSetType from a List of Lists representing paths.
    ///
    /// - Parameter value: The List to construct a PathSet object from.
    /// - Returns: The PathSetType constructed from value.
    /// - Throws: `XRPLBinaryCodecException`: If the PathSet representation is invalid.
    public override class func fromValue(value: Any) throws -> PathSetType {
        guard let listValue = value as? [[[String: String]]] else {
            throw XRPLBinaryCodeException.types("Invalid type to construct a PathSetType: expected Array<Array<Dictionary<String: String>>>, received \(type(of: value))")
        }
        
        guard PathSetType.isPathSetType(value: listValue) else {
            throw XRPLBinaryCodeException.types("Cannot construct PathSetType from given value")
        }
        
        var buffer = [UInt8]()
        for pathList in listValue {
            let pathType = try PathType.fromValue(value: pathList)
            buffer.append(contentsOf: pathType.bytes)
            buffer.append(UInt8(truncatingIfNeeded: PathSetConstants.pathSeparatorByte))
        }
        buffer.append(UInt8(truncatingIfNeeded: PathSetConstants.pathSetEndByte))
        
        return PathSetType(bytes: buffer)
    }
    
    /// Construct a PathSetType object from an existing BinaryParser.
    ///
    /// - Parameter parser: The parser to construct a PathSetType from.
    /// - Returns: The PathSetType constructed from parser.
    public override class func fromParser(parser: BinaryParser, lengthHint: Int? = nil) throws -> PathSetType {
        var buffer = [UInt8]()
        
        while !parser.isEnd() {
            let pathType = try PathType.fromParser(parser: parser)
            buffer.append(contentsOf: pathType.bytes)
            buffer.append(contentsOf: try parser.read(n: 1))
            if buffer.last == UInt8(truncatingIfNeeded: PathSetConstants.pathSetEndByte) {
                break
            }
        }
        
        return PathSetType(bytes: buffer)
    }
    
    /// Returns the JSON representation of a PathSetType.
    ///
    /// - Returns: The JSON representation of a PathSetType.
    public override func toJSON() throws -> Any {
        var json = [Any]()
        let pathSetParser = try BinaryParser(hex: self.bytes.toHexString())
        
        while !pathSetParser.isEnd() {
            let pathType = try PathType.fromParser(parser: pathSetParser)
            json.append(try pathType.toJSON())
            try pathSetParser.skip(n: 1)
        }
        
        return json
    }
}
