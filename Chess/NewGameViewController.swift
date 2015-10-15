//
//  NewGameViewController.swift
//  Chess
//
//  Created by Alex Studnicka on 23/12/14.
//  Copyright (c) 2014 Alex Studnička. All rights reserved.
//

import UIKit

protocol NewGameDelegate {
	func newGameCreated(response: NewGameResponse)
}

class NewGameViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

	@IBOutlet weak var againstSelector: UISegmentedControl!
	@IBOutlet weak var colorSelector: UISegmentedControl!
	@IBOutlet weak var friendView: UIView!
	@IBOutlet weak var friendPicker: UIPickerView!
	
	var delegate: NewGameDelegate?
	
	// MARK: - View Controller
	
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	// MARK: - Selectors changed

	@IBAction func selectorChanged(sender: UISegmentedControl) {
		if sender == againstSelector {
			
			UIView.animateWithDuration(0.25) {
				if self.againstSelector.selectedSegmentIndex == 1 {
					self.friendView.alpha = 1
					
					if API.friends == nil {
						API.listFriends { error in
							self.friendPicker.reloadAllComponents()
						}
					}
				} else {
					self.friendView.alpha = 0
				}
			}
			
		} else if sender == colorSelector {
			
		}
	}
	
	// MARK: - UIPickerViewDataSource & UIPickerViewDelegate
	
	func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		if API.friends != nil {
			return API.friends!.count
		} else {
			return 0
		}
	}
	
	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return API.friends![row].username
	}
	
	// MARK: - Done
	
	@IBAction func done(sender: UIBarButtonItem) {
		var opponent: String
		switch self.againstSelector.selectedSegmentIndex {
		case 0:
			opponent = "computer"
		case 1:
			opponent = "friend"
		case 2:
			opponent = "link"
		default:
			opponent = ""
		}
		
		var color: String
		switch self.colorSelector.selectedSegmentIndex {
		case 0:
			color = "white"
		case 1:
			color = "random"
		case 2:
			color = "black"
		default:
			color = ""
		}
		
		var friend: Int? = nil
		if self.againstSelector.selectedSegmentIndex == 1 && API.friends != nil {
			let row = self.friendPicker.selectedRowInComponent(0)
			friend = API.friends![row].uid
		}
		
		API.newGame(color, opponent: opponent, friend: friend) { response in
			if let response = response {
				if self.delegate != nil {
					self.delegate?.newGameCreated(response)
				}
				self.navigationController?.popViewControllerAnimated(true)
			} else {
				UIAlertView(title: ~"ERROR", message: nil, delegate: nil, cancelButtonTitle: ~"DISMISS").show()
			}
		}
	}
	
}
