import XCTest
@testable import xrpl_ios

class FieldIdCodecTests: XCTestCase {
    
    func testEncode() throws {
        let encodedHex = try FieldIdCodec.shared.encode(fieldName: "FirstLedgerSequence").toHexString().uppercased()
        XCTAssertEqual(encodedHex, "201A")
    }
    
    func testDecode() throws {
        let decoded = try FieldIdCodec.shared.decode(fieldId: "201A")
        XCTAssertEqual(decoded, "FirstLedgerSequence")
    }
}
