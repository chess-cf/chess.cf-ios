//
//  ChessAI.swift
//  Chess
//
//  Created by Alex Studnicka on 22/01/15.
//  Copyright (c) 2015 Alex Studnička. All rights reserved.
//

import Foundation

///////////////////////////////////////////////////////////////////////////////
// MARK: - Constants -
///////////////////////////////////////////////////////////////////////////////

//// maximum depth to search
//let MAX_DEPTH		= 4
//// maximum number of elements in the transposition table
//let TABLE_SIZE		= 1_000_000
//// controls how much time we spend on looking for optimal moves
//let NODES_SEARCHED	= 10_000
//// Mate value must be greater than 8*queen + 2*(rook+knight+bishop)
//// King value is set to twice this value such that if the opponent is
//// 8 queens up, but we got the king, we still exceed MATE_VALUE.
//let MATE_VALUE		= 30_000

let MAX_DEPTH		= 4
let TABLE_SIZE		= 1_000_000
let NODES_SEARCHED	= 500
//let MATE_VALUE		= 1_000_000

///////////////////////////////////////////////////////////////////////////////
// MARK: - Enums and Structs -
///////////////////////////////////////////////////////////////////////////////

enum Piece: UInt8, NilLiteralConvertible {
	//	case r = "r", n = "n", b = "b", q = "q", k = "k", p = "p"
	//	case R = "R", N = "N", B = "B", Q = "Q", K = "K", P = "P"
	//	case x = "."
	case x = 0
	case r, n, b, q, k, p
	case R, N, B, Q, K, P
	
	init(nilLiteral: ()) {
		self = .x
	}
	
	func toChar() -> Character {
		switch self {
		case .r: return "r"
		case .n: return "n"
		case .b: return "b"
		case .q: return "q"
		case .k: return "k"
		case .p: return "p"
		case .R: return "R"
		case .N: return "N"
		case .B: return "B"
		case .Q: return "Q"
		case .K: return "K"
		case .P: return "P"
		case .x: return "."
		}
	}
	
	func isLower() -> Bool {
		return self == .r || self == .n || self == .b || self == .q || self == .k || self == .p
	}
	
	func isUpper() -> Bool {
		return self == .R || self == .N || self == .B || self == .Q || self == .K || self == .P
	}
	
	func toLower() -> Piece {
		switch self {
		case .R: return .r
		case .N: return .n
		case .B: return .b
		case .Q: return .q
		case .K: return .k
		case .P: return .p
		default: return self
		}
	}
	
	func toUpper() -> Piece {
		switch self {
		case .r: return .R
		case .n: return .N
		case .b: return .B
		case .q: return .Q
		case .k: return .K
		case .p: return .P
		default: return self
		}
	}
	
	func switchCase() -> Piece {
		if self.isLower() { return self.toUpper() }
		else if self.isUpper() { return self.toLower() }
		else { return self }
	}
	
	func empty() -> Bool {
		return self == .x
	}
	
	func toBoardPiece() -> BoardPiece? {
		switch self {
		case .r: return BoardPiece(.Black, .Rook)
		case .n: return BoardPiece(.Black, .Knight)
		case .b: return BoardPiece(.Black, .Bishop)
		case .q: return BoardPiece(.Black, .Queen)
		case .k: return BoardPiece(.Black, .King)
		case .p: return BoardPiece(.Black, .Pawn)
		case .R: return BoardPiece(.White, .Rook)
		case .N: return BoardPiece(.White, .Knight)
		case .B: return BoardPiece(.White, .Bishop)
		case .Q: return BoardPiece(.White, .Queen)
		case .K: return BoardPiece(.White, .King)
		case .P: return BoardPiece(.White, .Pawn)
		case .x: return nil
		}
	}
	
}

struct Position: ArrayLiteralConvertible, Equatable, CustomStringConvertible {
	
	var row: Int
	var col: Int
	
	init(_ row: Int, _ col: Int) {
		self.row = row
		self.col = col
	}
	
