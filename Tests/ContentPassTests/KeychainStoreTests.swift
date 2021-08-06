import XCTest
@testable import ContentPass
import AppAuth

final class KeychainStoreTests: XCTestCase {
    private let dummyAuthState1: MockedAuthState = {
        let state = MockedAuthState()
        state.accessToken = UUID().uuidString
        state.accessTokenExpirationDate = Date()
        state.idToken = UUID().uuidString
        state.isAuthorized = true
        state.refreshToken = UUID().uuidString
        state.tokenType = UUID().uuidString
        state.tokenScope = UUID().uuidString
        state.scope = UUID().uuidString
        return state
    }()
    
    private let dummyAuthState2: MockedAuthState = {
        let state = MockedAuthState()
        state.accessToken = UUID().uuidString
        state.accessTokenExpirationDate = Date()
        state.idToken = UUID().uuidString
        state.isAuthorized = true
        state.refreshToken = UUID().uuidString
        state.tokenType = UUID().uuidString
        state.tokenScope = UUID().uuidString
        state.scope = UUID().uuidString
        return state
    }()
    
    func testInitGeneratesCorrectKeyPrefix() {
        let string = UUID().uuidString
        let expectedResult = "de.contentpass.\(string)"
        let store = KeychainStore(clientId: string)
        XCTAssertEqual(expectedResult, store.keyPrefix)
    }
    
    func testRetrieveAuthStateWithoutStoringResultsInNilValue() {
        let store = KeychainStore(clientId: "")
        let authState = store.retrieveAuthState()
        XCTAssertNil(authState)
    }
    
    func testStoredAuthStateIsRetrievable() {
        let store = KeychainStore(clientId: "")
        store.storeAuthState(dummyAuthState1)
        let result = store.retrieveAuthState() as? MockedAuthState
        XCTAssertNotNil(result)
        
        
        XCTAssertEqual(result, dummyAuthState1)
    }
}
