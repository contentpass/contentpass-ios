import XCTest
@testable import ContentPass

class ContentPassTests: XCTestCase {
    var delegatedState: ContentPass.State?
    let keychain = KeychainStore(clientId: "")
    let configuration = Configuration(
        baseUrl: URL(string: "https://contentpass.de")!,
        redirectUrl: URL(string: "de.contentpass://oauth")!,
        propertyId: UUID().uuidString
    )

    override func setUp() {
        keychain.deleteAuthState()
    }

    func testAuthorizerGetsSetUpProperly() {
        let contentPass = ContentPass(configuration: configuration, keychain: keychain)

        XCTAssertEqual(contentPass.authorizer.clientId, configuration.propertyId)
        XCTAssertEqual(contentPass.authorizer.clientRedirectUri, URL(string: "de.contentpass://oauth")!)
        XCTAssertEqual(contentPass.authorizer.discoveryUrl, URL(string: "https://contentpass.de")!)
    }

    func testKeyChainAuthStateRetrievalWorks() {
        let authState = MockedAuthState.createRandom()
        keychain.storeAuthState(authState)
        let contentPass = ContentPass(configuration: configuration, keychain: keychain)

        XCTAssertEqual(authState, contentPass.oidAuthState as! MockedAuthState)
    }

    func testSetUnauthorizedWhenNoAuthStateOnInit() {
        let contentPass = ContentPass(configuration: configuration, keychain: keychain)

        XCTAssertEqual(contentPass.state, .unauthenticated)
    }

    func testConvenienceInitializerSetsCorrectClientId() {
        let contentPass = ContentPass()

        XCTAssertEqual(contentPass.authorizer.clientId, "85ff2a2a-54f7-4da1-97af-9752572396ab")
    }

    func testAuthStateValidationDoesTokenRefreshWhenNeeded() {
        let authState = MockedAuthState.createRandom()
        authState.accessTokenExpirationDate = Date(timeIntervalSinceNow: -1)
        keychain.storeAuthState(authState)

        let contentPass = ContentPass(configuration: configuration, keychain: keychain)

        XCTAssert((contentPass.oidAuthState as? MockedAuthState)?.wasTokenRefreshPerformed ?? false)
    }

    func testRecoverFromErrorValidatesAuthState() {
        let authState = MockedAuthState.createRandom()
        authState.hasInternetConnection = false
        authState.accessTokenExpirationDate = Date(timeIntervalSinceNow: -1)
        keychain.storeAuthState(authState)

        let contentPass = ContentPass(configuration: configuration, keychain: keychain)

        XCTAssertFalse((contentPass.oidAuthState as? MockedAuthState)?.wasTokenRefreshPerformed ?? false)

        (contentPass.oidAuthState as? MockedAuthState)?.hasInternetConnection = true
        contentPass.recoverFromError()

        XCTAssert((contentPass.oidAuthState as? MockedAuthState)?.wasTokenRefreshPerformed ?? false)
    }

    func testAuthStateValidationSetsTokenRefreshTimer() {
        let authState = MockedAuthState.createRandom()
        authState.accessTokenExpirationDate = Date(timeIntervalSinceNow: 5)
        keychain.storeAuthState(authState)

        let contentPass = ContentPass(configuration: configuration, keychain: keychain)

        XCTAssertNotNil(contentPass.refreshTimer)

        guard let timer = contentPass.refreshTimer else {
            XCTFail("can't be nil, was just checked")
            return
        }

        XCTAssert(timer.isValid)
        let timerInterval = timer.fireDate.timeIntervalSinceNow
        let timerIsWithinRange = timerInterval < 5 && timerInterval >= 4
        XCTAssert(timerIsWithinRange)
    }

    func testRefreshTimerInvokesTokenRefresh() {
        let authState = MockedAuthState.createRandom()
        authState.accessTokenExpirationDate = Date(timeIntervalSinceNow: 0.5)
        keychain.storeAuthState(authState)

        let contentPass = ContentPass(configuration: configuration, keychain: keychain)

        let expectation = XCTestExpectation(description: "Wait for timer to fire")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.5)

