@testable import ContentPass
import Foundation

class Convenience {
    static func createDummyAuthorizer(
        clientId: String = "",
        clientSecret: String? = nil,
        redirectUrl: URL = URL(string: "dummy.url")!,
        discoveryUrl: URL = MockedOIDClient.validDiscoveryUrl,
        client: OIDClientWrapping = MockedOIDClient()
    ) -> Authorizer {
        return Authorizer(
            clientId: clientId,
            clientSecret: clientSecret,
            clientRedirectUri: redirectUrl,
            discoveryUrl: discoveryUrl,
            client: client
        )
    }
}
