![contentpass](https://www.contentpass.de/img/logo.svg)



## Compatibility


> contentpass supports iOS 10.0 and above



## Installation

Since we use external dependencies for solved problems such as OAuth 2.0, we strongly recommend using a dependency manager.
We currently support SPM as well as CocoaPods.



### Swift Package Manager

With [Swift Package Manager](https://swift.org/package-manager), either
* In Xcode simply select **File > Swift Packages > Add Package Dependency** from menu and paste `https://github.com/contentpass/contentpass-ios`

or

* Add the following `dependency` to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/contentpass/contentpass-ios", .upToNextMajor(from: "2.1.0"))
]
```

In both cases don't forget to add the sdk to your targets.



### CocoaPods

With [CocoaPods](https://guides.cocoapods.org/using/getting-started.html), add the following line to your `Podfile`:
```ruby
  pod 'ContentPass', '~> 2.0.0'
```

Then, run `pod install` via terminal.



## Usage

All of our public facing functions and properties are documented in XCode.
We also provide an example application in the `/ContentPassExample` directory. If you're unclear about the usage of some of our features, have a look and tinker around with the code.

### The contentpass_configuration.json

You will be provided a json file with all values necessary to configure the contentpass object. The json file will need to be added to your bundle and target.
If unsure what that means: Drag the file into your Xcode project root and when prompted, select to add the file to all targets.

### The contentpass object and its delegate

You should instantiate and hold one instance of the `ContentPass` class in one of your top level state holding objects. This can be your implementation of `UIAppDelegate`, `UISceneDelegate` or any state container. You should only ever instantiate one instance of `ContentPass` at any one time to rule out state inconsistency shenanigans.


```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  let contentPass = ContentPass()

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    // ...
    contentPass.delegate = self
  }
}
```

Don't forget to set one of your objects as the delegate of the `ContentPass` instance. Otherwise you will not be notified of any changes in the authentication state. For that you need to implement the `ContentPassDelegate` protocol.

```swift
extension SceneDelegate: ContentPassDelegate {
    func onStateChanged(contentPass: ContentPass, newState: ContentPass.State) {
      // handle the new ContentPass.State, e.g.
      switch newState {
        case .authenticated(let hasValidSubscription):
	        print("This was a triumph!")
        default:
        	break
      }
    }
}
```

### Authentication

We use [AppAuth](https://github.com/openid/AppAuth-iOS) for the OAuth 2.0 process. AppAuth uses Apple's `ASWebAuthenticationSession` or if below iOS 12 `SFAuthenticationSession`.

That means, that the user will be presented with a modal `SFSafariViewController` like view in which they can authenticate themselves with our servers. We then use the OAuth result to validate whether the user has any active contentpass subscriptions that are applicable.

To authenticate and authorize the user, simply call `authenticate` on the `ContentPass` object. You will need  to pass a `UIViewController` that is able to present the OAuth session as well as a `completionHandler` that takes a `Result<Void, Error>`.

```swift
contentPass.authenticate(presentingViewController: viewController) { result in
	switch result {
    case .success:
    	// this only means that authentication was successful,
    	// it doesn't tell you anything about the subscription status
    	break
    case .failure(let error):
    	// handle errors accordingly - refer to "Error handling" in this document
  }
}
```

If the authentication was a success, we will poll our servers for subscription plans in the background.

The `delegate` will be called with the final authentication and subscription state.

**Be aware that a successfully authenticated user may have no active subscription plans** and act accordingly!

### A few words on persistence

* We store tokens that anonymously identify the logged in user's session to our servers in the device's keychain.
* We refresh these tokens automatically in the background before they're invalidated.
* The subscription information gets validated as well on every token refresh.

### Logging out a user

Since we persist the user's session, you need a way to log the user out. Simply call `logout` and we remove all stored token data.

```swift
contentPass.logout()
```

The user will of course have to log in again afterwards.
You can also call `authenticate` again and all previous user information will get overwritten.
We only store *one* user session at any one time.

### Error handling

An error can occur during the `authenticate` function's lifetime or you can get an `.error(Error)` state in the delegate's `onStateChanged` function.

We have our own `ContentPassError` enum for the following cases:

* The user has canceled or dismissed the OAuth flow: `userCanceledAuthentication`
  You should handle this accordingly.
* Something went wrong while communicating with the backend: `subscriptionDataCorrupted`, `corruptedResponseFromWeb`, `badHTTPStatusCode` or `oidAuthenticatedButMissingIdToken`
  If you're sure that you have configured and set up everything correctly and one of these problems persists, contact us via GitHub issues or by mail.
* Something very unexpected happened: `unexpectedState`
  This should never occur and is basically our `throws` replacement since we're async. If you encounter one of these, feel very free to open a GitHub issue.

We also bubble up underlying errors that may occur because of connectivity problems or other issues regarding the OAuth flow.
With these errors it's best practice to cast them to `NSError` and look up the error's `domain` and `code` on your favorite search engine.

### Recovering from network errors

Sometimes we encounter an error state while refreshing the tokens in the background due to bad or no internet connection.
Since we don't monitor the device's connection state you need to tell the SDK that the network connection has been reestablished / improved. We will then refresh and revalidate the user's authentication tokens.

```swift
contentPass.recoverFromError()
```

### Couting an impression

Counting an impression is as easy as calling the function `countImpression(completionHandler:)`. A user has to be authenticated and have an active subscription applicable to your scope for this to work.

```swift
contentPass.countImpression { result in
  switch result {
    case .success:
    	// continue with your life
    case .error(let error):
    	// handle the error.
  }
}
```



## License

[MIT licensed](https://github.com/contentpass/contentpass-ios/blob/main/LICENSE)

## Open Source

We use the following open source packages in this SDK:

* [AppAuth](https://github.com/openid/AppAuth-iOS) for everything related to the OAuth 2.0 flow

* [Strongbox](https://github.com/granoff/Strongbox) for comfortably storing `NSCoding` objects into the keychain

