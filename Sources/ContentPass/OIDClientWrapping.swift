import AppAuth
import UIKit

protocol OIDClientWrapping {
    func discoverConfiguration(forIssuer: URL, completionHandler: @escaping (OIDServiceConfiguration?, Error?) -> Void)
    mutating func doAuthorization(byPresenting: OIDAuthorizationRequest, presenting: UIViewController, completionHandler: @escaping (OIDAuthState?, Error?) -> Void)
}
