import XCTest
@testable import xrpl_ios

class CodecTests: XCTestCase {
    
    private let codec = Codec()

    func testClassicAddresEncodeDecode() throws {
        let hexString = "BA8E78626EE42C41B46D46C3048DF3A1C3C87072"
        let encodedString = "rJrRMgiRgrU6hDF4pgu5DXQdWyPbY35ErN"
        
        let encodeResult = try codec.encodeClassicAddress(hexString.bytesFromHexString)
        
        XCTAssertEqual(encodeResult, encodedString)
        
        let decodedResult = try codec.decodeClassicAddress(encodedString)
        
        XCTAssertEqual(decodedResult, hexString.bytesFromHexString)
    }
}
