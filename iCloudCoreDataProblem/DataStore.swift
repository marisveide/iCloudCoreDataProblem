//
//  DataStore.swift
//  Count Myself
//
//  Created by Maris Veide on 23.02.2016.
//  Copyright © 2016 ITissible. All rights reserved.
//

import Foundation
import CoreData


class DataStore
{
    //*******************************************
    // MARK: - Properties
    //*******************************************
    
    var managedContext: NSManagedObjectContext!
    {
        return self.stack.managedObjectContext
    }
    var stack: CoreDataStack!
    
    
    //*******************************************
    // MARK: - Data Collections
    //*******************************************
    
    
    func itemQuery() -> [Item]
    {
        let entityName = "Item"
        let fetchRequest = NSFetchRequest(entityName: entityName)
        
        do
        {
            let results = try managedContext?.executeFetchRequest(fetchRequest) as! [Item]
            return results
            
        } catch let error as NSError
        {
            print("ERROR: Could not run query for for \(entityName)!\n\(error), \(error.localizedDescription)")
        }
        
        return []
    }
    
    
    //*******************************************
    // MARK: - iCloud: Store Changes Events - when user logs out of iCloud or logs in to different iCloud account.
    //*******************************************
    
    @objc func persistentStoreCoordinatorDidChangeStores(notification: NSNotification)
    {
        printDebug()
    }
    
    var persistentStoreCoordinatorChangesObserver: NSNotificationCenter?
    {
        didSet
        {
            printDebug()
            
            oldValue?.removeObserver(self, name: NSPersistentStoreCoordinatorStoresDidChangeNotification,
                                     object: self.stack.persistentStoreCoordinator)
            
            persistentStoreCoordinatorChangesObserver?.addObserver(
                self,
                selector: #selector(self.persistentStoreCoordinatorDidChangeStores(_:)),
                name: NSPersistentStoreCoordinatorStoresDidChangeNotification,
                object: self.stack.persistentStoreCoordinator)
        }
    }
    
    //*******************************************
    // MARK: - Data Actions
    //*******************************************
    
    func createItem(str: String? = "") -> Item
    {
        let itemEntity = NSEntityDescription.entityForName("Item", inManagedObjectContext: managedContext)
        let item = Item(entity: itemEntity!, insertIntoManagedObjectContext: managedContext)
        
        item.date = NSDate()
        item.str = str
        
        return item
    }
    
        // ***********************************************
    // * - MARK: DB Loaders
    // ***********************************************
    
    
    func reload()
    {
        
    }
    
    
    // ***********************************************
    // * - MARK: Managed Context
    // ***********************************************
    
    func save() -> Bool
    {
        if managedContext.hasChanges
        {
            do
            {
                try managedContext.save()
            } catch let error as NSError
            {
                print("ERROR: Could not save DB!\n\(error), \(error.localizedDescription)")
                return false
            }
        }
        
        self.reload()
        
        return true
    }
    
    
    func rollback()
    {
        managedContext.rollback()
        self.reload()
    }
    
    
    
    // ***********************************************
    // * - MARK: Init
    // ***********************************************
    
    init(inMemory:Bool = false)
    {
        self.stack = CoreDataStack(inMemory: inMemory)
        // self.stack = CoreDataStackLocal()
        
        self.persistentStoreCoordinatorChangesObserver = NSNotificationCenter.defaultCenter()
    }
    
}

