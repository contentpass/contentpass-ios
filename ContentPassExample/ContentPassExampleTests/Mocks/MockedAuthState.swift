@testable import ContentPass
import AppAuth

class MockedAuthState: NSObject, OIDAuthStateWrapping {
    func fireRequest(urlRequest: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
    }

    static var supportsSecureCoding = true

    var isAuthorized = false
    var accessToken: String?
    var accessTokenExpirationDate: Date?
    var refreshToken: String?
    var tokenType: String?
    var idToken: String?
    var additionalParameters: [String: NSCopying & NSObjectProtocol]?
    var scope: String?
    var tokenScope: String?
    var authorizationError: Error?
    weak var errorDelegate: OIDAuthStateErrorDelegate?
    weak var stateChangeDelegate: OIDAuthStateChangeDelegate?
    var wasTokenRefreshPerformed = false
    var hasInternetConnection = true

    func performTokenRefresh(errorHandler: @escaping (Error) -> Void) {
        wasTokenRefreshPerformed = hasInternetConnection
    }

    static func createRandom() -> MockedAuthState {
        let state = MockedAuthState()
        state.accessToken = UUID().uuidString
        state.accessTokenExpirationDate = Date(timeIntervalSinceNow: 5)
        state.idToken = UUID().uuidString
        state.isAuthorized = true
        state.refreshToken = UUID().uuidString
        state.tokenType = UUID().uuidString
        state.tokenScope = UUID().uuidString
        state.scope = UUID().uuidString
        return state
    }

    required init?(coder: NSCoder) {
        isAuthorized = coder.decodeBool(forKey: "isAuthorized")
        hasInternetConnection = coder.decodeBool(forKey: "hasInternetConnection")
        accessToken = coder.decodeObject(forKey: "accessToken") as? String
        accessTokenExpirationDate = coder.decodeObject(forKey: "accessTokenExpirationDate") as? Date
        refreshToken = coder.decodeObject(forKey: "refreshToken") as? String
        tokenType = coder.decodeObject(forKey: "tokenType") as? String
        idToken = coder.decodeObject(forKey: "idToken") as? String
        scope = coder.decodeObject(forKey: "scope") as? String
        tokenScope = coder.decodeObject(forKey: "tokenScope") as? String
    }

    override init() {
        super.init()
    }

    func encode(with coder: NSCoder) {
        coder.encode(hasInternetConnection, forKey: "hasInternetConnection")
        coder.encode(isAuthorized, forKey: "isAuthorized")
        coder.encode(accessToken, forKey: "accessToken")
        coder.encode(accessTokenExpirationDate, forKey: "accessTokenExpirationDate")
        coder.encode(refreshToken, forKey: "refreshToken")
        coder.encode(tokenType, forKey: "tokenType")
        coder.encode(idToken, forKey: "idToken")
        coder.encode(scope, forKey: "scope")
        coder.encode(tokenScope, forKey: "tokenScope")
    }

}

// MARK: Equatable
extension MockedAuthState {
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MockedAuthState else { return false }
        return other == self
    }

    static func == (lhs: MockedAuthState, rhs: MockedAuthState) -> Bool {
        lhs.isAuthorized == rhs.isAuthorized
            && lhs.accessToken == rhs.accessToken
            && lhs.accessTokenExpirationDate == rhs.accessTokenExpirationDate
            && lhs.refreshToken == rhs.refreshToken
            && lhs.tokenType == rhs.tokenType
            && lhs.additionalParameters?.count == rhs.additionalParameters?.count
            && lhs.scope == rhs.scope
            && lhs.tokenScope == rhs.tokenScope
    }
}
