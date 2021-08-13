import AppAuth
import Strongbox

struct KeychainStore: KeychainStoring {
    private let strongbox: Strongbox
    let keyPrefix: String
    private let authStateKey = "OIDAuthState"

    init(clientId: String) {
        keyPrefix = "de.contentpass.\(clientId)"
        strongbox = Strongbox(keyPrefix: keyPrefix)
    }

    func retrieveAuthState() -> OIDAuthStateWrapping? {
        strongbox.unarchive(objectForKey: authStateKey) as? OIDAuthStateWrapping
    }

    func storeAuthState(_ authState: OIDAuthStateWrapping) {
        strongbox.archive(authState, key: authStateKey)
    }

    func deleteAuthState() {
        strongbox.remove(key: authStateKey)
    }
}
