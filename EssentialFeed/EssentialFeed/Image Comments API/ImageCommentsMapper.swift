//
//  RemoteFeedLoaderDataMapper 2.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 05.03.2025.
//
import Foundation

public final class ImageCommentsMapper {
    
    private struct Result: Decodable {
        private let items: [Item]
        
        private struct Item: Decodable {
            let id: UUID
            let message: String
            let created_at: Date
            let author: Author
        }
        
        private struct Author: Decodable {
            let username: String
        }
        
        var comments: [ImageComment] {
            items.map { ImageComment(id: $0.id, message: $0.message, createdAt: $0.created_at, username: $0.author.username) }
        }
    }
    
    public enum Error: Swift.Error {
        case invalidResponse
    }
    
    public static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [ImageComment] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard response.isOK, let result = try? decoder.decode(Result.self, from: data) else {
            throw RemoteImageCommentsLoader.Error.invalidResponse
        }
        
        return result.comments
    }
}
