@testable import ContentPass
import Foundation

class Convenience {
    static func createDummyAuthorizer(
        clientId: String = "",
        redirectUrl: URL = URL(string: "dummy.url")!,
        discoveryUrl: URL = MockedOIDClient.validDiscoveryUrl,
        client: OIDClientWrapping = MockedOIDClient()
    ) -> Authorizer {
        return Authorizer(
            clientId: clientId,
            clientRedirectUri: redirectUrl,
            discoveryUrl: discoveryUrl,
            client: client
        )
    }
}
