import XCTest
@testable import ContentPass

class ContentPassTests: XCTestCase {
    var delegatedState: ContentPass.State?
    
    func testAuthorizerGetsSetUpProperly() {
        let clientId = UUID().uuidString
        let keychain = KeychainStore(clientId: clientId)
        let contentPass = ContentPass(clientId: clientId, keychain: keychain)
        XCTAssertEqual(contentPass.authorizer.clientId, clientId)
        XCTAssertEqual(contentPass.authorizer.clientSecret, "ahc0oongie6iigaex7ciengie0quaiphuoQueeZa")
        XCTAssertEqual(contentPass.authorizer.clientRedirectUri, URL(string: "de.t-online.pur://oauth")!)
        XCTAssertEqual(contentPass.authorizer.discoveryUrl, URL(string: "https://pur.t-online.de")!)
    }
    
    func testKeyChainAuthStateRetrievalWorks() {
        let clientId = UUID().uuidString
        let keychain = KeychainStore(clientId: clientId)
        let authState = MockedAuthState.createRandom()
        keychain.storeAuthState(authState)
        let contentPass = ContentPass(clientId: clientId, keychain: keychain)
        
        XCTAssertEqual(authState, contentPass.oidAuthState as! MockedAuthState)
    }
    
    func testSetUnauthorizedWhenNoAuthStateOnInit() {
        let clientId = UUID().uuidString
        let keychain = KeychainStore(clientId: clientId)
        let contentPass = ContentPass(clientId: clientId, keychain: keychain)
        
        XCTAssertEqual(contentPass.state, .unauthorized)
    }
    
    func testConvenienceInitializerSetsCorrectClientId() {
        let clientId = UUID().uuidString
        let contentPass = ContentPass(clientId: clientId)
        XCTAssertEqual(contentPass.authorizer.clientId, clientId)
    }
    
    func testAuthStateValidationDoesTokenRefreshWhenNeeded() {
        let clientId = UUID().uuidString
        let keychain = KeychainStore(clientId: clientId)
        let authState = MockedAuthState.createRandom()
        authState.accessTokenExpirationDate = Date(timeIntervalSinceNow: -1)
        keychain.storeAuthState(authState)
        let contentPass = ContentPass(clientId: clientId, keychain: keychain)
        XCTAssert((contentPass.oidAuthState as? MockedAuthState)?.wasTokenRefreshPerformed ?? false)
    }
    
    func testAuthStateValidationSetsTokenRefreshTimer() {
        let clientId = UUID().uuidString
        let keychain = KeychainStore(clientId: clientId)
        let authState = MockedAuthState.createRandom()
        authState.accessTokenExpirationDate = Date(timeIntervalSinceNow: 5)
        keychain.storeAuthState(authState)
        let contentPass = ContentPass(clientId: clientId, keychain: keychain)
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
    
    func testRefreshTimerInvokesTokenRefresh() {
        let clientId = UUID().uuidString
        let keychain = KeychainStore(clientId: clientId)
        let authState = MockedAuthState.createRandom()
        authState.accessTokenExpirationDate = Date(timeIntervalSinceNow: 0.5)
        keychain.storeAuthState(authState)
        let contentPass = ContentPass(clientId: clientId, keychain: keychain)

        let expectation = XCTestExpectation(description: "Wait for timer to fire")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.5)
        XCTAssert((contentPass.oidAuthState as? MockedAuthState)?.wasTokenRefreshPerformed ?? false)
    }
    
