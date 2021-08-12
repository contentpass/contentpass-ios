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

    func testContentPassTokenInitialization() {
        let testToken = "eyJhbGciOiJSUzI1NiJ9.eyJhdXRoIjp0cnVlLCJwbGFucyI6WyJjYTQ5MmFmNy0zMjBjLTQyYzktOWJhMC1iMmEzM2NmY2EzMDciXSwiYXVkIjoiNjliMjg5ODUiLCJpYXQiOjE2Mjg3NjYyOTIsImV4cCI6MTYyODk0MjY5Mn0"

        let decodedToken = Authorizer.ContentPassToken(tokenString: testToken)
        XCTAssertNotNil(decodedToken)
        XCTAssertEqual(decodedToken?.header.alg, "RS256")
        XCTAssertEqual(decodedToken?.body.plans, ["ca492af7-320c-42c9-9ba0-b2a33cfca307"])
        XCTAssertEqual(decodedToken?.body.aud, "69b28985")
        XCTAssertEqual(decodedToken?.body.auth, true)
        XCTAssertEqual(decodedToken?.body.iat, Date(timeIntervalSince1970: 1628766292))
        XCTAssertEqual(decodedToken?.body.exp, Date(timeIntervalSince1970: 1628942692))
    }

    func testValidateSubscriptionBubblesUpDiscoveyError() {
        let dummyClient = MockedOIDClient()
        let authorizer = Authorizer(
            clientId: "",
            clientSecret: nil,
            clientRedirectUri: URL(string: "dummy.url")!,
            discoveryUrl: MockedOIDClient.errorDiscoveryUrl,
            client: dummyClient
        )
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
        wait(for: [expectation], timeout: 10.0)
    }

    func testValidateSubscriptionBubblesUpUnderlyingError() {
        let dummyClient = MockedOIDClient()
        let authorizer = Authorizer(
            clientId: "underlying_error",
            clientSecret: nil,
            clientRedirectUri: URL(string: "dummy.url")!,
            discoveryUrl: MockedOIDClient.validDiscoveryUrl,
            client: dummyClient
        )
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
        wait(for: [expectation], timeout: 10.0)
    }

    func testValidateSubscriptionRequestCreation() {
        let dummyClient = MockedOIDClient()
        let authorizer = Authorizer(
            clientId: "test_creation",
            clientSecret: nil,
            clientRedirectUri: URL(string: "dummy.url")!,
            discoveryUrl: MockedOIDClient.validDiscoveryUrl,
            client: dummyClient
        )
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
        wait(for: [expectation], timeout: 10.0)
    }

    func testValidateSubscriptionDataCorruptionError() {
        let dummyClient = MockedOIDClient()
        let authorizer = Authorizer(
            clientId: "data_corruption",
            clientSecret: nil,
            clientRedirectUri: URL(string: "dummy.url")!,
            discoveryUrl: MockedOIDClient.validDiscoveryUrl,
            client: dummyClient
        )
        let expectation = XCTestExpectation(description: "Wait for completionHandler")
        authorizer.validateSubscription(idToken: "expected_this_id_token") { result in
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
        wait(for: [expectation], timeout: 10.0)
    }
}
