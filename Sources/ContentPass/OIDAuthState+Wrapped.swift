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
