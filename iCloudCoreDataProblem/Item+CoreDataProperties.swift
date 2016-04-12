//
//  Item+CoreDataProperties.swift
//  iCloudCoreDataProblem
//
//  Created by Maris Veide on 12.04.2016.
//  Copyright © 2016 ITissible. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Item {

    @NSManaged var str: String?
    @NSManaged var date: NSDate?

}
