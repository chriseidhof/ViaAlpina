//
//  MasterViewController.swift
//  ViaAlpina
//
//  Created by Chris Eidhof on 23/06/15.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import UIKit

struct Stage {
    let number: Int
    
    var path: String {
        return NSBundle.mainBundle().resourcePath?.stringByAppendingPathComponent("kml/\(number).kml") ?? ""

    }
    
    var next: Stage {
        return Stage(number: number+1)
    }
}

class MasterViewController: UITableViewController {

    var stages: [Stage] = (1...160).map { Stage(number: $0) }


    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        assert( segue.identifier == "showDetail")
        if let indexPath = self.tableView.indexPathForSelectedRow {
            let stage = stages[indexPath.row]
            let vc = segue.destinationViewController as! MapViewController
            vc.stage = stage
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        let ip = NSIndexPath(forRow: 42, inSection: 0)
        tableView.scrollToRowAtIndexPath(ip, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stages.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell

        let stage = stages[indexPath.row]
        cell.textLabel!.text = "\(stage.number)"
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

}