	init(arrayLiteral elements: Int...) {
		self.row = elements[0]
		self.col = elements[1]
	}
	
	init(_ string: String) {
		let chr1: Character = string[0]
		let chr2: String = string[1]
		self.row = 8-Int(chr2)!
		self.col = chr1.unicode()-97
	}
	
	func inBounds() -> Bool {
		return row >= 0 && row < 8 && col >= 0 && col < 8
	}
	
	func rotate() -> Position {
		return [7-row, 7-col]
	}
	
	var description: String {
		return "\(Character(97+col))\(8-row)"
	}
	
}

func ==(lhs: Position, rhs: Position) -> Bool {
	return lhs.row == rhs.row && lhs.col == rhs.col
}

func + (left: Position, right: Position) -> Position {
	var newPos = left
	newPos.row += right.row
	newPos.col += right.col
	return newPos
}

func +=(inout left: Position, right: Position) {
	left.row += right.row
	left.col += right.col
}

struct Move: ArrayLiteralConvertible, Equatable, CustomStringConvertible {
	var from: Position
	var to: Position
	
	init(_ from: Position, _ to: Position) {
		self.from = from
		self.to = to
	}
	
	init(from: Position, to: Position) {
		self.from = from
		self.to = to
	}
	
	init(arrayLiteral elements: Position...) {
		self.from = elements[0]
		self.to = elements[1]
	}
	
	init(_ string: String) {
		self.from = Position(string[0...1])
		self.to = Position(string[2...3])
	}
	
	var description: String {
		return "\(from)\(to)"
	}
	
	func rotate() -> Move {
		return [from.rotate(), to.rotate()]
	}
}

func ==(lhs: Move, rhs: Move) -> Bool {
	return lhs.from == rhs.from && lhs.to == rhs.to
}

struct Entry {
	
	var depth: Int
	var score: Int
	var gamma: Int
	var move: Move?
	
	init(depth: Int, score: Int, gamma: Int, move: Move?) {
		self.depth = depth
		self.score = score
		self.gamma = gamma
		self.move = move
	}
	
}

///////////////////////////////////////////////////////////////////////////////
// MARK: - Board and evaluation tables -
///////////////////////////////////////////////////////////////////////////////

let initial: [[Piece]] = [
	[.r, .n, .b, .q, .k, .b, .n, .r],
	[.p, .p, .p, .p, .p, .p, .p, .p],
	[nil, nil, nil, nil, nil, nil, nil, nil],
	[nil, nil, nil, nil, nil, nil, nil, nil],
	[nil, nil, nil, nil, nil, nil, nil, nil],
	[nil, nil, nil, nil, nil, nil, nil, nil],
	[.P, .P, .P, .P, .P, .P, .P, .P],
	[.R, .N, .B, .Q, .K, .B, .N, .R],
]

let directions: [Piece: [Position]] = [
	.P: [[-1, 0], [-2, 0], [-1, -1], [-1, 1]],
	.N: [[-2, 1], [-1, 2], [1, 2], [2, 1], [2, -1], [1, -2], [-1, -2], [-2, -1]],
	.B: [[-1, 1], [1, 1], [1, -1], [-1, -1]],
	.R: [[-1, 0], [0, 1], [1, 0], [0, -1]],
	.Q: [[-1, 0], [0, 1], [1, 0], [0, -1], [-1, 1], [1, 1], [1, -1], [-1, -1]],
	.K: [[-1, 0], [0, 1], [1, 0], [0, -1], [-1, 1], [1, 1], [1, -1], [-1, -1]]
]