        XCTAssert((contentPass.oidAuthState as? MockedAuthState)?.wasTokenRefreshPerformed ?? false)
    }

    func testTokenRefreshCorrectlySetsUnauthorizedWhenTokenGotLostBeforehand() {
        let authState = MockedAuthState.createRandom()
        authState.accessTokenExpirationDate = Date(timeIntervalSinceNow: 0.5)
        keychain.storeAuthState(authState)
        let authorizer = Convenience.createDummyAuthorizer()
        let contentPass = ContentPass(configuration: configuration, keychain: keychain, authorizer: authorizer)

        XCTAssertEqual(contentPass.state, .authenticated(email: nil, hasValidSubscription: true))

        contentPass.oidAuthState = nil

        wait(for: [], timeout: 1)

        XCTAssertEqual(contentPass.state, .unauthenticated)
    }

    func testAuthorizeSetsAuthStateCorrectly() {
        let dummyClient = MockedOIDClient()
        let authState = MockedAuthState.createRandom()
        dummyClient.shouldReturnAuthState = authState
        let authorizer = Convenience.createDummyAuthorizer(client: dummyClient)

        let contentPass = ContentPass(configuration: configuration, keychain: keychain, authorizer: authorizer)

        XCTAssertNil(contentPass.oidAuthState)

        contentPass.authenticate(presentingViewController: UIViewController(), completionHandler: { _ in })

        XCTAssertEqual(contentPass.oidAuthState as! MockedAuthState, authState)
    }

    func testAuthorizeReturnsSuccessOnSuccess() {
        let dummyClient = MockedOIDClient()
        let authState = MockedAuthState.createRandom()
        dummyClient.shouldReturnAuthState = authState
        let authorizer = Convenience.createDummyAuthorizer(client: dummyClient)
        let contentPass = ContentPass(configuration: configuration, keychain: keychain, authorizer: authorizer)

        let expectation = XCTestExpectation(description: "Wait for authorization")
        contentPass.authenticate(presentingViewController: UIViewController()) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail("Should be a success")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }

    func testAuthorizeBubblesUpUnderlyingErrors() {
        let dummyClient = MockedOIDClient()
        let authState = MockedAuthState.createRandom()
        dummyClient.shouldReturnAuthState = authState
        let authorizer = Convenience.createDummyAuthorizer(discoveryUrl: MockedOIDClient.errorDiscoveryUrl, client: dummyClient)
        let contentPass = ContentPass(configuration: configuration, keychain: keychain, authorizer: authorizer)

        let expectation = XCTestExpectation(description: "Wait for authorization")
        contentPass.authenticate(presentingViewController: UIViewController()) { result in
            switch result {
            case .success:
                XCTFail("Should be an error")
            case .failure(MockedOIDClient.ClientError.discoveryError):
                break
            case .failure(let error):
                XCTFail("Should be a specific error, not: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }

    func testStateGetsPassedToDelegate() {
        let contentPass = ContentPass()
        contentPass.delegate = self

        XCTAssertNil(delegatedState)

        contentPass.state = .authenticated(email: nil, hasValidSubscription: true)

        XCTAssertEqual(delegatedState, .authenticated(email: nil, hasValidSubscription: true))
    }

    func testAuthStateChangeToUnauthorizedResultsInCorrectStateBubbling() {
        let contentPass = ContentPass()
        contentPass.delegate = self
        let authState = MockedAuthState.createRandom()
        authState.isAuthorized = false
        contentPass.state = .authenticated(email: nil, hasValidSubscription: true)

        XCTAssertEqual(delegatedState, .authenticated(email: nil, hasValidSubscription: true))

        contentPass.didChange(authState)

        XCTAssertEqual(delegatedState, .unauthenticated)
    }

    func testAuthStateChangeToUnauthorizedResultsInKeychainDeletion() {
        let authState = MockedAuthState.createRandom()
        authState.accessTokenExpirationDate = Date(timeIntervalSinceNow: 5)
        keychain.storeAuthState(authState)
        let contentPass = ContentPass(configuration: configuration, keychain: keychain)

        XCTAssertNotNil(keychain.retrieveAuthState())

        authState.isAuthorized = false
        contentPass.oidAuthState = authState

        XCTAssertNil(keychain.retrieveAuthState())
    }

    func testAuthStateChangeToAuthorizedResultsInCorrectStateBubbling() {
        let authorizer = Convenience.createDummyAuthorizer()
        let contentPass = ContentPass(configuration: configuration, keychain: keychain, authorizer: authorizer)
        contentPass.delegate = self
        contentPass.state = .unauthenticated

        XCTAssertEqual(delegatedState, .unauthenticated)

        let authState = MockedAuthState.createRandom()
        contentPass.oidAuthState = authState

        XCTAssertEqual(delegatedState, .authenticated(email: nil, hasValidSubscription: true))
    }

    func testAuthStateChangeToAuthorizedStoresAuthState() {
        let authState = MockedAuthState.createRandom()
        authState.accessTokenExpirationDate = Date(timeIntervalSinceNow: 5)
        let contentPass = ContentPass(configuration: configuration, keychain: keychain)

        XCTAssertNil(keychain.retrieveAuthState())

        contentPass.didChange(authState)

        XCTAssertEqual(keychain.retrieveAuthState() as! MockedAuthState, authState)
    }

    func testAuthStateChangeToAuthorizedCorrectlySetsUpTokenRefresh() {
        let authState = MockedAuthState.createRandom()
        authState.accessTokenExpirationDate = Date(timeIntervalSinceNow: 5)
        let contentPass = ContentPass()

        contentPass.oidAuthState = authState

        XCTAssertNotNil(contentPass.refreshTimer)
        guard let timer = contentPass.refreshTimer else {
            XCTFail("can't be nil, was just checked")
            return
        }
        XCTAssert(timer.isValid)
        let timerInterval = timer.fireDate.timeIntervalSinceNow
        let timerIsWithinRange = timerInterval < 5 && timerInterval >= 4
        assert(timerIsWithinRange)
    }

    func testAuthStateWithoutTokenTimeoutDoesNotSetRefreshTimer() {
        let authState = MockedAuthState.createRandom()
        authState.accessTokenExpirationDate = nil
        let contentPass = ContentPass()

        contentPass.oidAuthState = authState

        XCTAssertNil(contentPass.refreshTimer)
    }

    func testAuthStateErrorBubblesUpCorrectly() {
        let authState = MockedAuthState.createRandom()
        let contentPass = ContentPass()
        contentPass.delegate = self

        contentPass.authState(authState, didEncounterAuthorizationError: ContentPassError.subscriptionDataCorrupted)

        XCTAssertEqual(delegatedState, .error(ContentPassError.subscriptionDataCorrupted))
    }

    func testAuthStateErrorRemovesTokenFromKeychain() {
        let authState = MockedAuthState.createRandom()
        keychain.storeAuthState(authState)
        let contentPass = ContentPass(configuration: configuration, keychain: keychain)

        XCTAssertEqual(authState, keychain.retrieveAuthState() as! MockedAuthState)

        contentPass.authState(authState, didEncounterAuthorizationError: ContentPassError.subscriptionDataCorrupted)

        XCTAssertNil(keychain.retrieveAuthState())
    }

    func testLogout() {
        let authState = MockedAuthState.createRandom()
        let authorizer = Convenience.createDummyAuthorizer()
        keychain.storeAuthState(authState)
        let contentPass = ContentPass(configuration: configuration, keychain: keychain, authorizer: authorizer)
        contentPass.delegate = self

        XCTAssertEqual(contentPass.state, .authenticated(email: nil, hasValidSubscription: true))

        contentPass.logout()
        XCTAssertEqual(delegatedState, .unauthenticated)
        XCTAssertNil(keychain.retrieveAuthState())
    }
}

extension ContentPassTests: ContentPassDelegate {
    func onStateChanged(contentPass: ContentPass, newState: ContentPass.State) {
        delegatedState = newState
    }
}
