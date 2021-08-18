import UIKit
import ContentPass
import Combine

class ViewModel {
    let contentPass: ContentPass

    @Published var isAuthenticated = false
    @Published var hasValidSubscription = false

    init(contentPass: ContentPass) {
        defer {
            contentPass.delegate = self
        }
        self.contentPass = contentPass
    }

    func login(presentingViewController: UIViewController) {
        contentPass.authorize(presentingViewController: presentingViewController) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                let nsError = error as NSError
                let errorMessage: String
                if nsError.domain == "org.openid.appauth.general" && nsError.code == -3 {
                    errorMessage = "User cancelled authentication."
                } else {
                    errorMessage = "\(error)"
                }

                let alert = UIAlertController(title: "An error occured:", message: errorMessage, preferredStyle: .alert)
                alert.addAction(.init(title: "Okay", style: .default) { _ in
                    alert.dismiss(animated: true, completion: nil)
                })
                presentingViewController.present(alert, animated: true, completion: nil)
            }
        }
    }

    func logout() {
        contentPass.logout()
    }
}

extension ViewModel: ContentPassDelegate {
    func onStateChanged(contentPass: ContentPass, newState: ContentPass.State) {
        switch newState {
        case .initializing, .unauthenticated:
            isAuthenticated = false
            hasValidSubscription = false
        case .error(let error):
            print(error)
            isAuthenticated = false
            hasValidSubscription = false
        case .authenticated(let sub):
            isAuthenticated = true
            hasValidSubscription = sub
        }
    }
}
