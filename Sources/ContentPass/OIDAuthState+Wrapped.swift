import AppAuth

extension OIDAuthState: OIDAuthStateWrapping {
    func performTokenRefresh(errorHandler: @escaping (Error) -> Void) {
        assert(errorDelegate != nil)
        assert(stateChangeDelegate != nil)

        setNeedsTokenRefresh()

        performAction { _, _, error in
            guard let error = error else { return }
            errorHandler(error)
        }
    }

    func fireRequest(urlRequest: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        performAction { accessToken, _, error in
            if let error = error  {
                completionHandler(nil, nil, error)
            } else if let accessToken = accessToken {
                var urlRequest = urlRequest
                urlRequest.allHTTPHeaderFields = ["Authorization": "Bearer \(accessToken)"]
                
                URLSession.shared.dataTask(with: urlRequest) {
                    completionHandler($0, $1, $2)
                }.resume()
            } else {
                completionHandler(nil, nil, ContentPassError.missingAccessToken)
            }
        }
    }
    
    var tokenScope: String? {
        lastTokenResponse?.scope
    }

    var accessToken: String? {
        lastTokenResponse?.accessToken
    }

    var accessTokenExpirationDate: Date? {
        lastTokenResponse?.accessTokenExpirationDate
    }

    var tokenType: String? {
        lastTokenResponse?.tokenType
    }

    var idToken: String? {
        lastTokenResponse?.idToken
    }

    var additionalParameters: [String: NSCopying & NSObjectProtocol]? {
        lastTokenResponse?.additionalParameters
    }
}
