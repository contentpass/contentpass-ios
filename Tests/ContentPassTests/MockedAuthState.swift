import AppAuth
@testable import ContentPass

class MockedAuthState: OIDAuthStateWrapping {
    var isAuthorized = false
    var accessToken: String?
    var accessTokenExpirationDate: Date?
    var refreshToken: String?
    var tokenType: String?
    var idToken: String?
    var additionalParameters: [String : NSCopying & NSObjectProtocol]?
    var scope: String?
    var tokenScope: String?
    var authorizationError: Error?
    var errorDelegate: OIDAuthStateErrorDelegate?
    var stateChangeDelegate: OIDAuthStateChangeDelegate?
    var wasTokenRefreshPerformed = false
    
    func performTokenRefresh() {
        wasTokenRefreshPerformed = true
    }
}

extension MockedAuthState: Equatable {
    static func == (lhs: MockedAuthState, rhs: MockedAuthState) -> Bool {
        lhs.isAuthorized == rhs.isAuthorized
            && lhs.accessToken == rhs.accessToken
            && lhs.accessTokenExpirationDate == rhs.accessTokenExpirationDate
            && lhs.refreshToken == rhs.refreshToken
            && lhs.tokenType == rhs.tokenType
            && lhs.additionalParameters?.count == rhs.additionalParameters?.count
            && lhs.scope == rhs.scope
            && lhs.tokenScope == rhs.tokenScope
            && lhs.wasTokenRefreshPerformed == rhs.wasTokenRefreshPerformed
    }
}
