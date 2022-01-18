import XCTest
@testable import xrpl_ios

class KeyPairTest: XCTestCase {
    
//    private static let dummyBytes = "\x01\x02\x03\x04\x05\x06\x07\x08\t\n\x0b\x0c\r\x0e\x0f\x10"
    
    func testGenerateSeed() throws {
        let output = try? KeyPairService.generateSeed()
        XCTAssertNotNil(output)
    }
    
    func testGenerateSeedWithEntropy() throws {
        let output = try KeyPairService.generateSeed(entropy: "vuongnm@devblock.net")
        XCTAssertEqual(output, "sEdTxr9QybWfY1AtwU23kXLXjPjGWLk")
    }
    
    func testGenerateKeyPairEd25519WithEntropy() throws {
        let seed = "sEdTxr9QybWfY1AtwU23kXLXjPjGWLk"
        let keypair = try KeyPairService.deriveKeypair(seed: seed)
        XCTAssertEqual(keypair.privateKey, "ED275591A631D429E9537A044081525CBF90EC0A746BCFDB55957A433F195FEEC9")
        XCTAssertEqual(keypair.publicKey, "ED7018ADA1056B4B4505AECCD3D26A3AFBC6D255706686B913D5CCB35FA85E1A25")
    }
    
    func testEd25519GenerateKeys() throws {
        let keypair = try KeyPairService.deriveKeypair(seed: "sEdSKaCy2JT7JaM7v95H9SxkhP9wS2r")
        XCTAssertEqual(keypair.publicKey, "ED01FA53FA5A7E77798F882ECE20B1ABC00BB358A9E55A202D0D0676BD0CE37A63")
        XCTAssertEqual(keypair.privateKey, "EDB4C4E046826BD26190D09715FC31F4E6A728204EADD112905B08B14B7F15C4F3")
    }
}