let pst: [Piece: [[Int]]] = [
	.P: [[198, 198, 198, 198, 198, 198, 198, 198],
		[178, 198, 198, 198, 198, 198, 198, 178],
		[178, 198, 198, 198, 198, 198, 198, 178],
		[178, 198, 208, 218, 218, 208, 198, 178],
		[178, 198, 218, 238, 238, 218, 198, 178],
		[178, 198, 208, 218, 218, 208, 198, 178],
		[178, 198, 198, 198, 198, 198, 198, 178],
		[198, 198, 198, 198, 198, 198, 198, 198]],
	
	.B: [[797, 824, 817, 808, 808, 817, 824, 797],
		[814, 841, 834, 825, 825, 834, 841, 814],
		[818, 845, 838, 829, 829, 838, 845, 818],
		[824, 851, 844, 835, 835, 844, 851, 824],
		[827, 854, 847, 838, 838, 847, 854, 827],
		[826, 853, 846, 837, 837, 846, 853, 826],
		[817, 844, 837, 828, 828, 837, 844, 817],
		[792, 819, 812, 803, 803, 812, 819, 792]],
	
	.N: [[627, 762, 786, 798, 798, 786, 762, 627],
		[763, 798, 822, 834, 834, 822, 798, 763],
		[817, 852, 876, 888, 888, 876, 852, 817],
		[797, 832, 856, 868, 868, 856, 832, 797],
		[799, 834, 858, 870, 870, 858, 834, 799],
		[758, 793, 817, 829, 829, 817, 793, 758],
		[739, 774, 798, 810, 810, 798, 774, 739],
		[683, 718, 742, 754, 754, 742, 718, 683]],
	
	.R: [[1258, 1263, 1268, 1272, 1272, 1268, 1263, 1258],
		[1258, 1263, 1268, 1272, 1272, 1268, 1263, 1258],
		[1258, 1263, 1268, 1272, 1272, 1268, 1263, 1258],
		[1258, 1263, 1268, 1272, 1272, 1268, 1263, 1258],
		[1258, 1263, 1268, 1272, 1272, 1268, 1263, 1258],
		[1258, 1263, 1268, 1272, 1272, 1268, 1263, 1258],
		[1258, 1263, 1268, 1272, 1272, 1268, 1263, 1258],
		[1258, 1263, 1268, 1272, 1272, 1268, 1263, 1258]],
	
	.Q: [[2529, 2529, 2529, 2529, 2529, 2529, 2529, 2529],
		[2529, 2529, 2529, 2529, 2529, 2529, 2529, 2529],
		[2529, 2529, 2529, 2529, 2529, 2529, 2529, 2529],
		[2529, 2529, 2529, 2529, 2529, 2529, 2529, 2529],
		[2529, 2529, 2529, 2529, 2529, 2529, 2529, 2529],
		[2529, 2529, 2529, 2529, 2529, 2529, 2529, 2529],
		[2529, 2529, 2529, 2529, 2529, 2529, 2529, 2529],
		[2529, 2529, 2529, 2529, 2529, 2529, 2529, 2529]],
	
	.K: [[60098, 60132, 60073, 60025, 60025, 60073, 60132, 60098],
		[60119, 60153, 60094, 60046, 60046, 60094, 60153, 60119],
		[60146, 60180, 60121, 60073, 60073, 60121, 60180, 60146],
		[60173, 60207, 60148, 60100, 60100, 60148, 60207, 60173],
		[60196, 60230, 60171, 60123, 60123, 60171, 60230, 60196],
		[60224, 60258, 60199, 60151, 60151, 60199, 60258, 60224],
		[60287, 60321, 60262, 60214, 60214, 60262, 60321, 60287],
		[60298, 60332, 60273, 60225, 60225, 60273, 60332, 60298]]
]

///////////////////////////////////////////////////////////////////////////////
// MARK: - Chess logic -
///////////////////////////////////////////////////////////////////////////////

class _Zobrist {
	
	var array = [[Int]]()
	
	init() {
		for _ in 0..<64 {
			var row = [Int]()
			for _ in 0..<13 {
				row.append(Int.random())
			}
			array.append(row)
		}
	}
	
