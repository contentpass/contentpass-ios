import AppAuth

protocol KeychainStoring {
    func retrieveAuthState() -> OIDAuthStateWrapping?
    func storeAuthState(_ token: OIDAuthStateWrapping)
    func deleteAuthState()
}
