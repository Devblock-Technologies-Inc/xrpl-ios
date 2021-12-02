import XCTest
@testable import xrpl_ios

// swiftlint:disable all
class Base58Tests: XCTestCase {

    func testEncodeDecodeString() throws {
        let decoded: [UInt8] = "Hello World".bytes
        let encoded: String = "JxErpTiA7PhnBMd"
        
        XCTAssertEqual(Base58.encode(decoded, alphabet: XRPL_ALPHABET), encoded)
        XCTAssertEqual(Base58.decode(encoded, alphabet: XRPL_ALPHABET), decoded)
    }
    
    func testEncodeChecked() throws {
        let input: [UInt8] = [6, 161, 159, 136, 34, 110, 33, 238, 14, 79, 14, 218, 133, 13, 109, 40, 194, 236, 153, 44, 61, 157, 254]
        let encoded = Base58.encodeCheck(input, alphabet: XRPL_ALPHABET)
        XCTAssertEqual(encoded, "tzrYsqqTg9HdizZGbNj5UPmAuZfCWVxFPtRA")
    }
    
    func testDecodeChecked() throws {
        let input = "tzrYsqqTg9HdizZGbNj5UPmAuZfCWVxFPtRA"
        let expectedOutputData: [UInt8] = [6, 161, 159, 136, 34, 110, 33, 238, 14, 79, 14, 218, 133, 13, 109, 40, 194, 236, 153, 44, 61, 157, 254]
        
        let actualOutput = try Base58.decodeCheck(input, alphabet: XRPL_ALPHABET)
        XCTAssertEqual(actualOutput, expectedOutputData)
    }

}
// swiftlint:enable all