	func hash(board: [[Piece]]) -> Int {
		var hash = 0
		for (row, rowArr) in board.enumerate() {
			for (col, p) in rowArr.enumerate() {
				hash = hash ^ self.array[row*8+col][Int(p.rawValue)]
			}
		}
		return hash
	}
	
}

let Zobrist = _Zobrist()

struct Board: Hashable, CustomStringConvertible {
	
	var board: [[Piece]]
	var score: Int
	var wc, bc: (Bool, Bool)
	var ep, kp: Position?
	var hash: Int
	
	init(board: [[Piece]] = initial, score: Int = 0, wc: (Bool, Bool) = (true, true), bc: (Bool, Bool) = (true, true), ep: Position? = nil, kp: Position? = nil, hash: Int? = nil) {
		self.board = board
		self.score = score
		self.wc = wc
		self.bc = bc
		self.ep = ep
		self.kp = kp
		
		if let hash = hash {
			self.hash = hash
		} else {
			self.hash = Zobrist.hash(board)
		}
	}
	
	var hashValue: Int {
		return self.hash
	}
	
	var description: String {
		var str = ""
		for row in self.board {
			for piece in row {
				str.append(piece.toChar())
			}
			str += "\n"
		}
		return str
	}
	
	subscript (p: Position) -> Piece {
		return self.board[p.row][p.col]
	}
	
	func genMoves() -> [Move] {
		var moves = [Move]()
		for (row, rowArr) in self.board.enumerate() {
			for (col, p) in rowArr.enumerate() {
				if !p.isUpper() { continue }
				for d in directions[p]! {
					let from: Position = [row, col]
					var to = from
					while true {
						to += d
						if !to.inBounds() { break }
						let q: Piece = self[to]
						
						// Castling
						if from == [7, 0] && q == .K && self.wc.0 == true { moves.append([to, (to + [0, -2])]) }
						if from == [7, 7] && q == .K && self.wc.0 == true { moves.append([to, (to + [0, 2])]) }
						
						// No friendly captures
						if q.isUpper() { break }
						
						// Special pawn stuff
						if p == .P && (d == [-1, -1] || d == [-1, 1]) && q.empty() && (to != self.ep && to != self.kp) { break }
						if p == .P && (d == [-1, 0] || d == [-2, 0]) && !q.empty() { break }
						if p == .P && d == [-2, 0] && (from.row < 6 || !self[(from + [-1, 0])].empty()) { break }
						
						// Move it
						moves.append([from, to])
						
						// Stop crawlers from sliding
						if p == .P || p == .N || p == .K { break }
						
						// No sliding after captures
						if q.isLower() { break }
						
					}
				}
			}
		}
		return moves
	}
	
	func rotate() -> Board {
		var newBoard = [[Piece]]()
		for boardRow in Array(self.board.reverse()) {
			var newRow = [Piece]()
			for piece in Array(boardRow.reverse()) {
				newRow.append(piece.switchCase())
			}
			newBoard.append(newRow)
		}
		return Board(board: newBoard, score: -self.score, wc: self.bc, bc: self.wc, ep: self.ep?.rotate(), kp: self.kp?.rotate())
	}
	
