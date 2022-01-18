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
    
    func testSeedEncodeDecodeEd25519() throws {
        let hexString = "4C3A1D213FBDFB14C7C28D609469B341"
        let encodedString = "sEdTM1uX8pu2do5XvTnutH6HsouMaM2"
        let hexStringBytes = Array<UInt8>.init(hex: hexString)
        
        let encodeResult = try codec.encodeSeed(hexStringBytes, encodingType: .ED25519)
        XCTAssertEqual(encodeResult, encodedString)
        
        let (decodeResult, encodingType) = try codec.decodeSeed(encodedString)
        XCTAssertEqual(decodeResult, hexStringBytes)
        XCTAssertEqual(encodingType, CryptoAlgorithm.ED25519)
    }
    
    func testSeedEncodeDecodeEd25519Low() throws {
        let hexString = "00000000000000000000000000000000"
        let encodedString = "sEdSJHS4oiAdz7w2X2ni1gFiqtbJHqE"
        let hexStringBytes = Array<UInt8>.init(hex: hexString)
        
        let encodeResult = try codec.encodeSeed(hexStringBytes, encodingType: .ED25519)
        XCTAssertEqual(encodeResult, encodedString)
        
        let (decodeResult, encodingType) = try codec.decodeSeed(encodedString)
        XCTAssertEqual(decodeResult, hexStringBytes)
        XCTAssertEqual(encodingType, CryptoAlgorithm.ED25519)
    }
    
    func testSeedEncodeDecodeEd25519High() throws {
        let hexString = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        let encodedString = "sEdV19BLfeQeKdEXyYA4NhjPJe6XBfG"
        let hexStringBytes = Array<UInt8>.init(hex: hexString)
        
        let encodeResult = try codec.encodeSeed(hexStringBytes, encodingType: .ED25519)
        XCTAssertEqual(encodeResult, encodedString)
        
        let (decodeResult, encodingType) = try codec.decodeSeed(encodedString)
        XCTAssertEqual(decodeResult, hexStringBytes)
        XCTAssertEqual(encodingType, CryptoAlgorithm.ED25519)
    }
}
