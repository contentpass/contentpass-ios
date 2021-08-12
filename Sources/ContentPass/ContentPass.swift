import AppAuth
import AuthenticationServices
import UIKit

public protocol ContentPassDelegate: AnyObject  {
    func onStateChanged(contentPass: ContentPass, newState: ContentPass.State)
}

public class ContentPass: NSObject {
    private let clientId: String
    private static let clientSecret = "ahc0oongie6iigaex7ciengie0quaiphuoQueeZa"
    private static let clientRedirectUri = URL(string: "de.t-online.pur://oauth")!
    private static let discoveryUrl = URL(string: "https://pur.t-online.de")!
//    private static let clientSecret: String? = nil
//    private static let clientRedirectUri = URL(string: "de.contentpass.demo://oauth")!
//    private static let discoveryUrl = URL(string: "https://my.contentpass.io")!
    
    var oidAuthState: OIDAuthStateWrapping? {
        didSet { didSetAuthState(oidAuthState) }
    }
    let keychain: KeychainStoring
    let authorizer: Authorizing
    
    let delegateWrapper = OIDDelegateWrapper()
    var refreshTimer: Timer?
    
    public var state = State.initializing { didSet { didSetState(state) } }
    
    public weak var delegate: ContentPassDelegate?
    
    public convenience init(clientId: String) {
        let authorizer = Authorizer(
            clientId: clientId,
            clientSecret: ContentPass.clientSecret,
            clientRedirectUri: ContentPass.clientRedirectUri,
            discoveryUrl: ContentPass.discoveryUrl
        )
        self.init(clientId: clientId, keychain: KeychainStore(clientId: clientId), authorizer: authorizer)
    }
    
    convenience init(clientId: String, keychain: KeychainStoring) {
        let authorizer = Authorizer(
            clientId: clientId,
            clientSecret: ContentPass.clientSecret,
            clientRedirectUri: ContentPass.clientRedirectUri,
            discoveryUrl: ContentPass.discoveryUrl
        )
        self.init(clientId: clientId, keychain: keychain, authorizer: authorizer)
    }
    
    init(clientId: String, keychain: KeychainStoring, authorizer: Authorizing) {
        defer {
            delegateWrapper.delegate = self
            validateAuthState()
            didSetAuthState(oidAuthState)
        }
        
        self.clientId = clientId
        self.keychain = keychain
        self.authorizer = authorizer
        
        if let authState = keychain.retrieveAuthState() {
            oidAuthState = authState
        } else {
            state = .unauthorized
        }
        
        super.init()
    }
    
    private func validateAuthState() {
        guard
            let authState = oidAuthState,
            authState.isAuthorized,
            let validUntil = authState.accessTokenExpirationDate
        else {
            state = .unauthorized
            return
        }
        
        let timeInterval = validUntil.timeIntervalSinceNow
        
        if authState.isAuthorized && timeInterval > 0 {
            state = .authorized
            setRefreshTimer(delay: timeInterval)
        } else {
            doTokenRefresh()
        }
    }
    
    private func setRefreshTimer(delay: Double) {
        refreshTimer?.invalidate()

        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: delay,
            repeats: false,
            block: { [weak self] timer in
                self?.doTokenRefresh()
            }
        )
    }
    
    @objc
    private func doTokenRefresh() {
        guard let authState = oidAuthState else {
            state = .unauthorized
            return
        }
        authState.performTokenRefresh()
    }
    
    public func authorize(presentingViewController: UIViewController, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        authorizer.authorize(presentingViewController: presentingViewController) { [weak self] result in
            switch result {
            case .success(let newAuthState):
                self?.oidAuthState = newAuthState
            default: break
            }
            completionHandler(result.map { _ in })
        }
    }
    
    private func didSetState(_ state: State) {
        delegate?.onStateChanged(contentPass: self, newState: state)
    }
    
    private func didSetAuthState(_ authState: OIDAuthStateWrapping?) {
        oidAuthState?.errorDelegate = delegateWrapper
        oidAuthState?.stateChangeDelegate = delegateWrapper
        guard let authState = authState else { return }
        didChange(authState)
    }
}

extension ContentPass: OIDDelegateWrapperDelegate {
    func didChange(_ state: OIDAuthStateWrapping) {
        if state.isAuthorized {
            self.state = .authorized
            guard let refreshDelay = state.accessTokenExpirationDate?.timeIntervalSinceNow else { return }
            setRefreshTimer(delay: refreshDelay)
            keychain.storeAuthState(state)
        } else {
            self.state = .unauthorized
            keychain.deleteAuthState()
        }
    }
    
    func authState(_ state: OIDAuthStateWrapping, didEncounterAuthorizationError error: Error) {
        self.state = .error(error)
        keychain.deleteAuthState()
    }
}
