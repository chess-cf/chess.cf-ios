//
//  FriendsViewController.swift
//  Chess
//
//  Created by Alex Studnicka on 23/12/14.
//  Copyright (c) 2014 Alex Studnička. All rights reserved.
//

import UIKit

class FriendsViewController: UITableViewController {
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.navigationItem.leftBarButtonItem = self.editButtonItem()
		
		if API.friends == nil {
			self.refresh(self.refreshControl!)
		}
		
		NSNotificationCenter.defaultCenter().addObserverForName("CHESSAPP_LOGIN", object: nil, queue: NSOperationQueue.mainQueue()) { _ in
			API.friends = nil
			self.tableView.reloadData()
			self.refresh(self.refreshControl!)
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	// MARK: - Refresh
	
	@IBAction func refresh(sender: UIRefreshControl) {
		
		self.refreshControl?.beginRefreshing()
		
		API.listFriends { error in
			self.tableView.reloadData()
			self.refreshControl?.endRefreshing()
		}
		
	}
	
	// MARK: - UITableViewDataSource & UITableViewDelegate

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if API.requestedFriends != nil && API.friends != nil {
			if API.requestedFriends!.count > 0 && API.friends!.count > 0 {
				return 2
			} else {
				return 1
			}
		}
		return 0
    }
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if API.requestedFriends != nil && API.friends != nil {
			if API.requestedFriends!.count > 0 && API.friends!.count > 0 {
				if section == 0 {
					return ~"FRIEND_REQUESTS"
				} else {
					return ~"FRIENDS"
				}
			} else {
				if API.requestedFriends!.count > 0 {
					return ~"FRIEND_REQUESTS"
				} else if API.friends!.count > 0 {
					return ~"FRIENDS"
				} else {
					return ~"NO_FRIENDS"
				}
			}
		}
		return nil
	}

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if API.requestedFriends != nil && API.friends != nil {
			if API.requestedFriends!.count > 0 && API.friends!.count > 0 {
				if section == 0 {
					return API.requestedFriends!.count
				} else {
					return API.friends!.count
				}
			} else {
				if API.requestedFriends!.count > 0 {
					return API.requestedFriends!.count
				} else if API.friends!.count > 0 {
					return API.friends!.count
				} else {
					return 0
				}
			}
		}
		return 0
	}
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 44
	}
	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var request = true
		if API.requestedFriends!.count > 0 && API.friends!.count > 0 {
			if indexPath.section == 1 {
				request = false
			}
		} else {
			if API.friends!.count > 0 {
				request = false
			}
		}
		
		if request {
			let cell = tableView.dequeueReusableCellWithIdentifier("FriendRequestCell", forIndexPath: indexPath) 
			
			let friend = API.requestedFriends![indexPath.row]
			
			let label = cell.contentView.viewWithTag(1) as! UILabel
			label.text = friend.username
			
			let btn1 = cell.contentView.viewWithTag(2) as! UIButton
			btn1.removeTarget(self, action: nil, forControlEvents: .TouchUpInside)
			btn1.addTarget(self, action: "friendRequestButtonPressed:", forControlEvents: .TouchUpInside)
			
			let btn2 = cell.contentView.viewWithTag(3) as! UIButton
			btn2.removeTarget(self, action: nil, forControlEvents: .TouchUpInside)
			btn2.addTarget(self, action: "friendRequestButtonPressed:", forControlEvents: .TouchUpInside)
			
			return cell
		} else {
			let cell = tableView.dequeueReusableCellWithIdentifier("FriendCell", forIndexPath: indexPath) 
			
			let friend = API.friends![indexPath.row]
			cell.textLabel?.text = friend.username
			
			return cell
		}
    }
	
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		if API.requestedFriends!.count > 0 && API.friends!.count > 0 {
			if indexPath.section == 1 {
				return true
			}
		} else {
			if API.friends!.count > 0 {
				return true
			}
		}
		return false
    }
	
	override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
		return ~"UNFRIEND"
	}
	
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
			let friend = API.friends!.removeAtIndex(indexPath.row)
			API.unfriend(friend.uid) {}
			if API.friends!.count == 0 {
				tableView.reloadSections(NSIndexSet(index: indexPath.section), withRowAnimation: .Automatic)
			} else {
				tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
			}
        }
    }
	
	// MARK: - Friend Request Buttons
	
	func friendRequestButtonPressed(sender: UIButton) {
		let friendsWasEmpty = API.friends!.count > 0 ? false : true
		let cell = sender.superview?.superview as! UITableViewCell
		let indexPath = self.tableView.indexPathForCell(cell)!
		let friend = API.requestedFriends!.removeAtIndex(indexPath.row)
		if sender.tag == 2 { API.friends!.append(friend) }
		API.requestResponse(friend.uid, action: sender.tag == 2 ? "accept" : "reject") {}
		tableView.beginUpdates()
		if API.requestedFriends!.count == 0 {
			if API.friends!.count > 0 {
				if sender.tag == 2 {
					if friendsWasEmpty {
						tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
					} else {
						tableView.deleteSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
						tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: API.friends!.count-1, inSection: 0)], withRowAnimation: .Automatic)
					}
				} else {
					tableView.deleteSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
				}
			} else {
				tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
			}
		} else {
			if sender.tag == 2 {
				tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
				if friendsWasEmpty {
					tableView.insertSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
				} else {
					tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
				}
			} else {
				tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
			}
		}
		tableView.endUpdates()
	}

}
