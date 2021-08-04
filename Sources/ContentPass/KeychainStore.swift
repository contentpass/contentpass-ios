import AppAuth
import Strongbox

struct KeychainStore: KeychainStoring {
    private let strongbox: Strongbox
    private let authStateKey = "OIDAuthState"
    
    init(clientId: String) {
        strongbox = Strongbox(keyPrefix: "de.contentpass.\(clientId)")
    }
    
    func retrieveAuthState() -> OIDAuthState? {
        strongbox.unarchive(objectForKey: authStateKey) as? OIDAuthState
    }
    
    func storeAuthState(_ authState: OIDAuthState) {
        strongbox.archive(authState, key: authStateKey)
    }
    
    func deleteAuthState() {
        strongbox.remove(key: authStateKey)
    }
    
}