    func testTokenRefreshCorrectlySetsUnauthorizedWhenTokenGotLostBeforehand() {
        let clientId = UUID().uuidString
        let keychain = KeychainStore(clientId: clientId)
        let authState = MockedAuthState.createRandom()
        authState.accessTokenExpirationDate = Date(timeIntervalSinceNow: 1)
        keychain.storeAuthState(authState)
        let contentPass = ContentPass(clientId: clientId, keychain: keychain)
        
        XCTAssertEqual(contentPass.state, .authorized)
        contentPass.oidAuthState = nil
        let expectation = XCTestExpectation(description: "Wait for timer to fire")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.5)
        XCTAssertEqual(contentPass.state, .unauthorized)
    }
    
    func testAuthorizeSetsAuthStateCorrectly() {
        let clientId = UUID().uuidString
        let keychain = KeychainStore(clientId: clientId)
        let dummyClient = MockedOIDClient()
        let authState = MockedAuthState.createRandom()
        dummyClient.shouldReturnAuthState = authState
        let authorizer = Authorizer(
            clientId: "",
            clientSecret: nil,
            clientRedirectUri: URL(string: "dummy.url")!,
            discoveryUrl: MockedOIDClient.validDiscoveryUrl,
            client: dummyClient
        )
        let contentPass = ContentPass(clientId: clientId, keychain: keychain, authorizer: authorizer)
        XCTAssertNil(contentPass.oidAuthState)
        contentPass.authorize(presentingViewController: UIViewController(), completionHandler: { _ in })
        XCTAssertEqual(contentPass.oidAuthState as! MockedAuthState, authState)
    }
    
    func testAuthorizeReturnsSuccessOnSuccess() {
        let clientId = UUID().uuidString
        let keychain = KeychainStore(clientId: clientId)
        let dummyClient = MockedOIDClient()
        let authState = MockedAuthState.createRandom()
        dummyClient.shouldReturnAuthState = authState
        let authorizer = Authorizer(
            clientId: "",
            clientSecret: nil,
            clientRedirectUri: URL(string: "dummy.url")!,
            discoveryUrl: MockedOIDClient.validDiscoveryUrl,
            client: dummyClient
        )
        let contentPass = ContentPass(clientId: clientId, keychain: keychain, authorizer: authorizer)
        let expectation = XCTestExpectation(description: "Wait for authorization")
        contentPass.authorize(presentingViewController: UIViewController()) { result in
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
        let clientId = UUID().uuidString
        let keychain = KeychainStore(clientId: clientId)
        let dummyClient = MockedOIDClient()
        let authState = MockedAuthState.createRandom()
        dummyClient.shouldReturnAuthState = authState
        let authorizer = Authorizer(
            clientId: "",
            clientSecret: nil,
            clientRedirectUri: URL(string: "dummy.url")!,
            discoveryUrl: MockedOIDClient.errorDiscoveryUrl,
            client: dummyClient
        )
        let contentPass = ContentPass(clientId: clientId, keychain: keychain, authorizer: authorizer)
        let expectation = XCTestExpectation(description: "Wait for authorization")
        contentPass.authorize(presentingViewController: UIViewController()) { result in
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
        let clientId = UUID().uuidString
        let contentPass = ContentPass(clientId: clientId)
        contentPass.delegate = self
        XCTAssertNil(delegatedState)
        contentPass.state = .authorized
        XCTAssertEqual(delegatedState, .authorized)
    }
    
    func testAuthStateChangeToUnauthorizedResultsInCorrectStateBubbling() {
        let clientId = UUID().uuidString
        let contentPass = ContentPass(clientId: clientId)
        contentPass.delegate = self
        let authState = MockedAuthState.createRandom()
        authState.isAuthorized = false
        contentPass.state = .authorized
        XCTAssertEqual(delegatedState, .authorized)
        contentPass.didChange(wrappedState: authState)
        XCTAssertEqual(delegatedState, .unauthorized)
    }
    
    func testAuthStateChangeToUnauthorizedResultsInKeychainDeletion() {
        let clientId = UUID().uuidString
        let keychain = KeychainStore(clientId: clientId)
        let authState = MockedAuthState.createRandom()
        authState.accessTokenExpirationDate = Date(timeIntervalSinceNow: 5)
        keychain.storeAuthState(authState)
        let contentPass = ContentPass(clientId: clientId, keychain: keychain)
        XCTAssertNotNil(keychain.retrieveAuthState())
        authState.isAuthorized = false
        contentPass.didChange(wrappedState: authState)
        XCTAssertNil(keychain.retrieveAuthState())
    }
    
    func testAuthStateChangeToAuthorizedResultsInCorrectStateBubbling() {
        let clientId = UUID().uuidString
        let contentPass = ContentPass(clientId: clientId)
        contentPass.delegate = self
        let authState = MockedAuthState.createRandom()
        contentPass.state = .unauthorized
        XCTAssertEqual(delegatedState, .unauthorized)
        contentPass.didChange(wrappedState: authState)
        XCTAssertEqual(delegatedState, .authorized)
    }
    
    func testAuthStateChangeToAuthorizedStoresAuthState() {
        let clientId = UUID().uuidString
        let keychain = KeychainStore(clientId: clientId)
        let authState = MockedAuthState.createRandom()
        authState.accessTokenExpirationDate = Date(timeIntervalSinceNow: 5)
        let contentPass = ContentPass(clientId: clientId, keychain: keychain)
        XCTAssertNil(keychain.retrieveAuthState())
        contentPass.didChange(wrappedState: authState)
        XCTAssertEqual(keychain.retrieveAuthState() as! MockedAuthState, authState)
    }
    
    func testAuthStateChangeToAuthorizedCorrectlySetsUpTokenRefresh() {
        let clientId = UUID().uuidString
        let authState = MockedAuthState.createRandom()
        authState.accessTokenExpirationDate = Date(timeIntervalSinceNow: 5)
        let contentPass = ContentPass(clientId: clientId)
        contentPass.didChange(wrappedState: authState)
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
        let clientId = UUID().uuidString
        let authState = MockedAuthState.createRandom()
        authState.accessTokenExpirationDate = nil
        let contentPass = ContentPass(clientId: clientId)
        contentPass.didChange(wrappedState: authState)
        XCTAssertNil(contentPass.refreshTimer)
    }
    
    func testAuthStateErrorBubblesUpCorrectly() {
        let clientId = UUID().uuidString
        let authState = MockedAuthState.createRandom()
        let contentPass = ContentPass(clientId: clientId)
        contentPass.delegate = self
        contentPass.authState(wrappedState: authState, didEncounterAuthorizationError: ContentPassError.missingOIDServiceConfiguration)
        XCTAssertEqual(delegatedState, .error(ContentPassError.missingOIDServiceConfiguration))
    }
    
    func testAuthStateErrorRemovesTokenFromKeychain() {
        let clientId = UUID().uuidString
        let keychain = KeychainStore(clientId: clientId)
        let authState = MockedAuthState.createRandom()
        authState.accessTokenExpirationDate = Date(timeIntervalSinceNow: 5)
        keychain.storeAuthState(authState)
        let contentPass = ContentPass(clientId: clientId, keychain: keychain)
        contentPass.delegate = self
        XCTAssertEqual(authState, keychain.retrieveAuthState() as! MockedAuthState)
        contentPass.authState(wrappedState: authState, didEncounterAuthorizationError: ContentPassError.missingOIDServiceConfiguration)
        XCTAssertNil(keychain.retrieveAuthState())
    }
}

extension ContentPassTests: ContentPassDelegate {
    func onStateChanged(contentPass: ContentPass, newState: ContentPass.State) {
        delegatedState = newState
    }
}
