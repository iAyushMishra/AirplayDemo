//
//  Entity+CoreDataProperties.swift
//  AirplayDemo
//
//  Created by Ayush Mishra on 18/05/23.
//
//

import Foundation
import CoreData


extension Entity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entity> {
        return NSFetchRequest<Entity>(entityName: "Entity")
    }

    @NSManaged public var name: String?
    @NSManaged public var attribute: String?

}

extension Entity : Identifiable {

}
