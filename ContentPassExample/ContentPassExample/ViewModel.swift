import SwiftUI
import ContentPass
import Combine

class ViewModel: ObservableObject {
    let contentPass: ContentPass

    @Published var isAuthenticated = false
    @Published var hasValidSubscription = false
    @Published var isError = false
    @Published var impressionTries = 0
    @Published var impressionSuccesses = 0

    init(contentPass: ContentPass) {
        defer {
            contentPass.delegate = self
        }

        self.contentPass = contentPass
    }

    func login() {
        guard let viewController = UIApplication.shared.windows.first?.rootViewController else { return }
        
        contentPass.authenticate(presentingViewController: viewController) { result in
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
                viewController.present(alert, animated: true, completion: nil)
            }
        }
    }

    func logout() {
        contentPass.logout()
    }

    func recoverFromError() {
        contentPass.recoverFromError()
    }
    
    func countImpression() {
        contentPass.countImpression { [weak self] result in
            DispatchQueue.main.async {
                self?.impressionTries += 1
                
                switch result {
                case .success:
                    self?.impressionSuccesses += 1
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
}

extension ViewModel: ContentPassDelegate {
    func onStateChanged(contentPass: ContentPass, newState: ContentPass.State) {
        DispatchQueue.main.async {
            switch newState {
            case .initializing, .unauthenticated:
                self.isAuthenticated = false
                self.hasValidSubscription = false
                self.isError = false
            case .error(let error):
                print(error)
                self.isAuthenticated = false
                self.hasValidSubscription = false
                self.isError = true
            case .authenticated(let sub):
                self.isAuthenticated = true
                self.hasValidSubscription = sub
                self.isError = false
            }
        }
    }
}
