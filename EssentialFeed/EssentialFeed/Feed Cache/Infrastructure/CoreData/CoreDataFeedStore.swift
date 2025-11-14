//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 31.12.2024.
//

import CoreData

final public class CoreDataFeedStore: Sendable {
    private static let modelName = "FeedCache"
    @MainActor
    private static let model = NSManagedObjectModel.with(name: modelName, in: Bundle(for: CoreDataFeedStore.self))
    
    private let container: NSPersistentContainer
    let context: NSManagedObjectContext
    
    deinit {
        cleanUpReferencesToPersistentStores()
    }
    
    enum StoreError: Error {
        case modelNotFound
        case failedToLoadPersistentContainer(Error)
    }
    
    public enum ContextQueue {
        case main
        case background
    }
    
    public var contextQueue: ContextQueue {
        context == container.viewContext ? .main : .background
    }
    
    @MainActor
    public convenience init(storeUrl: URL, contextQueue: ContextQueue = .background) throws {
        guard let model = CoreDataFeedStore.model else {
            throw StoreError.modelNotFound
        }
        
        try self.init(storeUrl: storeUrl, contextQueue: contextQueue, model: model)
    }
    
    public init(storeUrl: URL, contextQueue: ContextQueue = .background, model: NSManagedObjectModel) throws {
        container = try NSPersistentContainer.load(modelName: CoreDataFeedStore.modelName, model: model, url: storeUrl)
        context = contextQueue == .main ? container.viewContext : container.newBackgroundContext()
    }
    
    @available(*, deprecated, message: "Use async version instead")
    public func perform(_ action: @Sendable @escaping () -> Void) {
        context.perform(action)
    }
    
    public func perform<T>(_ block: @escaping @Sendable () throws -> T) async rethrows -> T {
        try await context.perform(block)
    }
    
    private func cleanUpReferencesToPersistentStores() {
        context.performAndWait {
            let coordinator = self.container.persistentStoreCoordinator
            try? coordinator.persistentStores.forEach(coordinator.remove)
        }
    }
}
