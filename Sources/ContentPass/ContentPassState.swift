// swiftlint:disable cyclomatic_complexity

extension ContentPass {
    public enum State: Equatable {
        case initializing
        case unauthenticated
        case authenticated(hasValidSubscription: Bool)
        case error(Error)

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
    }
}
