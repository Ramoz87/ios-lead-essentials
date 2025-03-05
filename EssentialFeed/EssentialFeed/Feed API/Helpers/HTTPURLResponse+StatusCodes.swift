//
//  HTTPURLResponse+StatusCodes.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 18.02.2025.
//
import Foundation

extension HTTPURLResponse {
    var isOK: Bool {
        return (200...299).contains(statusCode)
    }
}
