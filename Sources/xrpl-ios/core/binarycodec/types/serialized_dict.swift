import Foundation

fileprivate struct SerializedDictContants {
    static let OBJECT_END_MARKER_BYTE: [UInt8] = [0xE1]
    static let OBJECT_END_MARKER: String = "ObjectEndMarker"
    static let SERIALIZED_DICT: String = "SerializedDict"
    static let DESTINATION: String = "Destination"
    static let ACCOUNT: String = "Account"
    static let SOURCE_TAG: String = "SourceTag"
    static let DEST_TAG: String = "DestinationTag"
}

fileprivate class SerializedDictHelpers {
    
    /// Break down an X-Address into a classic address and a tag.
    ///
    ///- Parameters:
    ///     - field: Name of field
    ///     - xAddress: X-Address corresponding to the field
    /// - Returns: A dictionary representing the classic address and tag.
    /// - Throws: `XRPLBinaryCodecException`: field-tag combo is invalid.
    static func handleXAddress(field: String, xAddress: String) throws -> Dictionary<String, Any> {
        let addressCodec = AddressCodec()
        let (classicAddress, tag, _) = try addressCodec.xAddresToClassicAddress(xAddress: xAddress)
        var tagName: String = ""
        if field == SerializedDictContants.DESTINATION {
            tagName = SerializedDictContants.DEST_TAG
        } else if field == SerializedDictContants.ACCOUNT {
            tagName = SerializedDictContants.SOURCE_TAG
        } else if tag != 0 {
            throw XRPLBinaryCodeException.types("\(field) cannot have an associated tag")
        }
        
        if tag != 0, !tagName.isEmpty {
            return [field: classicAddress, tagName: tag]
        } else {
            return [field: classicAddress]
        }
    }
    
    static func stringToEnum(field: String, value: Any) throws -> Any {
        // all of these fields have enum values that are used for serialization
        // converts the string name to the corresponding enum code
        let definations = try Definations.loadDefinations()
        if let stringValue = value as? String {
            switch field {
            case "TransactionType":
                return definations.getTransactionTypeCode(stringValue)
            case "TransactionResult":
                return definations.getTransactionResultCode(stringValue)
            case "LedgerEntryType":
                return definations.getLedgerEntryTypeCode(stringValue)
            default:
                return value
            }
        } else {
            return value
        }
    }
    
    static func enumToString(field: String, value: Any) throws -> Any {
        let definations = try Definations.loadDefinations()
        if let intValue = value as? Int {
            switch field {
            case "TransactionType":
                return definations.getTransactionTypeName(intValue)
            case "TransactionResult":
                return definations.getTransactionResultName(intValue)
            case "LedgerEntryType":
                return definations.getLedgerEntryTypeName(intValue)
            default:
                return value
            }
        } else {
            return value
        }
    }
}

/// Class for serializing/deserializing Dicts of objects.
public class SerializedDictType: SerializedType {
    
    /// Construct an SerializedDictType from given bytes.
    public override init(bytes: [UInt8]) {
        super.init(bytes: bytes)
    }
    
    /// Construct a SerializedDictType from a BinaryParser.
    /// - Parameter parser: The parser to construct a SerializedDictType from.
    /// - Returns: The SerializedDictType constructed from parser.
    public override class func fromParser(parser: BinaryParser, lengthHint: Int? = nil) throws -> SerializedDictType {
        let serializer = BinarySerializer()
        while !parser.isEnd() {
            let field = try parser.readField()
            if field.fieldName == SerializedDictContants.OBJECT_END_MARKER {
                break
            }
            let associatedValue = try parser.readFieldValue(field)
            try serializer.writeFieldAndValue(field: field, value: associatedValue)
            if field.fieldInfo.type == SerializedDictContants.SERIALIZED_DICT {
                serializer.append(bytesObject: SerializedDictContants.OBJECT_END_MARKER_BYTE)
            }
        }
        return SerializedDictType(bytes: serializer.bytesSink)
    }
    
