@testable import ContentPass
import AppAuth

class MockedOIDClient: OIDClientWrapping {
    enum ClientError: Error {
        case discoveryError
        case authError
    }
    static let validDiscoveryUrl = URL(string: "valid.discovery.url")!
    static let flakyDiscoveryUrl = URL(string: "flaky.discovery.url")!
    static let errorDiscoveryUrl = URL(string: "error.discovery.url")!
    static let resultingConfiguration = OIDServiceConfiguration(
        authorizationEndpoint: URL(string: "auth.endpoint")!,
        tokenEndpoint: URL(string: "token.endpoint")!
    )

    static let errorInAuthorizationClientId = "authError"
    static let unexpectedClientId = "unexpectedError"

    var discoveryUrl: URL?
    var didReturnConfiguration = false
    var calledCounter = 0

    var authRequest: OIDAuthorizationRequest?
    var shouldReturnAuthState: OIDAuthStateWrapping?

    func discoverConfiguration(forIssuer: URL, completionHandler: @escaping (OIDServiceConfiguration?, Error?) -> Void) {
        calledCounter += 1

        switch forIssuer {
        case MockedOIDClient.validDiscoveryUrl:
            discoveryUrl = forIssuer
            completionHandler(MockedOIDClient.resultingConfiguration, nil)
            didReturnConfiguration = true
        case MockedOIDClient.flakyDiscoveryUrl:
            if discoveryUrl == nil {
                discoveryUrl = MockedOIDClient.validDiscoveryUrl
                completionHandler(nil, ClientError.discoveryError)
            } else {
                completionHandler(MockedOIDClient.resultingConfiguration, nil)
                didReturnConfiguration = true
            }
        default:
            completionHandler(nil, ClientError.discoveryError)

        }
    }

    func doAuthorization(byPresenting: OIDAuthorizationRequest, presenting: UIViewController, completionHandler: @escaping (OIDAuthStateWrapping?, Error?) -> Void) {
        authRequest = byPresenting

        switch byPresenting.clientID {
        case MockedOIDClient.errorInAuthorizationClientId:
            completionHandler(nil, ClientError.authError)
        case MockedOIDClient.unexpectedClientId:
            completionHandler(nil, nil)
        default:
            completionHandler(shouldReturnAuthState ?? MockedAuthState.createRandom(), nil)
        }
    }
}