	func move(move: Move) -> Board {
		let i = move.from
		let j = move.to
		let p = self[i]
		let q = self[j]
		
		// Copy variables and reset ep and kp
		var board = self.board
		var wc = self.wc
		var bc = self.bc
		var ep: Position? = nil
		var kp: Position? = nil
		let score = self.score + self.value(move)
//		var hash = self.hash
		
		// Actual move
		board[j.row][j.col] = board[i.row][i.col]
		board[i.row][i.col] = .x
		
		// Castling rights
		if i == [7, 0] { wc = (false, wc.1) }
		if i == [7, 7] { wc = (wc.0, false) }
		if j == [0, 0] { bc = (bc.0, false) }
		if j == [0, 7] { bc = (false, bc.1) }
		
		// Castling
		if p == .K {
			wc = (false, false)
			let delta: Position = j + [-i.row, -i.col]
			if delta == [0, 2] || delta == [0, -2] {
				let newkp = i+j
				kp = [newkp.row/2, newkp.col/2]
				board[7][((j.col < i.col) ? 0 : 7)] = .x
				board[kp!.row][kp!.col] = .R
			}
		}
		
		// Special pawn stuff
		if p == .P {
			if j.row == 0 {
				board[j.row][j.col] = .Q
			}
			let delta: Position = j + [-i.row, -i.col]
			if delta == [-2, 0] {
				ep = i + [-1, 0]
			}
			if (delta == [-1, -1] || delta == [-1, 1]) && q.empty() {
				let x = j + [1, 0]
				board[x.row][x.col] = .x
			}
		}
		
		// We rotate the returned position, so it's ready for the next player
		return Board(board: board, score: score, wc: wc, bc: bc, ep: ep, kp: kp).rotate()
	}
	
	func getPstValue(p: Piece, _ pos: Position) -> Int {
		let curPst = pst[p] as [[Int]]!
		return curPst[pos.row][pos.col]
	}
	
	func value(move: Move) -> Int {
		let i = move.from
		let j = move.to
		let p = self[i]
		let q = self[j]
		
		// Actual move
		var score = getPstValue(p, j) - getPstValue(p, i)
		
		// Capture
		if q.isLower() {
			score += getPstValue(p.toUpper(), j)
		}
		
		// Castling check detection
		if let kp = self.kp {
			if abs(j.col-kp.col) < 2 {
				score += getPstValue(.K, j)
			}
		}
		
		// Castling
		if p == .K && abs(i.col-j.col) == 2 {
			let newP = i+j
			score += getPstValue(.R, [newP.row/2, newP.col/2])
			score -= getPstValue(.R, (j.col < i.col) ? [7, 0] : [7, 7])
		}
		
		// Special pawn stuff
		if p == .P {
			if j.row == 0 {
				score += getPstValue(.Q, j) - getPstValue(.P, j)
			}
			if j == self.ep {
				score += getPstValue(.P, j+[1, 0])
			}
		}
		return score
	}
	
	func inCheck(player: Piece) -> Bool {
		for (row, rowArr) in self.board.enumerate() {
			for (col, p) in rowArr.enumerate() {
				if p == player {
					for m in [.R, .B, .N, .K] as [Piece] {
						for d in directions[m]! {
							let from: Position = [row, col]
							var to = from
							while true {
								to += d
								if !to.inBounds() { break }
								let q: Piece = self[to]
								
								if !q.empty() {
									if (q.isLower() == player.isLower()) { break }
									
									if (q.toUpper() == m) || (q.toUpper() == .Q && (m == .R || m == .B)) { return true }
									if (m == .K) && (d == [1, 1] || d == [1, -1]) && (q.toUpper() == .P) { return true }
									else { break }
								}
								
								if p == .P || p == .N || p == .K { break }
								
							}
						}
					}
					return false
				}
			}
		}
		return false
	}
	
}

func ==(lhs: Board, rhs: Board) -> Bool {
	//	if lhs.score != rhs.score { return false }
	//
	//	for (row, rowArr) in enumerate(lhs.board) {
	//		for (col, p) in enumerate(rowArr) {
	//			if p != rhs.board[row][col] {
	//				return false
	//			}
	//		}
	//	}
	//
	//	return true
	return lhs.hashValue == rhs.hashValue
}

///////////////////////////////////////////////////////////////////////////////
// MARK: - Search logic -
///////////////////////////////////////////////////////////////////////////////

class ChessAI {
	
	var board = Board()
	
	var nodes: Int = 0
	var tp = OrderedDictionary<Board, Entry>()
	//	var tp = [Board: Entry]()
	
