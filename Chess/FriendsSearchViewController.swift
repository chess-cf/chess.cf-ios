//
//  FriendsSearchViewController.swift
//  Chess
//
//  Created by Alex Studnicka on 28/12/14.
//  Copyright (c) 2014 Alex Studnička. All rights reserved.
//

import UIKit

class FriendsSearchViewController: UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate {
	
	var searchController = UISearchController(searchResultsController: nil)
	var friends: [FriendInfo]?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.navigationItem.hidesBackButton = true
		
		searchController.dimsBackgroundDuringPresentation = false
		searchController.hidesNavigationBarDuringPresentation = false
		searchController.delegate = self
		searchController.searchResultsUpdater = self
		searchController.searchBar.sizeToFit()
		searchController.searchBar.tintColor = ©0xE5CEB7
		searchController.searchBar.placeholder = ~"USERNAME_OR_EMAIL"
		self.navigationItem.titleView = searchController.searchBar
		
		self.definesPresentationContext = true
    }
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		searchController.active = true
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return (friends != nil) ? 1 : 0
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if friends!.count > 0 {
			return nil
		} else {
			return ~"NOT_FOUND"
		}
	}

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if friends!.count > 0 {
			return friends!.count
		} else {
			return 0
		}
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FriendCell", forIndexPath: indexPath) 

		let friend = self.friends![indexPath.row]
		
		cell.textLabel?.text = friend.username
		
		if friend.isFriend || friend.requested {
			cell.accessoryType = .Checkmark
			cell.selectionStyle = .None
		} else {
			cell.accessoryType = .None
			cell.selectionStyle = .Default
		}
		
        return cell
    }
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let friend = self.friends![indexPath.row]
		if !friend.isFriend && !friend.requested {
			API.sendRequest(friend.uid) {}
			tableView.deselectRowAtIndexPath(indexPath, animated: true)
			friend.requested = true
			tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
		}
	}
	
	// MARK: - UISearchResultsUpdating
	
	func updateSearchResultsForSearchController(searchController: UISearchController) {
		let query = searchController.searchBar.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) ?? ""
		if query.characters.count > 0 {
			API.searchFriends(query) { friends in
				self.friends = friends
				self.tableView.reloadData()
			}
		} else {
			self.friends = nil
			self.tableView.reloadData()
		}
	}
	
	// MARK: - UISearchControllerDelegate
	
	func didPresentSearchController(searchController: UISearchController) {
		searchController.searchBar.becomeFirstResponder()
	}
	
	func willDismissSearchController(searchController: UISearchController) {
		self.navigationController?.popViewControllerAnimated(true)
	}
	
}
