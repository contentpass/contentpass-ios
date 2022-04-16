import SwiftUI
import ContentPass

@main
struct ContentPassExampleApp: App {
    let contentPass = ContentPass()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: .init(contentPass: contentPass))
        }
    }
}
