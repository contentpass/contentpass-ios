import AppAuth

protocol OIDDelegateWrapperDelegate: AnyObject {
    func authState(_ state: OIDAuthStateWrapping, didEncounterAuthorizationError error: Error)
    func didChange(_ state: OIDAuthStateWrapping)
}

class OIDDelegateWrapper: NSObject, OIDAuthStateErrorDelegate, OIDAuthStateChangeDelegate {
    weak var delegate: OIDDelegateWrapperDelegate?
    
    func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
        delegate?.authState(state, didEncounterAuthorizationError: error)
    }
    
    func didChange(_ state: OIDAuthState) {
        delegate?.didChange(state)
    }
}
