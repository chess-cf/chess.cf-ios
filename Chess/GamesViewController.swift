//
//  GamesViewController.swift
//  Chess
//
//  Created by Alex Studnicka on 22/12/14.
//  Copyright (c) 2014 Alex Studnička. All rights reserved.
//

import UIKit
import SwiftyJSON

class GamesViewController: UITableViewController, NewGameDelegate {
	
	var games: [GameInfo]?
	let dateFormatter = NSDateFormatter()
	
    override func viewDidLoad() {
		super.viewDidLoad()
		
		dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
		dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
		
		self.navigationItem.leftBarButtonItem = self.editButtonItem()
		
		if API.getToken() != "" {
			self.refresh(self.refreshControl!)
		}
		
		NSNotificationCenter.defaultCenter().addObserverForName("CHESSAPP_LOGIN", object: nil, queue: NSOperationQueue.mainQueue()) { _ in
			self.games = nil
			self.tableView.reloadData()
			self.refresh(self.refreshControl!)
		}
		
    }
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		if API.getToken() == "" {
			self.tabBarController!.performSegueWithIdentifier("LoginSegue", sender: self)
		} else if games == nil {
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
		
		API.listGames { games in
			self.games = games
			self.tableView.reloadData()
			self.refreshControl?.endRefreshing()
		}
		
	}
	
    // MARK: - UITableViewDataSource & UITableViewDelegate

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if let actualGames = games {
			if actualGames.count > 0 {
				return actualGames.count
			} else {
				return 1
			}
		} else {
			return 0
		}
    }
	
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if games!.count > 0 {
			return 1
		} else {
			return 0
		}
    }
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if games!.count > 0 {
			let game = games![section]
			return dateFormatter.stringFromDate(game.dateCreated)
		} else {
			return ~"NO_GAMES"
		}
	}
	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("GameCell", forIndexPath: indexPath) 

        let game = games![indexPath.section]
		cell.textLabel?.text = "♖ \(game.whitePlayer) × ♜ \(game.blackPlayer)"
		
        return cell
    }
	
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
	}
	
	override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
		return ~"LEAVE_GAME"
	}
	
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		if editingStyle == .Delete {
			let game = games!.removeAtIndex(indexPath.section)
			API.gameLeave(game.uid) {}
			if games!.count == 0 {
				tableView.reloadSections(NSIndexSet(index: indexPath.section), withRowAnimation: .Automatic)
			} else {
				tableView.deleteSections(NSIndexSet(index: indexPath.section), withRowAnimation: .Automatic)
			}
        }
    }

    // MARK: - Navigation
	
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "PushGameSegue" {
			let game = games![self.tableView.indexPathForSelectedRow!.section]
			let destination = segue.destinationViewController as! GameViewController
			destination.game = game
		} else if segue.identifier == "NewGameSegue" {
			let destination = segue.destinationViewController as! NewGameViewController
			destination.delegate = self
		}
    }
	
	// MARK: - NewGameResponse
	
	func newGameCreated(response: NewGameResponse) {
		games?.insert(response.info, atIndex: 0)
		if games!.count == 1 {
			tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
		} else {
			tableView.insertSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
		}
	}

}
