import XCTest
@testable import ContentPass
import AppAuth

final class AuthorizerTests: XCTestCase {
    func testInitializationRunsConfigurationDiscoveryWithCorrectUrl() {
        let dummyClient = MockedOIDClient()
        _ = Authorizer(
            clientId: "",
            clientSecret: nil,
            clientRedirectUri: URL(string: "dummy.url")!,
            discoveryUrl: MockedOIDClient.validDiscoveryUrl,
            client: dummyClient
        )
        XCTAssert(dummyClient.didReturnConfiguration)
        XCTAssertEqual(dummyClient.discoveryUrl, MockedOIDClient.validDiscoveryUrl)
    }
    
    func testAuthorizeRunsConfigurationDiscoveryIfNeeded() {
        let dummyClient = MockedOIDClient()
        let authorizer = Authorizer(
            clientId: "",
            clientSecret: nil,
            clientRedirectUri: URL(string: "dummy.url")!,
            discoveryUrl: MockedOIDClient.flakyDiscoveryUrl,
            client: dummyClient
        )
        XCTAssert(!dummyClient.didReturnConfiguration)
        authorizer.authorize(presentingViewController: UIViewController()) { _ in }
        XCTAssertEqual(dummyClient.discoveryUrl, MockedOIDClient.validDiscoveryUrl)
        XCTAssert(dummyClient.didReturnConfiguration)
    }
    
    func testAuthorizeDoesNotRunDiscoveryIfConfigurationPresent() {
        let dummyClient = MockedOIDClient()
        let authorizer = Authorizer(
            clientId: "",
            clientSecret: nil,
            clientRedirectUri: URL(string: "dummy.url")!,
            discoveryUrl: MockedOIDClient.validDiscoveryUrl,
            client: dummyClient
        )
        let preAuthorize = dummyClient.calledCounter
        authorizer.authorize(presentingViewController: UIViewController(), completionHandler: { _ in })
        XCTAssertEqual(preAuthorize, dummyClient.calledCounter)
        XCTAssertEqual(dummyClient.calledCounter, 1)
    }
    
    func testAuthorizeBubblesUpDiscoveryError() {
        let dummyClient = MockedOIDClient()
        let authorizer = Authorizer(
            clientId: "",
            clientSecret: nil,
            clientRedirectUri: URL(string: "dummy.url")!,
            discoveryUrl: MockedOIDClient.errorDiscoveryUrl,
            client: dummyClient
        )
        let expectation = XCTestExpectation(description: "Wait for completionHandler")
        authorizer.authorize(presentingViewController: UIViewController()) { result in
            switch result {
            case .success:
                XCTFail("this should have resulted in an error")
            case .failure(MockedOIDClient.ClientError.discoveryError):
                break
            default:
                XCTFail("bubbled up the wrong error")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testAuthorizeBubblesUpUnderlyingError() {
        let dummyClient = MockedOIDClient()
        let authorizer = Authorizer(
            clientId: MockedOIDClient.errorInAuthorizationClientId,
            clientSecret: nil,
            clientRedirectUri: URL(string: "dummy.url")!,
            discoveryUrl: MockedOIDClient.validDiscoveryUrl,
            client: dummyClient
        )
        let expectation = XCTestExpectation(description: "Wait for completionHandler")
        authorizer.authorize(presentingViewController: UIViewController()) { result in
            switch result {
            case .success:
                XCTFail("this should have resulted in an error")
            case .failure(MockedOIDClient.ClientError.authError):
                break
            default:
                XCTFail("bubbled up the wrong error")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testAuthorizeReturnsUnexpectedStateCorrectly() {
        let dummyClient = MockedOIDClient()
        let authorizer = Authorizer(
            clientId: MockedOIDClient.unexpectedClientId,
            clientSecret: nil,
            clientRedirectUri: URL(string: "dummy.url")!,
            discoveryUrl: MockedOIDClient.validDiscoveryUrl,
            client: dummyClient
        )
        let expectation = XCTestExpectation(description: "Wait for completionHandler")
        authorizer.authorize(presentingViewController: UIViewController()) { result in
            switch result {
            case .success:
                XCTFail("this should have resulted in an error")
            case .failure(ContentPassError.unexpectedState(.missingAuthorizationStateAfterAuthorization)):
                break
            default:
                XCTFail("bubbled up the wrong error")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testAuthorizeGeneratesCorrectAuthorizationRequest() {
        let dummyClient = MockedOIDClient()
        let clientId = UUID().uuidString
        let clientSecret = UUID().uuidString
        let redirectUri = URL(string: "this.url.is.correct")!
        
        let authorizer = Authorizer(
            clientId: clientId,
            clientSecret: clientSecret,
            clientRedirectUri: redirectUri,
            discoveryUrl: MockedOIDClient.validDiscoveryUrl,
            client: dummyClient
        )
        authorizer.authorize(presentingViewController: UIViewController()) { _ in }
        XCTAssertEqual(dummyClient.authRequest?.clientID, clientId)
        XCTAssertEqual(dummyClient.authRequest?.clientSecret, clientSecret)
        XCTAssertEqual(dummyClient.authRequest?.redirectURL, redirectUri)
        XCTAssertEqual(dummyClient.authRequest?.scope, "openid offline_access contentpass")
        XCTAssertEqual(dummyClient.authRequest?.responseType, OIDResponseTypeCode)
    }
}
