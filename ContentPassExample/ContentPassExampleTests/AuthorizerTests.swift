import XCTest
@testable import ContentPass
import AppAuth

final class AuthorizerTests: XCTestCase {
    func testInitializationRunsConfigurationDiscoveryWithCorrectUrl() {
        let dummyClient = MockedOIDClient()

        _ = Convenience.createDummyAuthorizer(client: dummyClient)

        XCTAssert(dummyClient.didReturnConfiguration)
        XCTAssertEqual(dummyClient.discoveryUrl, MockedOIDClient.validDiscoveryUrl)
    }

    func testAuthorizeRunsConfigurationDiscoveryIfNeeded() {
        let dummyClient = MockedOIDClient()
        let authorizer = Convenience.createDummyAuthorizer(discoveryUrl: MockedOIDClient.flakyDiscoveryUrl, client: dummyClient)

        XCTAssert(!dummyClient.didReturnConfiguration)

        authorizer.authorize(presentingViewController: UIViewController()) { _ in }

        XCTAssertEqual(dummyClient.discoveryUrl, MockedOIDClient.validDiscoveryUrl)
        XCTAssert(dummyClient.didReturnConfiguration)
    }

    func testAuthorizeDoesNotRunDiscoveryIfConfigurationPresent() {
        let dummyClient = MockedOIDClient()
        let authorizer = Convenience.createDummyAuthorizer(client: dummyClient)
        let preAuthorize = dummyClient.calledCounter

        authorizer.authorize(presentingViewController: UIViewController(), completionHandler: { _ in })

        XCTAssertEqual(preAuthorize, dummyClient.calledCounter)
        XCTAssertEqual(dummyClient.calledCounter, 1)
    }

    func testAuthorizeBubblesUpDiscoveryError() {
        let dummyClient = MockedOIDClient()
        let authorizer = Convenience.createDummyAuthorizer(discoveryUrl: MockedOIDClient.errorDiscoveryUrl, client: dummyClient)

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
        let authorizer = Convenience.createDummyAuthorizer(clientId: MockedOIDClient.errorInAuthorizationClientId, client: dummyClient)

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
        let authorizer = Convenience.createDummyAuthorizer(clientId: MockedOIDClient.unexpectedClientId, client: dummyClient)

        let expectation = XCTestExpectation(description: "Wait for completionHandler")
        authorizer.authorize(presentingViewController: UIViewController()) { result in
            switch result {
            case .success:
                XCTFail("this should have resulted in an error")
            case .failure(ContentPassError.unexpectedState(.missingAuthStateAfterAuthorization)):
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
        XCTAssertEqual(dummyClient.authRequest?.additionalParameters, ["cp_route": "login", "prompt": "consent"])
    }

    func testValidateSubscriptionBubblesUpDiscoveyError() {
        let dummyClient = MockedOIDClient()
        let authorizer = Convenience.createDummyAuthorizer(discoveryUrl: MockedOIDClient.errorDiscoveryUrl, client: dummyClient)

        let expectation = XCTestExpectation(description: "Wait for completionHandler")
        authorizer.validateSubscription(idToken: "") { result in
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
        wait(for: [expectation], timeout: 1)
    }

    func testValidateSubscriptionBubblesUpUnderlyingError() {
        let dummyClient = MockedOIDClient()
        let authorizer = Convenience.createDummyAuthorizer(clientId: "underlying_error", client: dummyClient)

        let expectation = XCTestExpectation(description: "Wait for completionHandler")
        authorizer.validateSubscription(idToken: "") { result in
            switch result {
            case .success:
                XCTFail("this should have resulted in an error")
            case .failure(MockedOIDClient.ValidationTestError.underlyingError):
                break
            case .failure(let error):
                XCTFail("Unexpected error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testValidateSubscriptionRequestCreation() {
        let dummyClient = MockedOIDClient()
        let authorizer = Convenience.createDummyAuthorizer(clientId: "test_creation", client: dummyClient)

        let expectation = XCTestExpectation(description: "Wait for completionHandler")
        authorizer.validateSubscription(idToken: "expected_this_id_token") { result in
            switch result {
            case .success:
                break
            case .failure(MockedOIDClient.ValidationTestError.requestCreationFailure):
                XCTFail("URLRequest contains malformed POST body")
            case .failure(let error):
                XCTFail("Unexpected error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testValidateSubscriptionDataCorruptionError() {
        let dummyClient = MockedOIDClient()
        let authorizer = Convenience.createDummyAuthorizer(clientId: "data_corruption", client: dummyClient)

        let expectation = XCTestExpectation(description: "Wait for completionHandler")
        authorizer.validateSubscription(idToken: "") { result in
            switch result {
            case .success:
                XCTFail("this should have resulted in an error")
            case .failure(ContentPassError.subscriptionDataCorrupted):
                break
            case .failure(let error):
                XCTFail("Unexpected error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
}
