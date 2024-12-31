//
//  ManagedCache.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 31.12.2024.
//

import CoreData

@objc(ManagedCache)
class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
    
    var localFeed: [LocalFeedImage] {
        return feed.compactMap { ($0 as? ManagedFeedImage)?.local }
    }
}

extension ManagedCache {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ManagedCache> {
        return NSFetchRequest<ManagedCache>(entityName: "ManagedCache")
    }
    
    static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
        let request = Self.fetchRequest()
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first
    }
}
