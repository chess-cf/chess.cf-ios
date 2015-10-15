//
//  Extensions.swift
//  Chess
//
//  Created by Alex Studnicka on 23/12/14.
//  Copyright (c) 2014 Alex Studnička. All rights reserved.
//

import Foundation
import UIKit

// ----------------
// MARK: - Strings -
// ----------------

prefix operator ~ {}
prefix func ~(a: String) -> String {
	return NSLocalizedString(a, comment: "")
}

extension String {
	subscript (i: Int) -> String {
		return String(Array(self.characters)[i])
	}
	
	subscript (i: Int) -> Character {
		return Character(String(Array(self.characters)[i]))
	}
	
	subscript (r: Range<Int>) -> String {
		let startIndex = self.startIndex.advancedBy(r.startIndex)
		let endIndex = startIndex.advancedBy(r.endIndex - r.startIndex)
		return self[Range(start: startIndex, end: endIndex)]
	}
	
	func replace(target: String, withString: String) -> String {
		return self.stringByReplacingOccurrencesOfString(target, withString: withString, options: NSStringCompareOptions.LiteralSearch, range: nil)
	}
	
//	func stringByReplacingCharacterAtIndex(index: Int, replacement: Character) -> String {
//		var tmp = self
//		let range = advance(self.startIndex, index)...advance(self.startIndex, index)
//		tmp.replaceRange(range, with: String(replacement))
//		return tmp
//	}
}

extension Character {
	init (_ unicode: Int) {
		self = Character(UnicodeScalar(unicode))
	}
	
	func unicode() -> Int {
		let characterString = String(self)
		let scalars = characterString.unicodeScalars
		return Int(scalars[scalars.startIndex].value)
	}
}

// ----------------
// MARK: - Colors -
// ----------------

prefix operator © {}
prefix func ©(a: Int) -> UIColor {
	return UIColor(rgba: String(format:"#%X", a))
}

extension UIColor {
	convenience init(rgba: String) {
		var red:   CGFloat = 0.0
		var green: CGFloat = 0.0
		var blue:  CGFloat = 0.0
		var alpha: CGFloat = 1.0
		
		if rgba.hasPrefix("#") {
			let index   = rgba.startIndex.advancedBy(1)
			let hex     = rgba.substringFromIndex(index)
			let scanner = NSScanner(string: hex)
			var hexValue: CUnsignedLongLong = 0
			if scanner.scanHexLongLong(&hexValue) {
				switch (hex.characters.count) {
				case 3:
					red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
					green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
					blue  = CGFloat(hexValue & 0x00F)              / 15.0
					break
				case 4:
					red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
					green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
					blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
					alpha = CGFloat(hexValue & 0x000F)             / 15.0
					break
				case 6:
					red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
					green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
					blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
					break
				case 8:
					red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
					green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
					blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
					alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
					break
				default:
					print("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8")
					break
				}
			} else {
				print("Scan hex error")
			}
		} else {
			print("Invalid RGB string, missing '#' as prefix")
		}
		self.init(red:red, green:green, blue:blue, alpha:alpha)
	}
}

// ----------------
// MARK: - dispatch_after -
// ----------------

func dispatch_after(delay: Double, closure: (() -> Void)) {
	dispatch_after(
		dispatch_time(
			DISPATCH_TIME_NOW,
			Int64(delay * Double(NSEC_PER_SEC))
		),
		dispatch_get_main_queue(), closure)
}

// ----------------
// MARK: - Random -
// ----------------

func arc4random <T: IntegerLiteralConvertible> (type: T.Type) -> T {
	var r: T = 0
	arc4random_buf(&r, sizeof(T))
	return r
}

extension UInt64 {
	static func random(lower: UInt64 = min, upper: UInt64 = max) -> UInt64 {
		var m: UInt64
		let u = upper - lower
		var r = arc4random(UInt64)
		
		if u > UInt64(Int64.max) {
			m = 1 + ~u
		} else {
			m = ((max - (u * 2)) + 1) % u
		}
		
		while r < m {
			r = arc4random(UInt64)
		}
		
		return (r % u) + lower
	}
}

extension Int64 {
	static func random(lower: Int64 = min, upper: Int64 = max) -> Int64 {
		let (s, overflow) = Int64.subtractWithOverflow(upper, lower)
		let u = overflow ? UInt64.max - UInt64(~s) : UInt64(s)
		let r = UInt64.random(upper: u)
		
		if r > UInt64(Int64.max)  {
			return Int64(r - (UInt64(~lower) + 1))
		} else {
			return Int64(r) + lower
		}
	}
}

extension Int32 {
	static func random(lower: Int32 = min, upper: Int32 = max) -> Int32 {
		let r = arc4random_uniform(UInt32(Int64(upper) - Int64(lower)))
		return Int32(Int64(r) + Int64(lower))
	}
}

extension Int {
	static func random(lower: Int = min, upper: Int = max) -> Int {
		switch (__WORDSIZE) {
		case 32: return Int(Int32.random(Int32(lower), upper: Int32(upper)))
		case 64: return Int(Int64.random(Int64(lower), upper: Int64(upper)))
		default: return lower
		}
	}
}
