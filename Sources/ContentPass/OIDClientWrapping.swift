import AppAuth
import UIKit

protocol OIDClientWrapping {
    func discoverConfiguration(forIssuer: URL, completionHandler: @escaping (OIDServiceConfiguration?, Error?) -> Void)
    func doAuthorization(byPresenting: OIDAuthorizationRequest, presenting: UIViewController, completionHandler: @escaping (OIDAuthStateWrapping?, Error?) -> Void)
    func fireValidationRequest(_ validationRequest: URLRequest, completionHandler: @escaping (Data?, Error?) -> Void)
}
