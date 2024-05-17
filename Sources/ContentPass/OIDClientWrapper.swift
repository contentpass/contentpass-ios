import AppAuth

class OIDClientWrapper: OIDClientWrapping {
    private var currentAuthorizationFlow: OIDExternalUserAgentSession?

    func discoverConfiguration(forIssuer: URL, completionHandler: @escaping (OIDServiceConfiguration?, Error?) -> Void) {
        OIDAuthorizationService.discoverConfiguration(forIssuer: forIssuer, completion: completionHandler)
    }

    func doAuthorization(byPresenting: OIDAuthorizationRequest, presenting: UIViewController, completionHandler: @escaping (OIDAuthStateWrapping?, Error?) -> Void) {
        if #available(iOS 13, *) {
            currentAuthorizationFlow = OIDAuthState.authState(
                byPresenting: byPresenting,
                presenting: presenting,
                prefersEphemeralSession: true,
                callback: completionHandler
            )
        } else {
            currentAuthorizationFlow = OIDAuthState.authState(
                byPresenting: byPresenting,
                presenting: presenting,
                callback: completionHandler
            )
        }
    }

    func fireValidationRequest(_ validationRequest: URLRequest, completionHandler: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: validationRequest) { data, response, error in
            guard let response = response as? HTTPURLResponse else {
                completionHandler(nil, ContentPassError.corruptedResponseFromWeb)
                return
            }
            if (200..<300).contains(response.statusCode) {
                completionHandler(data, error)
            } else {
                completionHandler(nil, ContentPassError.badHTTPStatusCode(response.statusCode))
            }
        }
        task.resume()
    }
}