    /// Create a SerializedDictType object from a dictionary.
    /// - Parameters:
    ///     - value: The dictionary to construct a SerializedDictType from.
    ///     - onlySigning: whether only the signing fields should be included.
    /// - Returns: The SerializedDictType object constructed from value.
    /// - Throws: `XRPLBinaryCodecException`: If the SerializedDict can't be constructed from value.
    // - MARK: - TODO: Should refactor adding the onlySigning param in superclass SerializedType
    public class func fromValue(value: Dictionary<String, Any>, onlySigning: Bool = false) throws -> SerializedDictType {
        // MARK: - TODO: Add conditions handled[SerializedDictContants.SOURCE_TAG] != value[SerializedDictContants.SOURCE_TAG]
        
        let addressCodec = AddressCodec()
        let serializer = BinarySerializer()
        var xAddressDecoded = [String: Any]()
        for (key, val) in value {
            if let stringValue = val as? String, addressCodec.isValidXAddress(xAddress: stringValue) {
                let handled = try SerializedDictHelpers.handleXAddress(field: key, xAddress: stringValue)
                if handled.keys.contains(SerializedDictContants.SOURCE_TAG)
                    && handled[SerializedDictContants.SOURCE_TAG] != nil
                    && value.keys.contains(SerializedDictContants.SOURCE_TAG)
                    && value[SerializedDictContants.SOURCE_TAG] != nil
                    /* && handled[SerializedDictContants.SOURCE_TAG] != value[SerializedDictContants.SOURCE_TAG] */ {
                    throw XRPLBinaryCodeException.types("Cannot have mismatched Account X-Address and SourceTag")
                }
                
                if handled.keys.contains(SerializedDictContants.DEST_TAG)
                    && handled[SerializedDictContants.DEST_TAG] != nil
                    && value.keys.contains(SerializedDictContants.DEST_TAG)
                    && value[SerializedDictContants.DEST_TAG] != nil
                    /* && handled[SerializedDictContants.DEST_TAG] != value[SerializedDictContants.DEST_TAG] */ {
                    throw XRPLBinaryCodeException.types("Cannot have mismatched Destination X-Address and DestinationTag")
                }
                
                xAddressDecoded = xAddressDecoded.merging(handled) { $1 }
            } else {
                xAddressDecoded[key] = try SerializedDictHelpers.stringToEnum(field: key, value: val)
            }
        }
        
        var sortedKeys = [FieldInstance]()
        let definations = try Definations.loadDefinations()
        for fieldName in xAddressDecoded.keys {
            let fieldInstance = definations.getFieldInstance(fieldName)
            if fieldInstance.fieldInfo.isSerialized {
                sortedKeys.append(fieldInstance)
            }
        }
        sortedKeys.sort(by: { $0.ordinal < $1.ordinal })
        
        if onlySigning {
            sortedKeys = sortedKeys.filter { $0.fieldInfo.isSigningField }
        }
        
        for fieldInstance in sortedKeys {
            guard let fieldName = xAddressDecoded[fieldInstance.fieldName] else {
                throw XRPLBinaryCodeException.types("Decoded fields not include \(fieldInstance.fieldName)")
            }
            let associatedValue = try SerializedType.getType(by: fieldInstance.fieldName).fromValue(value: fieldName)
            try serializer.writeFieldAndValue(field: fieldInstance, value: associatedValue)
            if fieldInstance.fieldInfo.type == SerializedDictContants.SERIALIZED_DICT {
                serializer.append(bytesObject: SerializedDictContants.OBJECT_END_MARKER_BYTE)
            }
        }
        
        return SerializedDictType(bytes: serializer.bytesSink)
    }
    
    /// Returns the JSON representation of a SerializedDictType.
    ///
    /// - Returns: The JSON representation of a SerializedDictType.
    public override func toJSON() throws -> Any {
        let parser = try BinaryParser(hex: toString())
        var accumulator = [String: Any]()
        while !parser.isEnd() {
            let field = try parser.readField()
            if field.fieldName == SerializedDictContants.OBJECT_END_MARKER {
                break
            }
            let jsonValue = try parser.readFieldValue(field).toJSON()
            accumulator[field.fieldName] = try SerializedDictHelpers.enumToString(field: field.fieldName, value: jsonValue)
        }
        return accumulator
    }
}
