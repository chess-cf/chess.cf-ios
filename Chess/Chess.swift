//
//  Chess.swift
//  Chess
//
//  Created by Alex Studnička on 25.10.14.
//  Copyright (c) 2014 Alex Studnička. All rights reserved.
//

import Foundation
import SceneKit

enum Player: Character {
	case White = "W"
	case Black = "B"
	
	init (string: String) {
		if string == "white" { self = .White }
						else { self = .Black }
	}
}

enum PieceType: Character {
	case King = "K"
	case Queen = "Q"
	case Rook = "R"
	case Bishop = "B"
	case Knight = "N"
	case Pawn = "P"
}

enum MoveType {
	case Move, Take
}

//struct Move {
//	let from: Position
//	let   to: Position
//	
//	init(from: Position, to: Position) {
//		self.from = from
//		  self.to = to
//	}
//	
//	init(_ string: String) {
//		let row0 = 8-String(string[1]).toInt()!
//		let col0 = string[0].unicodeScalarCodePoint()-97
//		let row1 = 8-String(string[3]).toInt()!
//		let col1 = string[2].unicodeScalarCodePoint()-97
//		from = Position(row0, col0)
//		  to = Position(row1, col1)
//	}
//	
//	func toString() -> String {
//		let row0 = 8-from.row
//		let col0 = Character(97+from.col)
//		let row1 = 8-to.row
//		let col1 = Character(97+to.col)
//		return "\(col0)\(row0)\(col1)\(row1)"
//	}
//}

struct BoardPiece {
	var color: Player
	var type: PieceType
	var model: SCNNode!
	
	init(_ color: Player, _ type: PieceType, _ model: SCNNode? = nil) {
		self.color = color
		self.type = type
		self.model = model
	}
	
	init?(char: String, isBlack: Bool) {
		if char == "." { return nil }
		
		if char == char.lowercaseString {
			self.color = isBlack ? .White : .Black
		} else {
			self.color = isBlack ? .Black : .White
		}
		
			 if (char.lowercaseString == "k")	{ self.type = .King }
		else if (char.lowercaseString == "q")	{ self.type = .Queen }
		else if (char.lowercaseString == "r")	{ self.type = .Rook }
		else if (char.lowercaseString == "b")	{ self.type = .Bishop }
		else if (char.lowercaseString == "n")	{ self.type = .Knight }
		else if (char.lowercaseString == "p")	{ self.type = .Pawn }
		else									{ return nil }
	}
}

//struct Position: Equatable {
//	var row: Int = 0, col: Int = 0
//	init(_ row: Int, _ col: Int) {
//		self.row = row
//		self.col = col
//	}
//}
//
//func ==(lhs: Position, rhs: Position) -> Bool {
//	return lhs.row == rhs.row && lhs.col == rhs.col
//}

func getPiece(row: Int, col: Int) -> BoardPiece? {
	if (row >= 0 && row < 8 && col >= 0 && col < 8) {
		return gameBoardArray[row][col]
	} else {
		return nil
	}
}

func getPiece(pos: Position) -> BoardPiece? {
	return getPiece(pos.row, col: pos.col)
}

var gameBoardArray: [[BoardPiece?]]!
