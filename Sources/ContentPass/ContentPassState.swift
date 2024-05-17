extension ContentPass {

    /// The possible contentpass authentication states.
    ///
    /// To be able to react to state changes, please implement the `ContentPassDelegate` protocol and set the `ContentPass` object's `delegate` property.
    public enum State: Equatable {
        /// The contentpass object was just created. Will switch to another state very soon.
        ///
        /// This occurs mainly when a user was authenticated previously and the stored token information is refreshed and validated.
        case initializing

        /// No user is authenticated.
        case unauthenticated

        /// The user has authenticated themselves successfully with our services.
        ///
        /// Since an authenticated user might not have an active subscription, you should always check `hasValidSubscription` to act accordingly.
        case authenticated(hasValidSubscription: Bool)

        /// We encountered an error.
        ///
        /// This might be a `ContentPassError` but it also can be something underlying. In the latter case, cast it to `NSError` and act according to `domain` and `code`.
        case error(Error)

        // swiftlint:disable cyclomatic_complexity
        public static func == (lhs: ContentPass.State, rhs: ContentPass.State) -> Bool {
            switch lhs {
            case .error:
                switch rhs {
                case .error:
                    return true
                default:
                    return false
                }
            case .authenticated:
                switch rhs {
                case .authenticated:
                    return true
                default:
                    return false
                }
            case .initializing:
                switch rhs {
                case .initializing:
                    return true
                default:
                    return false
                }
            case .unauthenticated:
                switch rhs {
                case .unauthenticated:
                    return true
                default:
                    return false
                }
            }
        }
        // swiftlint:enable cyclomatic_complexity
    }
}
