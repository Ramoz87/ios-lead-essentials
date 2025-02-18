//
//  HTTPURLResponse+StatusCodes.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 18.02.2025.
//
import Foundation

extension HTTPURLResponse {
    private static var successCodes = Range(uncheckedBounds: (200, 300))

    var isOK: Bool {
        return HTTPURLResponse.successCodes.contains(statusCode)
    }
}
