import UIKit
import AppAuth

protocol Authorizing {
    var clientId: String { get }
    var clientRedirectUri: URL { get }
    var discoveryUrl: URL { get }
    func authorize(presentingViewController: UIViewController, completionHandler: @escaping (Result<OIDAuthStateWrapping, Error>) -> Void)
    func validateSubscription(idToken: String, completionHandler: @escaping (Result<Bool, Error>) -> Void)
}
