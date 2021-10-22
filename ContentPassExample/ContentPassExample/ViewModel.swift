import UIKit
import ContentPass
import Combine

class ViewModel {
    let contentPass: ContentPass

    @Published var isAuthenticated = false
    @Published var hasValidSubscription = false
    @Published var isError = false

    init(contentPass: ContentPass) {
        defer {
            contentPass.delegate = self
        }

        self.contentPass = contentPass
    }

    func login(presentingViewController: UIViewController) {
        contentPass.authenticate(presentingViewController: presentingViewController) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                let errorMessage: String

                switch error {
                case ContentPassError.userCanceledAuthentication:
                    errorMessage = "User canceled authentication."
                default:
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

    func recoverFromError() {
        contentPass.recoverFromError()
    }
}

extension ViewModel: ContentPassDelegate {
    func onStateChanged(contentPass: ContentPass, newState: ContentPass.State) {
        switch newState {
        case .initializing, .unauthenticated:
            isAuthenticated = false
            hasValidSubscription = false
            isError = false
        case .error(let error):
            print(error)
            isAuthenticated = false
            hasValidSubscription = false
            isError = true
        case .authenticated(let sub):
            isAuthenticated = true
            hasValidSubscription = sub
            isError = false
        }
    }
}
