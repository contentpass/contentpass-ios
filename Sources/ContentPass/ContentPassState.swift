// swiftlint:disable cyclomatic_complexity

extension ContentPass {
    public enum State: Equatable {
        case initializing
        case unauthorized
        case authorized
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
            case .authorized:
                switch rhs {
                case .authorized:
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
            case .unauthorized:
                switch rhs {
                case .unauthorized:
                    return true
                default:
                    return false
                }
            }
        }
    }
}
