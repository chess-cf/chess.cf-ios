//
//  LoginViewController.swift
//  Chess
//
//  Created by Alex Studnicka on 22/12/14.
//  Copyright (c) 2014 Alex Studnička. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

	@IBOutlet weak var usernameField: UITextField!
	@IBOutlet weak var passwordField: UITextField!
	@IBOutlet weak var overlayView: UIView!
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		usernameField.becomeFirstResponder()
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	// MARK: - UITextFieldDelegate
	
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		if textField == usernameField {
			if let text = usernameField.text where text.characters.count > 0 {
				passwordField.becomeFirstResponder()
			}
		} else if textField == passwordField {
			login()
		}
		return false
	}
	
	// MARK: - Actions
	
	@IBAction func login() {
		
		guard let username = usernameField.text, let password = passwordField.text
			  where username.characters.count > 0 && password.characters.count > 0 else { return }
		
		usernameField.resignFirstResponder()
		passwordField.resignFirstResponder()
	
		self.navigationItem.rightBarButtonItem?.enabled = false
		UIView.animateWithDuration(0.25) {
			self.overlayView.alpha = 1
		}
		
		API.login(username, password: password) { error in
			if let error = error {
				
				self.navigationItem.rightBarButtonItem?.enabled = true
				UIView.animateWithDuration(0.25) {
					self.overlayView.alpha = 0
				}
				UIAlertView(title: ~"ERROR", message: ~error, delegate: nil, cancelButtonTitle: ~"DISMISS").show()
				
			} else {
				NSNotificationCenter.defaultCenter().postNotificationName("CHESSAPP_LOGIN", object: self)
				self.dismissViewControllerAnimated(true, completion: nil)
			}
		}
		
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
