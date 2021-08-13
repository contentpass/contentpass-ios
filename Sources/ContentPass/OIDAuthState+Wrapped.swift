import AppAuth

extension OIDAuthState: OIDAuthStateWrapping {
    func performTokenRefresh() {
        assert(errorDelegate != nil)
        assert(stateChangeDelegate != nil)
        // no completion handling needed because we implement the delegates
        performAction(freshTokens: { _, _, _ in })
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
