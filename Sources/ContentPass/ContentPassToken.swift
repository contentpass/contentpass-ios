import Foundation

struct ContentPassTokenResponse: Codable {
    let contentpassToken: String
}

struct ContentPassToken {
    let header: Header
    let body: Body

    var isSubscriptionValid: Bool {
        body.auth && !body.plans.isEmpty
    }

    init?(tokenString: String) {
        let split = tokenString.split(separator: ".")
        guard
            split.count >= 2,
            let headerData = Data(urlSafeBase64Encoded: String(split[0])),
            let bodyData = Data(urlSafeBase64Encoded: String(split[1]))
        else { return nil }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            header = try decoder.decode(Header.self, from: headerData)
            body = try decoder.decode(Body.self, from: bodyData)
        } catch _ {
            return nil
        }

    }

    struct Header: Codable {
        let alg: String
    }
    struct Body: Codable {
        let auth: Bool
        let plans: [String]
        let aud: String
        let iat: Date
        let exp: Date
    }
}

extension Data {
    init?(urlSafeBase64Encoded: String) {
        var stringtoDecode: String = urlSafeBase64Encoded.replacingOccurrences(of: "-", with: "+")
        stringtoDecode = stringtoDecode.replacingOccurrences(of: "_", with: "/")
        switch stringtoDecode.utf8.count % 4 {
        case 2:
            stringtoDecode += "=="
        case 3:
            stringtoDecode += "="
        default:
            break
        }
        guard let data = Data(base64Encoded: stringtoDecode, options: .ignoreUnknownCharacters) else {
            return nil
        }
        self = data
    }
}
