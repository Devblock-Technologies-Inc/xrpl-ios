import Foundation

fileprivate struct SerializedListContants {
    static let ARRAY_END_MARKER: [UInt8] = [0xF1]
    static let ARRAY_END_MARKER_NAME: String = "ArrayEndMarker"
    static let OBJECT_END_MARKER: [UInt8] = [0xE1]
}

/// Class for serializing and deserializing Lists of objects. See `Array Fields <https://xrpl.org/serialization.html#array-fields>`
public class SerializedListType: SerializedType {
    
    /// Construct a SerializedListType from a BinaryParser.
    ///
    /// - Parameter parser: The parser to construct a SerializedList from.
    /// - Returns: The SerializedListType constructed from parser.
    public override class func fromParser(parser: BinaryParser, lengthHint: Int? = nil) throws -> SerializedListType {
        var resultBytes = [UInt8]()
        
        while !parser.isEnd() {
            let field = try parser.readField()
            if field.fieldName == SerializedListContants.ARRAY_END_MARKER_NAME {
                break
            }
            resultBytes.append(contentsOf: field.fieldHeader.bytes)
            resultBytes.append(contentsOf: try parser.readFieldValue(field).bytes)
            resultBytes.append(contentsOf: SerializedListContants.OBJECT_END_MARKER)
        }
        resultBytes += SerializedListContants.ARRAY_END_MARKER
        
        return SerializedListType(bytes: resultBytes)
    }
    
    /// Create a SerializedListType object from a dictionary.
    ///
    /// - Parameter value: The dictionary to construct a SerializedList from.
    /// - Returns: The SerializedListType object constructed from value.
    /// - Throws: `XRPLBinaryCodecException`: If the provided value isn't a list or contains non-dict elements.
    public override class func fromValue(value: Any) throws -> SerializedListType {
        guard let arrayValue = value as? Array<Dictionary<String, Any>> else {
            throw XRPLBinaryCodeException.types("Invalid type to construct a SerializedListType: excepted Array<Dictionary<String, Any>, received \(type(of: value))")
        }
        
        var resultBytes = [UInt8]()
        for object in arrayValue {
            let transaction = try SerializedDictType.fromValue(value: object)
            resultBytes.append(contentsOf: transaction.bytes)
        }
        resultBytes.append(contentsOf: SerializedListContants.ARRAY_END_MARKER)
        
        return SerializedListType(bytes: resultBytes)
    }
    
    /// Returns the JSON representation of a SerializedListType.
    ///
    /// - Returns: The JSON representation of a SerializedListType.
    public override func toJSON() throws -> Any {
        var result = [Any]()
        let parser = try BinaryParser(hex: toString())
        
        while !parser.isEnd() {
            let field = try parser.readField()
            if field.fieldName == SerializedListContants.ARRAY_END_MARKER_NAME {
                break
            }
            var outer = [String: Any]()
            outer[field.fieldName] = try SerializedDictType.fromParser(parser: parser).toJSON()
            result.append(outer)
        }
        
        return result
    }
}
