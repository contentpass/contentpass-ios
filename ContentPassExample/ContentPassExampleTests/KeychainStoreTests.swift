import XCTest
@testable import ContentPass
import AppAuth

final class KeychainStoreTests: XCTestCase {
    private let dummyAuthState = MockedAuthState.createRandom()

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
        let store = KeychainStore(clientId: "some.client.id")
        store.storeAuthState(dummyAuthState)
        let result = store.retrieveAuthState()

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.accessToken, dummyAuthState.accessToken)
        XCTAssertEqual(result as! MockedAuthState, dummyAuthState)
    }

    func testDeleteAuthState() {
        let store = KeychainStore(clientId: "some.client.id")
        store.storeAuthState(dummyAuthState)

        XCTAssertNotNil(store.retrieveAuthState())
        store.deleteAuthState()
        XCTAssertNil(store.retrieveAuthState())
    }
}
