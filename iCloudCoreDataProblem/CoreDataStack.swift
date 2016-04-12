//
//  CoreDataStack.swift
//  BugCatcher
//
//  Created by Maris Veide on 11.02.2016.
//  Copyright © 2016 Razeware. All rights reserved.
//

import CoreData

class CoreDataStack: CustomStringConvertible
{
    static let sharedManager = CoreDataStack()
    static let applicationDocumentsDirectoryName = "iCloud.com.maris.iCloudCoreDataProblem"
    static let errorDomain = "CoreDataStack"
    
    static let modelName = "DB"
    static let storeName = "DB"
    static var storeFileName: String
    {
        return storeName + ".sqlite"
    }
    var options : [String : AnyObject]?
    
    var inMemory: Bool = false
    
    
    var description: String
    {
        var desc = "context: \(self.managedObjectContext)\n" +
            "modelName: \(CoreDataStack.modelName)" +
            "storeURL: \(self.storeURL)"
        
        desc += "\nPersistent Stores:\n"
        for store in persistentStoreCoordinator.persistentStores
        {
            desc += "* \(store.URL!.absoluteString)"
        }
        
        return desc
    }
    
    
    lazy var managedObjectModel: NSManagedObjectModel =
        {
            let modelURL = NSBundle.mainBundle().URLForResource(modelName, withExtension: "momd")!
            return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator =
        {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            
            do
            {
                if self.inMemory
                {
                    try coordinator.addPersistentStoreWithType(
                        NSInMemoryStoreType,
                        configuration: nil,
                        URL: nil,
                        options: nil)
                } else
                {
                    try coordinator.addPersistentStoreWithType(
                        NSSQLiteStoreType,
                        configuration: nil,
                        URL: self.storeURL,
                        options: self.options)
                }
            } catch var error as NSError
            {
                print("ERROR: Persistent Store Error: \(error)")
            } catch
            {
                fatalError("Error creating Persistent Store!")
            }
            return coordinator
    }()
    
    
    /// The directory the application uses to store the Core Data store file.
    lazy var applicationSupportDirectory: NSURL =
        {
            let fileManager = NSFileManager.defaultManager()
            let urls = fileManager.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
            let applicationSupportDirectoryURL = urls.last!
            let applicationSupportDirectory =
                applicationSupportDirectoryURL.URLByAppendingPathComponent(applicationDocumentsDirectoryName)
            
            do
            {
                let properties = try applicationSupportDirectory.resourceValuesForKeys([NSURLIsDirectoryKey])
                
                if let isDirectory = properties[NSURLIsDirectoryKey] as? Bool where isDirectory == false
                {
                    let description = NSLocalizedString("Could not access the application data folder.",
                                                        comment: "Failed to initialize applicationSupportDirectory.")
                    let reason = NSLocalizedString("Found a file in its place.",
                                                   comment: "Failed to initialize applicationSupportDirectory.")
                    
                    throw NSError(domain: errorDomain, code: 201, userInfo:
                        [
                            NSLocalizedDescriptionKey: description,
                            NSLocalizedFailureReasonErrorKey: reason
                        ])
                }
            } catch let error as NSError where error.code != NSFileReadNoSuchFileError
            {
                fatalError("Error occured: \(error).")
            } catch
            {
                let path = applicationSupportDirectory.path!
                
                do
                {
                    try fileManager.createDirectoryAtPath(path, withIntermediateDirectories:true, attributes:nil)
                }
                catch
                {
                    fatalError("Could not create application documents directory at \(path).")
                }
            }
            
            return applicationSupportDirectory
    }()
    
    
    /// URL for the main Core Data store file.
    lazy var storeURL: NSURL =
        {
            return self.applicationSupportDirectory.URLByAppendingPathComponent(storeFileName)
    }()
    
    
    lazy var managedObjectContext: NSManagedObjectContext =
        {
            let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            context.persistentStoreCoordinator = self.persistentStoreCoordinator
            return context
    }()
    
    
    // ****************************************
    // MARK: - iCloud Sync
    // ****************************************
    
    var iCloudEnabled: Bool
    {
        let fm = NSFileManager.defaultManager()
        if let _ = fm.ubiquityIdentityToken
        {
            return true
        }
        
        return false
    }
    
    func monitorUbiquitousContentUpdatesIfiCloudEnabled()
    {
        if iCloudEnabled
        {
            // PROBLEM with iCloud APPEARS HERE if called when user not logged in iCloud!!!
            self.updateContextWithUbiquitousContentUpdates = true
        }
    }

    
    var updateContextWithUbiquitousContentUpdates: Bool = false
    {
        willSet
        {
            printDebug()
            ubiquitousChangesObserver = newValue ? NSNotificationCenter.defaultCenter() : nil
            
        }
    }
    
    
    private var ubiquitousChangesObserver: NSNotificationCenter?
    {
        didSet
        {
            printDebug(ubiquitousChangesObserver)
            
            oldValue?.removeObserver(
                self,
                name: NSPersistentStoreDidImportUbiquitousContentChangesNotification,
                object: persistentStoreCoordinator)
            
            ubiquitousChangesObserver?.addObserver(
                self,
                selector: #selector(self.persistentStoreDidImportUbiquitousContentChanges(_:)),
                name: NSPersistentStoreDidImportUbiquitousContentChangesNotification,
                object: persistentStoreCoordinator)
            
            
            oldValue?.removeObserver(
                self,
                name: NSPersistentStoreCoordinatorStoresWillChangeNotification,
                object: persistentStoreCoordinator)
            
            ubiquitousChangesObserver?.addObserver(
                self,
                selector: #selector(self.persistentStoreCoordinatorWillChangeStores(_:)),
                name: NSPersistentStoreCoordinatorStoresWillChangeNotification,
                object: persistentStoreCoordinator)
        }
    }
    
    
    @objc func persistentStoreDidImportUbiquitousContentChanges(notification: NSNotification)
    {
        print("Merging ubiquitous content changes")
        print(notification)
        
        self.managedObjectContext.performBlock
        {
            self.managedObjectContext.mergeChangesFromContextDidSaveNotification(notification)
        }
    }
    
    
    @objc func persistentStoreCoordinatorWillChangeStores(notification: NSNotification)
    {
        print(notification)
        
        if managedObjectContext.hasChanges
        {
            do
            {
                try managedObjectContext.save()
            } catch let error as NSError
            {
                print("Error saving: \(error)", terminator: "")
            }
        }
        managedObjectContext.reset()
    }
    
    
    
    // ***********************************************
    // * Data: iCloud Container Actions
    // ***********************************************
    
    func deleteiCloudContainer()
    {
        print("Deleting iCloud Container...")
        
        let currentStore = managedObjectContext.persistentStoreCoordinator!.persistentStores.last!
        
        print("Located data store [\(currentStore)]")
        
        managedObjectContext.reset()
        print("managedObjectContext.reset() - OK")
        
        do
        {
            try managedObjectContext.persistentStoreCoordinator?.removePersistentStore(currentStore)
            print("removePersistentStore() - OK")
        } catch let error as NSError
        {
            print("Could not remove persistent store [\(currentStore)]: \(error)")
        }
        
        do
        {
            try NSPersistentStoreCoordinator.removeUbiquitousContentAndPersistentStoreAtURL(
                currentStore.URL!, options: currentStore.options)
            print("removeUbiquitousContentAndPersistentStoreAtURL() - OK")
        } catch let error as NSError
        {
            print("Could not remove Ubiquitous Content and Persistent Store at URL [\(currentStore)]: \(error)")
        }
    }
    
    //*******************************************
    // MARK: - Init
    //*******************************************
    
    init(inMemory:Bool = false)
    {
        self.inMemory = inMemory
        
        self.options = [NSMigratePersistentStoresAutomaticallyOption: true,
                        NSInferMappingModelAutomaticallyOption: true]

        if iCloudEnabled
        {
            self.options?[NSPersistentStoreUbiquitousContentNameKey] = CoreDataStack.storeName
            self.monitorUbiquitousContentUpdatesIfiCloudEnabled()
        }

    }
    
}
