import Foundation

struct Configuration {
    let baseUrl: URL
    let redirectUrl: URL
    let propertyId: String

    static func load() -> Configuration {
        let fileName = "contentpass_configuration.json"
        let fromDisk = Bundle.main.decode(
            ConfigOnDisk.self,
            from: fileName,
            keyDecodingStrategy: .convertFromSnakeCase
        )

        let expectedVersion = 1

        guard fromDisk.schemaVersion == expectedVersion else {
            fatalError("Failed to decode \(fileName) from bundle due to unexpected schema_version. Expected: \(expectedVersion)")
        }

        guard let baseUrl = URL(string: fromDisk.baseUrl) else {
            fatalError("Failed to decode \(fileName) from bundle due to base_url being malformed")
        }

        guard let redirectUrl = URL(string: fromDisk.redirectUri) else {
            fatalError("Failed to decode \(fileName) from bundle due to redirect_uri being malformed")
        }

        return Configuration(baseUrl: baseUrl, redirectUrl: redirectUrl, propertyId: fromDisk.propertyId)
    }

    fileprivate struct ConfigOnDisk: Codable {
        let schemaVersion: Int
        let baseUrl: String
        let redirectUri: String
        let propertyId: String
    }
}

extension Bundle {
    func decode<T: Decodable>(_ type: T.Type, from file: String, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) -> T {
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate \(file) in bundle.")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(file) from bundle.")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        decoder.keyDecodingStrategy = keyDecodingStrategy

        do {
            return try decoder.decode(T.self, from: data)
        } catch DecodingError.keyNotFound(let key, let context) {
            fatalError("Failed to decode \(file) from bundle due to missing key '\(key.stringValue)' not found – \(context.debugDescription)")
        } catch DecodingError.typeMismatch(_, let context) {
            fatalError("Failed to decode \(file) from bundle due to type mismatch – \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            fatalError("Failed to decode \(file) from bundle due to missing \(type) value – \(context.debugDescription)")
        } catch {
            fatalError("Failed to decode \(file) from bundle: \(error)")
        }
    }
}
