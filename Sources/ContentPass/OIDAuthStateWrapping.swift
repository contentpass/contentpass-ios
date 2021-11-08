import AppAuth

protocol OIDAuthStateWrapping: NSSecureCoding {
    var isAuthorized: Bool { get }
    var accessToken: String? { get }
    var accessTokenExpirationDate: Date? { get }
    var refreshToken: String? { get }
    var tokenType: String? { get }
    var idToken: String? { get }
    var additionalParameters: [String: NSCopying & NSObjectProtocol]? { get }
    var scope: String? { get }
    var tokenScope: String? { get }
    var authorizationError: Error? { get }

    var errorDelegate: OIDAuthStateErrorDelegate? { get set }
    var stateChangeDelegate: OIDAuthStateChangeDelegate? { get set }

    func performTokenRefresh(errorHandler: @escaping (Error) -> Void)
}
