import AppAuth
import AuthenticationServices
import UIKit

/// Functions that enable you to react to changes in the contentpass sdk's state.
public protocol ContentPassDelegate: AnyObject {
    /// A function that enables you to react to a change in contentpass state.
    ///
    /// - Parameters:
    ///   - contentPass: The contentpass object that contains the state change.
    ///   - newState: The new `ContentPass.State` of the contentpass object. Can contain an error that can either be a `ContentPassError` or some underlying error. The underlying errors can be cast to `NSError` and then handled according to `domain` and `code`.
    func onStateChanged(contentPass: ContentPass, newState: ContentPass.State)
}

/// An object that handles all communication with the contentpass servers for you.
///
/// Its core functionality is authenticating a contentpass user via OAuth 2.0 and afterwards validating whether the authenticated user has a valid contentpass subscription plan.
///
/// User information gets persisted in the keychain and the relevant tokens get refreshed automatically, therefore the subscription information is always up to date.
///
/// You should only have one instance of this object at any one time. A good place for it is in your topmost state holding object or your app's `AppDelegate` / `SceneDelegate`.
///
/// Don't forget to implement the `ContentPassDelegate` protocol and set one of your state handling objects as the `delegate`. You can then react to authentication or subscription state changes.
///
/// **Important**: The `contentpass_configuration.json` file needs to be available as a resource in your app bundle. Otherwise initialization will result in a `fatalError`.
///
/// The initializer will automatically retrieve any stored authentication token information from the device's keychain and validate the subscription status if a token was stored previously.
/// The device should therefore be connected to the internet at this point.
///
/// If an error occurs during the initial token validation:
/// * The error will be provided as this object's `state`
/// * The error will be pushed to this object's `delegate` via `onStateChanged(contentPass:newState:)`.
public class ContentPass: NSObject {
    // MARK: PUBLIC PROPERTIES

    /// Your personal client identifier that was provided by contentpass.
    ///
    /// This can only be provided via the initializer.
    public let propertyId: String

    /// The current authentication state of the contentpass sdk.
    ///
    /// This is always up to date but to be notified of changes in state, be sure to register a `ContentPassDelegate` as the parent object's `delegate`.
    ///
    /// For the possible values and their meaning see `ContentPass.State`.
    internal (set) public var state = State.initializing { didSet { didSetState(state) } }

    /// The object that acts as the delegate of the contentpass sdk.
    ///
    /// The delegate must adopt the `ContentPassDelegate` protocol. The delegate is not retained.
    public weak var delegate: ContentPassDelegate?

    // MARK: INTERNAL PROPERTIES
    var oidAuthState: OIDAuthStateWrapping? {
        didSet { didSetAuthState(oidAuthState) }
    }
    let keychain: KeychainStoring
    let authorizer: Authorizing

    let delegateWrapper = OIDDelegateWrapper()
    var refreshTimer: Timer?

    private let configuration: Configuration
    
    // MARK: PUBLIC FUNCTIONS

    /// An object that handles all communication with the contentpass servers for you.
    ///
    /// Important: The `contentpass_configuration.json` file needs to be available as a resource in your app bundle.
    ///
    /// The initializer will automatically retrieve any stored authentication token information from the device's keychain and validate the subscription status if a token was stored previously.
    /// The device should therefore be connected to the internet at this point.
    ///
    /// If an error occurs during the initial token validation:
    /// * The error will be provided as this object's `state`
    /// * The error will be pushed to this object's `delegate` via `onStateChanged(contentPass:newState:)`.
    public convenience override init() {
        let config = Configuration.load()

        let authorizer = Authorizer(
            clientId: config.propertyId,
            clientRedirectUri: config.redirectUrl,
            discoveryUrl: config.baseUrl
        )
        self.init(configuration: config, keychain: KeychainStore(clientId: config.propertyId), authorizer: authorizer)
    }

