import AppAuth
import AuthenticationServices
import UIKit

public protocol ContentPassDelegate: AnyObject  {
    func onStateChanged(contentPass: ContentPass, newState: ContentPass.State)
}

public class ContentPass: NSObject {
    public enum State {
        case initializing
        case unauthorized
        case authorized
    }
    private let clientId: String
    private let clientSecret = "ahc0oongie6iigaex7ciengie0quaiphuoQueeZa"
    private let clientRedirectUri = URL(string: "de.t-online.pur://oauth")!
    private let discoveryUrl = URL(string: "https://pur.t-online.de")!
    
    private var oidAuthState: OIDAuthState? { didSet { didSetAuthState(oidAuthState) } }
    private let keychain: KeychainStoring
    private let authorizer: Authorizing
    
    private var refreshTimer: Timer?
    
    public var state = State.initializing { didSet { didSetState(state) } }
    
    public weak var delegate: ContentPassDelegate?
    
    public convenience init(clientId: String) {
        self.init(clientId: clientId, keychain: KeychainStore(clientId: clientId))
    }
    
    init(clientId: String, keychain: KeychainStoring) {
        defer {
            validateAuthState()
            didSetAuthState(oidAuthState)
        }
        
        self.clientId = clientId
        self.keychain = keychain
        
        if let authState = keychain.retrieveAuthState() {
            oidAuthState = authState
        } else {
            state = .unauthorized
        }
        
        authorizer = Authorizer(
            clientId: clientId,
            clientSecret: clientSecret,
            clientRedirectUri: clientRedirectUri,
            discoveryUrl: discoveryUrl
        )
        
        super.init()
    }
    
    private func validateAuthState() {
        guard
            let authState = oidAuthState,
            let lastToken = authState.lastTokenResponse,
            let validUntil = lastToken.accessTokenExpirationDate
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
        // no completion handling needed because we implement the delegates
        authState.performAction(freshTokens: { _, _, _ in } )
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
    
    private func didSetAuthState(_ authState: OIDAuthState?) {
        oidAuthState?.errorDelegate = self
        oidAuthState?.stateChangeDelegate = self
    }
}

extension ContentPass: OIDAuthStateErrorDelegate {
    public func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
        print("authstate error: \(error)")
    }
}

extension ContentPass: OIDAuthStateChangeDelegate {
    public func didChange(_ state: OIDAuthState) {
        print("state changed: \(state.lastTokenResponse?.accessToken ?? "no access token")")
        if state.isAuthorized {
            self.state = .authorized
            guard let refreshDelay = state.lastTokenResponse?.accessTokenExpirationDate?.timeIntervalSinceNow else { return }
            setRefreshTimer(delay: refreshDelay)
            keychain.storeAuthState(state)
        } else {
            self.state = .unauthorized
            keychain.deleteAuthState()
        }
    }
}
