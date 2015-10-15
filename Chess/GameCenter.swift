//
//  GameCenter.swift
//  Chess
//
//  Created by Alex Studnicka on 30/12/14.
//  Copyright (c) 2014 Alex Studnička. All rights reserved.
//

import Foundation
import GameKit

class _GameCenter: NSObject, GKGameCenterControllerDelegate {
	
	// MARK: - Authentication
	
	var authenticated = false
	
	func authenticate() {
		let localPlayer = GKLocalPlayer.localPlayer()
		localPlayer.authenticateHandler = { viewController, error in
			if let viewController = viewController {
				UIApp.tabBarVC.presentViewController(viewController, animated: true, completion: nil)
			} else if localPlayer.authenticated {
				self.authenticated = true
			} else {
				print("GameCenter !NOT! authenticated / Error: \(error)")
				self.authenticated = false
				
				var vcs = UIApp.tabBarVC.viewControllers
				vcs?.removeAtIndex(2)
				UIApp.tabBarVC.setViewControllers(vcs!, animated: true)
			}
		}
	}
	
	// MARK: - Open Game Center
	
	func openGameCenter() {
		let gcVC = GKGameCenterViewController()
		gcVC.gameCenterDelegate = self
		UIApp.tabBarVC.presentViewController(gcVC, animated: true, completion: nil)
	}
	
	// MARK: - GKGameCenterControllerDelegate
	
	func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
		UIApp.tabBarVC.dismissViewControllerAnimated(true, completion: nil)
	}
	
}

let GameCenter = _GameCenter()
