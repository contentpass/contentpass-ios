import AppAuth

struct OIDClientWrapper: OIDClientWrapping {
    private var currentAuthorizationFlow: OIDExternalUserAgentSession?

    func discoverConfiguration(forIssuer: URL, completionHandler: @escaping (OIDServiceConfiguration?, Error?) -> Void) {
        OIDAuthorizationService.discoverConfiguration(forIssuer: forIssuer, completion: completionHandler)
    }

    mutating func doAuthorization(byPresenting: OIDAuthorizationRequest, presenting: UIViewController, completionHandler: @escaping (OIDAuthStateWrapping?, Error?) -> Void) {
        currentAuthorizationFlow = OIDAuthState.authState(
            byPresenting: byPresenting,
            presenting: presenting,
            callback: completionHandler
        )
    }
}
