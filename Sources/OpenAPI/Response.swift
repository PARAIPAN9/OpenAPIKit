//
//  Response.swift
//  
//
//  Created by Mathew Polzin on 6/22/19.
//

import Foundation

extension OpenAPI {
    public struct Response: Equatable {
        public let description: String?
        //    public let headers:
        public let content: PathItem.PathProperties.Operation.ContentMap
        //    public let links:

        public init(description: String,
                    content: PathItem.PathProperties.Operation.ContentMap) {
            self.description = description
            self.content = content
        }

        public enum StatusCode: RawRepresentable, Equatable, Hashable {
            public typealias RawValue = String

            case `default`
            case status(code: Int)

            public var rawValue: String {
                switch self {
                case .default:
                    return "default"

                case .status(code: let code):
                    return String(code)
                }
            }

            public init?(rawValue: String) {
                if let val = Int(rawValue) {
                    self = .status(code: val)
                } else {
                    self = .default
                }
            }
        }
    }
}

// MARK: - Codable

extension OpenAPI.Response {
    private enum CodingKeys: String, CodingKey {
        case description
        //        case headers
        case content
        //        case links
    }
}

extension OpenAPI.Response: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let desc = description {
            try container.encode(desc, forKey: .description)
        }

        // Hack to work around Dictionary encoding
        // itself as an array in this case:
        let stringKeyedDict = Dictionary(
            content.map { ($0.key.rawValue, $0.value) },
            uniquingKeysWith: { $1 }
        )
        try container.encode(stringKeyedDict, forKey: .content)
    }
}

extension OpenAPI.Response: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        description = try container.decodeIfPresent(String.self, forKey: .description)

        // hacky workaround for Dictionary decoding bug
        let contentDict = try container.decode([String: OpenAPI.Content].self, forKey: .content)
        content = Dictionary(contentDict.compactMap { contentTypeString, content in
            OpenAPI.ContentType(rawValue: contentTypeString).map { ($0, content) } },
                               uniquingKeysWith: { $1 })
    }
}

extension OpenAPI.Response.StatusCode: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        let string: String
        switch self {
        case .`default`:
            string = "default"

        case .status(code: let code):
            string = String(code)
        }

        try container.encode(string)
    }
}

extension OpenAPI.Response.StatusCode: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let val = Self(rawValue: try container.decode(String.self))

        guard let value = val else {
            throw OpenAPI.DecodingError.unknown(codingPath: decoder.codingPath)
        }

        self = value
    }
}
