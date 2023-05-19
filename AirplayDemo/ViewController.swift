//
//  ViewController.swift
//  AirplayDemo
//
//  Created by Ayush Mishra on 17/05/23.
//

import UIKit
import CoreData

struct AirPlayDevice {
    let name: String
    let ipAddress: String
    var isReachable: Bool
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NetServiceDelegate {
    var devices: [AirPlayDevice] = []
    var tableView: UITableView!
    let runLoop = RunLoop.current
        let distantFuture = Date.distantFuture

        ///    Set this to false when we want to exit the app...
        var shouldKeepRunning = true
    
    func run() {
            while shouldKeepRunning == true &&
                runLoop.run(mode:.default, before: distantFuture) {}
        }
    // Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView(frame: view.bounds)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        discoverAirPlayDevices()
        fetchDevicesFromCoreData()
    }

    func discoverAirPlayDevices() {
        let serviceType = "_airplay._tcp."
        let browser = NetServiceBrowser()
        browser.delegate = self
        browser.searchForServices(ofType: serviceType, inDomain: "")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let device = devices[indexPath.row]
        cell.textLabel?.text = "\(device.name) (\(device.ipAddress))"

        if device.isReachable {
            cell.detailTextLabel?.text = "Reachable"
            cell.detailTextLabel?.textColor = .green
            saveDeviceToCoreData(name: device.name, ipAddress: device.ipAddress)
        } else {
            cell.detailTextLabel?.text = "Unreachable"
            cell.detailTextLabel?.textColor = .red
        }

        return cell
    }
    
    // Save reachable device data to Core Data
    func saveDeviceToCoreData(name: String, ipAddress: String) {
        let context = persistentContainer.viewContext
        let deviceEntity = NSEntityDescription.entity(forEntityName: "Entity", in: context)!
        let device = NSManagedObject(entity: deviceEntity, insertInto: context)
        device.setValue(name, forKey: "name")
        device.setValue(ipAddress, forKey: "ipAddress")
        
        do {
            try context.save()
        } catch {
            print("Failed to save device data: \(error)")
        }
    }
    
    // Fetch saved devices from Core Data
    func fetchDevicesFromCoreData() {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Entity")
        
        do {
            let fetchedDevices = try context.fetch(fetchRequest) as! [NSManagedObject]
            for device in fetchedDevices {
                let name = device.value(forKey: "name") as! String
                let ipAddress = device.value(forKey: "ipAddress") as! String
                let newDevice = AirPlayDevice(name: name, ipAddress: ipAddress, isReachable: true)
                devices.append(newDevice)
            }
            
            tableView.reloadData()
        } catch {
            print("Failed to fetch devices: \(error)")
        }
    }
}

extension ViewController: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        let device = AirPlayDevice(name: service.name, ipAddress: "", isReachable: false)
        devices.append(device)
        tableView.reloadData()

        let ipResolutionService = NetService(domain: "", type: "_device-info._tcp.", name: service.name)
        ipResolutionService.delegate = self
        ipResolutionService.resolve(withTimeout: 5.0)
    }
}
