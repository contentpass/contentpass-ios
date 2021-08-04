import AppAuth

protocol KeychainStoring {
    func retrieveAuthState() -> OIDAuthState?
    func storeAuthState(_ token: OIDAuthState)
    func deleteAuthState()
}
