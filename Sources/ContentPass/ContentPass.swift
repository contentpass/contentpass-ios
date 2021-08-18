import AppAuth
import AuthenticationServices
import UIKit

public protocol ContentPassDelegate: AnyObject {
    func onStateChanged(contentPass: ContentPass, newState: ContentPass.State)
}

public class ContentPass: NSObject {
    private let clientId: String
    private static let clientRedirectUri = URL(string: "de.t-online.pur://oauth")!
    private static let discoveryUrl = URL(string: "https://pur.t-online.de")!

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
            clientRedirectUri: ContentPass.clientRedirectUri,
            discoveryUrl: ContentPass.discoveryUrl
        )
        self.init(clientId: clientId, keychain: KeychainStore(clientId: clientId), authorizer: authorizer)
    }

    convenience init(clientId: String, keychain: KeychainStoring) {
        let authorizer = Authorizer(
            clientId: clientId,
            clientRedirectUri: ContentPass.clientRedirectUri,
            discoveryUrl: ContentPass.discoveryUrl
        )
        self.init(clientId: clientId, keychain: keychain, authorizer: authorizer)
    }

    init(clientId: String, keychain: KeychainStoring, authorizer: Authorizing) {
        defer {
            delegateWrapper.delegate = self
            validateAuthState()
        }

        self.clientId = clientId
        self.keychain = keychain
        self.authorizer = authorizer

        if let authState = keychain.retrieveAuthState() {
            oidAuthState = authState
            oidAuthState?.errorDelegate = delegateWrapper
            oidAuthState?.stateChangeDelegate = delegateWrapper
        } else {
            state = .unauthenticated
        }

        super.init()
    }

    private func validateAuthState() {
        guard
            let authState = oidAuthState,
            authState.isAuthorized,
            let validUntil = authState.accessTokenExpirationDate
        else {
            state = .unauthenticated
            return
        }

        let timeInterval = validUntil.timeIntervalSinceNow

        if authState.isAuthorized && timeInterval > 0 {
            validateSubscription()
            setRefreshTimer(delay: timeInterval)
        } else {
            doTokenRefresh()
        }
    }

    private func validateSubscription() {
        guard
            oidAuthState?.isAuthorized ?? false,
            let idToken = oidAuthState?.idToken
        else {
            state = .error(ContentPassError.oidAuthenticatedButMissingIdToken)
            return
        }

        authorizer.validateSubscription(idToken: idToken) { [weak self] result in
            switch result {
            case .success(let isValid):
                self?.state = .authenticated(hasValidSubscription: isValid)
            case .failure(let error):
                self?.state = .error(error)
            }
        }
    }

    private func setRefreshTimer(delay: Double) {
        refreshTimer?.invalidate()

        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: delay,
            repeats: false,
            block: { [weak self] _ in
                self?.doTokenRefresh()
            }
        )
    }

    @objc
    private func doTokenRefresh() {
        guard let authState = oidAuthState else {
            state = .unauthenticated
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
        if state == .unauthenticated {
            keychain.deleteAuthState()
        }
        delegate?.onStateChanged(contentPass: self, newState: state)
    }

    private func didSetAuthState(_ authState: OIDAuthStateWrapping?) {
        oidAuthState?.errorDelegate = delegateWrapper
        oidAuthState?.stateChangeDelegate = delegateWrapper

        if let authState = authState {
            didChange(authState)
        } else {
            keychain.deleteAuthState()
            state = .unauthenticated
        }
    }

    public func logout() {
        oidAuthState = nil
    }
}

extension ContentPass: OIDDelegateWrapperDelegate {
    func didChange(_ state: OIDAuthStateWrapping) {
        if state.isAuthorized {
            validateSubscription()
            guard let refreshDelay = state.accessTokenExpirationDate?.timeIntervalSinceNow else { return }
            setRefreshTimer(delay: refreshDelay)
            keychain.storeAuthState(state)
        } else {
            self.state = .unauthenticated
        }
    }

    func authState(_ state: OIDAuthStateWrapping, didEncounterAuthorizationError error: Error) {
        self.state = .error(error)
        keychain.deleteAuthState()
    }
}
