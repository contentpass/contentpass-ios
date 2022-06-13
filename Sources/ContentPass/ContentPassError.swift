/// A collection of errors that can occur in the contentpass sdk.
///
/// The most important one is `userCanceledAuthentication` that occurs on the user canceling the authentication flow.
///
/// Most others either point towards something being wrong with your configuration or credentials, the backend not responding in a way that the sdk would want or should straight up never happen. If one of the unexpected ones happens for you, feel free to raise an issue via GitHub.
public enum ContentPassError: Error {

    /// Something unexpected went wrong.
    ///
    /// If you encounter this, please report it via GitHub and include the `UnexpectedState`. Thank you!
    case unexpectedState(UnexpectedState)

    /// The response of our backend regarding the subscription data can't be parsed.
    case subscriptionDataCorrupted

    /// A response from our backend can't be casted to a `HTTPURLResponse`.
    case corruptedResponseFromWeb

    /// Something went wrong while validating the subscription in the backend.
    ///
    /// If this problem persists and your configuration is correct, contact us.
    case badHTTPStatusCode(Int)

    /// A previously successful authentication state did not contain the necessary token information to validate the subscription.
    ///
    /// If this problem persists and your configuration is correct, contact us.
    case oidAuthenticatedButMissingIdToken

    /// The user canceled the authentication flow by dismissing the authentication view.
    case userCanceledAuthentication

    /// While counting an impression, something went wrong during the token refresh. You should double check whether a user is currently authorized.
    case missingAccessToken

    public enum UnexpectedState {
        case missingSubscriptionData
        case missingConfigurationAfterDiscovery
        case missingConfigurationDuringAuthorization
        case missingAuthStateAfterAuthorization
    }
}
