//
//  MasterViewController.swift
//  ViaAlpina
//
//  Created by Chris Eidhof on 23/06/15.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {

    var stages: [Stage] = (1...Stage.max).map { Stage(number: $0) }
    
    override func viewDidLoad() {
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(12)]
        navigationController?.navigationBar.titleTextAttributes = attributes
    }


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
        let ip = NSIndexPath(forRow: 50, inSection: 0)
        tableView.scrollToRowAtIndexPath(ip, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
    }

    // MARK: - Table View

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stages.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell

        var stage = stages[indexPath.row]
        cell.textLabel?.text = stage.kmlInfo?.name
        return cell
    }
}

