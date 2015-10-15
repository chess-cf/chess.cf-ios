//
//  AppDelegate.swift
//  Chess
//
//  Created by Alex Studnička on 25.10.14.
//  Copyright (c) 2014 Alex Studnička. All rights reserved.
//

import UIKit
import GameKit

var UIApp: AppDelegate {
	return UIApplication.sharedApplication().delegate as! AppDelegate
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {

	var window: UIWindow?
	
	var tabBarVC: UITabBarController {
		return self.window!.rootViewController! as! UITabBarController
	}
	
	// MARK: - UIApplicationDelegate

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		
		let board = Board()
		board.genMoves()
//		println("board: \(board.board)")
		
		// --------------------
		
		self.tabBarVC.delegate = self
		
		// UI customization
		changeAppearance()
		
		// Login to Game Center
		#if !(arch(i386) || arch(x86_64)) && os(iOS)
			if API.getToken() != "" {
				GameCenter.authenticate()
			}
		#endif
		
		// Load sounds to memory
		initializeSounds()
		
		// Setup Channel
		API.setupChannelWebView(self.window!)
		
		return true
	}

	func applicationWillResignActive(application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
	
	// MARK: - Appearance
	
	func changeAppearance() {
		UITabBar.appearance().selectedImageTintColor = UIColor(red: 229/255, green: 206/255, blue: 183/255, alpha: 1)
	}
	
	// MARK: - UITabBarControllerDelegate
	
	func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
		if viewController.tabBarItem.tag == 3 {
			GameCenter.openGameCenter()
			return false
		}
		return true
	}

}

