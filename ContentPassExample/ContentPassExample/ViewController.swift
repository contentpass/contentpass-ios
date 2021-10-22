import UIKit
import Combine

class ViewController: UIViewController {
    private let authenticatedLabel = UILabel()
    private let subscriptionLabel = UILabel()
    private let loginButton = UIButton(type: .system)
    private let logoutButton = UIButton(type: .system)
    private let recoverButton = UIButton(type: .system)

    private var cancelBag = Set<AnyCancellable>()

    let viewModel: ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSubviews()
    }

    private func setupSubviews() {
        setupContent()
        setupLayout()
        setupBindings()
    }

    private func setupContent() {
        view.backgroundColor = .white
        loginButton.setTitle("Login", for: .normal)
        logoutButton.setTitle("Logout", for: .normal)
        recoverButton.setTitle("Recover from error", for: .normal)
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [authenticatedLabel, subscriptionLabel, loginButton, logoutButton, recoverButton])
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupBindings() {
        loginButton.addTarget(self, action: #selector(onLoginClicked), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(onLogoutClicked), for: .touchUpInside)
        recoverButton.addTarget(self, action: #selector(onRecoverClicked), for: .touchUpInside)

        viewModel.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .map { "Is authenticated: \($0)" }
            .assign(to: \.text, on: authenticatedLabel)
            .store(in: &cancelBag)

        viewModel.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: logoutButton)
            .store(in: &cancelBag)

        viewModel.$hasValidSubscription
            .receive(on: DispatchQueue.main)
            .map { "Has valid subscription: \($0)" }
            .assign(to: \.text, on: subscriptionLabel)
            .store(in: &cancelBag)

        viewModel.$isError
            .receive(on: DispatchQueue.main)
            .map(!)
            .assign(to: \.isHidden, on: recoverButton)
            .store(in: &cancelBag)
    }

    @objc
    private func onLoginClicked() {
        viewModel.login(presentingViewController: self)
    }

    @objc
    private func onLogoutClicked() {
        viewModel.logout()
    }

    @objc
    private func onRecoverClicked() {
        viewModel.recoverFromError()
    }
}
