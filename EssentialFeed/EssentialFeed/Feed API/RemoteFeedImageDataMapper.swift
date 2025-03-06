//
//  FeedImageDataMapper.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 06.03.2025.
//
import Foundation

public final class RemoteFeedImageDataMapper {
    
    public enum Error: Swift.Error {
        case invalidData
    }

    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> Data {
        guard response.isOK, !data.isEmpty else {
            throw Error.invalidData
        }

        return data
    }
}
