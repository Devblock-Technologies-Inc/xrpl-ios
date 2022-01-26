import XCTest
@testable import xrpl_ios

class WalletGenerationTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testGenerateRandomWallet() throws {
        let newWallet = try Wallet.create()
        let xAddress = try newWallet.getXAddress(isTest: true)
        
        XCTAssertNoThrow(newWallet)
        XCTAssertNoThrow(xAddress)
        
        print(newWallet)
        print(xAddress)
        
        let message = "test message"
        let signature = try KeyPairService.sign(message: message.bytes, privateKey: newWallet.privateKey)
        let validMessage = try KeyPairService.isValidMessage(message: message.bytes, signature: Array<UInt8>.init(hex: signature), publicKey: newWallet.publicKey)
        
        XCTAssertTrue(validMessage)
    }
    
    func testCreateWalletWithSeed() throws {
        let dummyArrayBytes: [UInt8] = Array<UInt8>(1...16)
        let entropy = String(data: Data(dummyArrayBytes), encoding: .utf8)
        let exceptedSeedValue = "sEdSKaCy2JT7JaM7v95H9SxkhP9wS2r"
        
        let generatedSeed = try KeyPairService.generateSeed(entropy: entropy, algorithm: .ED25519)
        
        // Test generateSeed
        XCTAssertEqual(generatedSeed, exceptedSeedValue)
        
        let wallet = try Wallet(seed: generatedSeed, sequence: 0)
        
        // Test key pair
        XCTAssertEqual(wallet.publicKey, "ED01FA53FA5A7E77798F882ECE20B1ABC00BB358A9E55A202D0D0676BD0CE37A63")
        XCTAssertEqual(wallet.privateKey, "EDB4C4E046826BD26190D09715FC31F4E6A728204EADD112905B08B14B7F15C4F3")
        
        let exceptedClassicAddress = "rLUEXYuLiQptky37CqLcm9USQpPiz5rkpD"
        
        // Test classicAddress
        XCTAssertEqual(wallet.classicAddress, exceptedClassicAddress)
        
        // Use https://xrpaddress.info create a new address format given wallet.classicAddress and tag is 12345
        let exceptedXAddress = "XVYaPuwjbmRPA9pdyiXAGXsw8NhgJqMMMbqXC6WH86Vm8p3"
        let exceptedXAddressTestnet = "TVTcFrK5T5yR4eoEECG5wWonECb7FRrPJm8yy4jFPN8GkcL"
        let generatedXAddressMainnet = try wallet.getXAddress(tag: 12345, isTest: false)
        let generatedXAddressTestnet = try wallet.getXAddress(tag: 12345, isTest: true)
        
        // Test x-address
        XCTAssertEqual(exceptedXAddress, generatedXAddressMainnet)
        XCTAssertEqual(exceptedXAddressTestnet, generatedXAddressTestnet)
        
        let message = "test message"
        let exceptedSignature = "CB199E1BFD4E3DAA105E4832EEDFA36413E1F44205E4EFB9E27E826044C21E3E2E848BBC8195E8959BADF887599B7310AD1B7047EF11B682E0D068F73749750E"
        let signature = try KeyPairService.sign(message: message.bytes, privateKey: wallet.privateKey)
        
        // Test encode String UTF-8
        XCTAssertEqual(message.bytes, [116, 101, 115, 116, 32, 109, 101, 115, 115, 97, 103, 101])
        
        let validMessage = try KeyPairService.isValidMessage(message: message.bytes, signature: Array<UInt8>.init(hex: exceptedSignature), publicKey: wallet.publicKey)
        let validMessageRandomSignature = try KeyPairService.isValidMessage(message: message.bytes, signature: Array<UInt8>.init(hex: signature), publicKey: wallet.publicKey)
        
        // Test signature
        XCTAssertTrue(validMessage)
        XCTAssertTrue(validMessageRandomSignature)
    }

}