	func bound(board: Board, _ gamma: Int, _ depth: Int) -> Int {
		//	returns s(pos) <= r < gamma    if s(pos) < gamma
		//	returns s(pos) >= r >= gamma   if s(pos) >= gamma
		nodes++
		
		if nodes % 1000 == 0 {
			print("Searched \(nodes) nodes")
		}
		
		// Look in the table if we have already searched this position before.
		// We use the table value if it was done with at least as deep a search
		// as ours, and the gamma value is compatible.
		let entry = tp[board]
		if let entry = entry {
			if entry.depth >= depth && (entry.score < entry.gamma && entry.score < gamma || entry.score >= entry.gamma && entry.score >= gamma) {
				return entry.score
			}
		}
		
//		// Stop searching if we have won/lost.
//		if abs(board.score) >= MATE_VALUE {
//			return board.score
//		}
		
		// Null move. Is also used for stalemate checking
		let nullscore = depth > 0 ? -bound(board.rotate(), 1-gamma, depth-3) : board.score
		//		let nullscore = depth > 0 ? -MATE_VALUE*3 : board.score
		if nullscore >= gamma {
			return nullscore
		}
		
		// We generate all possible, pseudo legal moves and order them to provoke cuts.
		// At the next level of the tree we are going to minimize the score.
		// This can be shown equal to maximizing the negative score, with a slightly adjusted gamma value.
		var best = -1_000_000
		var bmove: Move? = nil
		let moves = board.genMoves().sort({ board.value($0) > board.value($1) })
		for move in moves {
			// Only moves not resulting in check
			if !board.move(move).inCheck(.k) {
				// We check captures with the value function, as it also contains ep and kp
				if depth <= 0 && board.value(move) < 150 { break }
				let score = -bound(board.move(move), 1-gamma, depth-1)
				if score > best {
					best = score
					bmove = move
				}
				if score >= gamma { break }
			}
		}
		
		// If there are no captures, or just not any good ones, stand pat
		if depth <= 0 && best < nullscore {
			return nullscore
		}
		
//		// Check for stalemate. If best move loses king, but not doing anything would save us. Not at all a perfect check.
//		if depth > 0 && best <= -MATE_VALUE && nullscore > -MATE_VALUE {
//			println("stalemate")
//			best = 0
//		}
		
		// We save the found move together with the score, so we can retrieve it in the play loop.
		// We also trim the transposition table in FILO order.
		// We prefer fail-high moves, as they are the ones we can build our pv from.
		var flag = false
		if let entry = entry {
			if depth >= entry.depth && best >= gamma { flag = true }
		} else {
			flag = true
		}
		
		if flag {
			tp[board] = Entry(depth: depth, score: best, gamma: gamma, move: bmove)
			
			if tp.count > Int(TABLE_SIZE) {
				tp.removeLastEntry()
			}
		}
		
		return best
	}
	
	func search(board: Board, maxn: Int = Int(NODES_SEARCHED)) -> (Move?, Int) {
		// Iterative deepening MTD-bi search
		nodes = 0
		
		var score = 0
		
		// We limit the depth to some constant, so we don't get a stack overflow in the end game.
		for depth in 1..<MAX_DEPTH {
			// The inner loop is a binary search on the score of the position.
			// Inv: lower <= score <= upper
			// However this may be broken by values from the transposition table, as they don't have the same concept of p(score).
			// Hence we just use 'lower < upper - margin' as the loop condition.
			var lower = -1_000_000
			var upper = 1_000_000
			while lower < upper - 3 {
				let gamma = (lower+upper+1)/2
				score = bound(board, gamma, depth)
				if score >= gamma { lower = score }
				else { upper = score }
			}
			
			//			println("Searched \(nodes) nodes. Depth \(depth). Score \(score)(\(lower)/\(upper))")
			
			// We stop deepening if the global N counter shows we have spent too long, or if we have already won the game.
			if nodes >= maxn /*|| abs(score) >= MATE_VALUE*/ { break }
		}
		
		// If the game hasn't finished we can retrieve our move from the transposition table.
		let entry = tp[board]
		return (entry?.move, score)
		
	}
	
}
