import UIKit
import AppAuth

protocol Authorizing {
    func authorize(presentingViewController: UIViewController, completionHandler: @escaping (Result<OIDAuthStateWrapping, Error>) -> Void)
}