    /// Starts the authentication flow for the user.
    ///
    /// - Parameters:
    ///   - presentingViewController: A `UIViewController` that's able to present the view controllers that handle the authentication flow.
    ///   - completionHandler: The `Result` is a `success(.authorized(hasValidSubscription)` on authentication success, otherwise contains an `Error` describing what went wrong. The `Error` is either of the `ContentPassError` type or an underlying error.
    ///
    /// Depending on the user's iOS version this either starts a `ASWebAuthenticationSession` or a `SFAuthenticationSession`.
    ///
    /// On an authentication `success()`, be sure to check the `authorized` state's boolean attribute `hasValidSubscription` for whether the user has an active contentpass subscription that's relevant to your property id.
    public func authenticate(presentingViewController: UIViewController, completionHandler: @escaping (Result<State, Error>) -> Void) {
        authorizer.authorize(presentingViewController: presentingViewController) { [weak self] result in
            switch result {
            case .success(let newAuthState):
                self?.oidAuthState = newAuthState

                guard let idToken = newAuthState.idToken else { break }

                self?.authorizer.validateSubscription(idToken: idToken) { result in
                    switch result {
                    case .success(let isValid):
                        completionHandler(.success(.authenticated(hasValidSubscription: isValid)))
                    case .failure(let error):
                        completionHandler(.failure(error))
                    }
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    /// Removes all saved information regarding the currently logged in user.
    ///
    /// This also purges all persistent information from the keychain.
    ///
    /// A user will have to login again after you call this method.
    public func logout() {
        oidAuthState = nil
    }

    /// Triggers validation of the authentication tokens.
    ///
    /// You might encounter error states because there was no or bad internet connection while refreshing the tokens.
    /// Call this function to tell the `ContentPass` object that the internet connection recovered.
    /// It then refreshes and / or reauthenticates the tokens if necessary.
    public func recoverFromError() {
        validateAuthState()
    }
    
    /// Count an impression for the logged in user.
    ///
    /// A user needs to be authenticated and have a subscription applicable to your service.
    /// - Parameter completionHandler: On a successful counting of the impression, the Result is a `success`. If something went wrong, you'll be supplied with an appropriate error case. The error  `ContentPassError.badHTTPStatusCode(404)` most probably means that your user has no applicable subscription.
    public func countImpression(completionHandler: @escaping (Result<Void, Error>) -> Void) {
        let impressionID = UUID()
        let propertyId = propertyId.split(separator: "-").first!
        let request = URLRequest(url: URL(string:  "\(configuration.baseUrl)/pass/hit?pid=\(propertyId)&iid=\(impressionID)&t=pageview")!)
        
        oidAuthState?.fireRequest(urlRequest: request) { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completionHandler(.success(()))
                } else {
                    completionHandler(.failure(ContentPassError.badHTTPStatusCode(httpResponse.statusCode)))
                }
            } else {
                completionHandler(.failure(ContentPassError.corruptedResponseFromWeb))
            }
        }
    }

    // MARK: INTERNAL FUNCTIONS

    convenience init(configuration: Configuration, keychain: KeychainStoring) {
        let authorizer = Authorizer(
            clientId: configuration.propertyId,
            clientRedirectUri: configuration.redirectUrl,
            discoveryUrl: configuration.baseUrl
        )
        self.init(configuration: configuration, keychain: keychain, authorizer: authorizer)
    }

    init(configuration: Configuration, keychain: KeychainStoring, authorizer: Authorizing) {
        defer {
            delegateWrapper.delegate = self
            validateAuthState()
        }
        self.configuration = configuration
        self.propertyId = configuration.propertyId
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

    private func doTokenRefresh() {
        guard let authState = oidAuthState else {
            state = .unauthenticated
            return
        }

        authState.performTokenRefresh { [weak self] error in
            self?.state = .error(error)
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

}

// MARK: OIDDelegateWrapperDelegate
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
