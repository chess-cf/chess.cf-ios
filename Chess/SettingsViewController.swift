//
//  SettingsViewController.swift
//  Chess
//
//  Created by Alex Studnicka on 23/12/14.
//  Copyright (c) 2014 Alex Studnička. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
		
		NSNotificationCenter.defaultCenter().addObserverForName("CHESSAPP_LOGIN", object: nil, queue: NSOperationQueue.mainQueue()) { _ in self.tableView.reloadData() }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

    // MARK: - UITableViewDataSource & UITableViewDelegate

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
		
		if indexPath == NSIndexPath(forRow: 0, inSection: 0) {
			cell.textLabel?.text = ~"USER"
			
			if let loginInfo = LoginInfo.fromDefaults() {
				cell.detailTextLabel?.text = loginInfo.username
			} else {
				cell.detailTextLabel?.text = "-"
			}
		}
		
		return cell
    }

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if indexPath == NSIndexPath(forRow: 1, inSection: 0) {
			tableView.deselectRowAtIndexPath(indexPath, animated: true)
			logout()
		}
	}
	
	// MARK: - Actions
	
	func logout() {
		
		let ud = NSUserDefaults.standardUserDefaults()
		ud.setValue(nil, forKey: "token")
		ud.setValue(nil, forKey: "username")
		ud.synchronize()
		
		self.tabBarController!.performSegueWithIdentifier("LoginSegue", sender: self)
		
	}

}
