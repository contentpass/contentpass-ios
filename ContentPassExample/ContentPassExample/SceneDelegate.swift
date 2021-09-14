import UIKit
import ContentPass

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    let contentPass = ContentPass()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        let viewModel = ViewModel(contentPass: contentPass)
        window.rootViewController = ViewController(viewModel: viewModel)
        window.makeKeyAndVisible()
        self.window = window
    }
}
