//
//  GameViewController.swift
//  Chess
//
//  Created by Alex Studnička on 25.10.14.
//  Copyright (c) 2014 Alex Studnička. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController {
	
	var game: GameInfo!
	var detailGame: DetailGameInfo!
//	var aiGame = true
	var ai: ChessAI!
	var waiting = false
	
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var overlayView: UIView!
	@IBOutlet weak var waitingView: UIView!
	@IBOutlet weak var resultView: UIView!
	
	@IBOutlet weak var scnView: SCNView!
	let piecesScene = SCNScene(named: "art.scnassets/chess_pieces.dae")!
	var board: SCNNode!
	var squares: SCNNode!
	var lightNode: SCNNode!
	
	var activePiece: (piece: BoardPiece, pos: Position)!
	var helpers = [(Position, MoveType)]()
	
    override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = "\(game.whitePlayer) × \(game.blackPlayer)"
		
		self.activityIndicator.alpha = 1
		self.activityIndicator.startAnimating()
		
		if game.isAI {
			
			dispatch_after(0.1) {
				
				self.ai = ChessAI()
				
				var initialBoard = [[BoardPiece?]]()
				for initialRow in self.ai.board.board {
					var newRow = [BoardPiece?]()
					for piece in initialRow {
						newRow.append(piece.toBoardPiece())
					}
					initialBoard.append(newRow)
				}
				
				var hints = [Move]()
				for hintMove in self.ai.board.genMoves() {
					if !self.ai.board.move(hintMove).inCheck(.k) {
						hints.append(hintMove)
					}
				}
				
				self.detailGame = DetailGameInfo(board: initialBoard, hints: hints)
				self.createScene()
				
			}
			
		} else {
			API.gameInfo(game.uid, completionHandler: { loadedGameInfo in
				self.detailGame = loadedGameInfo
				API.openChannel(self.game.uid, channelToken: self.detailGame.channelToken)
				self.createScene()
			})
		}
		
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		API.closeChannel()
	}
	
	// --------------------------------
	// MARK: - Create scene
	
	func createScene() {
		
		let scene = SCNScene()
		
		let cameraSphere = SCNNode()
		let cameraNode = SCNNode()
		cameraNode.camera = SCNCamera()
		cameraNode.camera?.yFov = 20
		cameraNode.position = SCNVector3(x: 0, y: 0, z: 45)
		cameraSphere.eulerAngles = SCNVector3(x: Float(M_PI/6), y: 0, z: 0)
		cameraSphere.addChildNode(cameraNode)
		scene.rootNode.addChildNode(cameraSphere)
		
		let lightSphere = SCNNode()
		lightNode = SCNNode()
		lightNode.light = SCNLight()
		lightNode.light!.type = SCNLightTypeSpot
		lightNode.position = SCNVector3(x: 0, y: 0, z: 16)
		lightSphere.eulerAngles = SCNVector3(x: Float(M_PI/8), y: 0, z: 0)
		lightSphere.addChildNode(lightNode)
		scene.rootNode.addChildNode(lightSphere)
		
		let ambientLightNode = SCNNode()
		ambientLightNode.light = SCNLight()
		ambientLightNode.light!.type = SCNLightTypeAmbient
		ambientLightNode.light!.color = UIColor.lightGrayColor()
		scene.rootNode.addChildNode(ambientLightNode)
		
		// --------------------------------
		
		let boardMaterial = SCNMaterial()
		boardMaterial.diffuse.contents = UIImage(named: "art.scnassets/board.jpg")
		
		let woodMaterial = SCNMaterial()
		woodMaterial.diffuse.contents = UIImage(named: "art.scnassets/wood.jpg")
		woodMaterial.diffuse.wrapS = .Repeat
		woodMaterial.diffuse.wrapT = .Repeat
		
		let floor = SCNFloor()
		let floorNode = SCNNode(geometry: floor)
		floorNode.geometry?.firstMaterial = SCNMaterial()
		floorNode.geometry?.firstMaterial?.doubleSided = true
		floorNode.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 229/255, green: 206/255, blue: 183/255, alpha: 1)
		floorNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: Float(M_PI_2))
		scene.rootNode.addChildNode(floorNode)
		
		board = SCNNode(geometry: SCNBox(width: 8.5, height: 8.5, length: 0.5, chamferRadius: 0.05))
		board.geometry?.materials = [boardMaterial, woodMaterial, woodMaterial, woodMaterial, woodMaterial, woodMaterial]
		scene.rootNode.addChildNode(board)
		
		// --------------------------------
		
		squares = SCNNode()
		board.addChildNode(squares)
		
		for (var row = 0; row < 8; row++) {
			for (var col = 0; col < 8; col++) {
				let square = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 0.1, chamferRadius: 0))
				square.name = "Square-\(row)-\(col)"
				let position = getPositionForRow(row, col: col)
				square.position = SCNVector3(x: position.x, y: position.y, z: 0.25)
				square.geometry?.firstMaterial = SCNMaterial()
				square.geometry?.firstMaterial?.transparency = 0
				square.geometry?.firstMaterial?.diffuse.contents = UIColor.blueColor()
				squares.addChildNode(square)
			}
		}
		
		// --------------------------------
		
		scnView.scene = scene
		scnView.playing = true
//		scnView.loops = true
//		scnView.allowsCameraControl = true
//		scnView.showsStatistics = true
		scnView.backgroundColor = UIColor.darkGrayColor()
		scnView.antialiasingMode = .Multisampling4X
		
		let tapGesture = UITapGestureRecognizer(target: self, action: "handleTap:")
		var gestureRecognizers = scnView.gestureRecognizers ?? []
		gestureRecognizers.append(tapGesture)
		scnView.gestureRecognizers = gestureRecognizers
		
		// --------------------------------
		
//		board.runAction(SCNAction.repeatActionForever(SCNAction.rotateByAngle(CGFloat(M_PI), aroundAxis: SCNVector3(x: 0, y: 0, z: 1), duration: 10)))
		
		gameBoardArray = detailGame.board
		drawBoard()
		
		// --------------------------------
		
		UIView.animateWithDuration(0.5, delay: 1, options: [], animations: {
			self.activityIndicator.alpha = 0
			self.scnView.alpha = 1
			
			if !self.detailGame.opponent_played {
				self.waiting = true
				self.overlayView.alpha = 1
				self.move(Position(0, 0), user: true)
			}
			
		}) { completed in
			self.scnView.playing = false
		}
		
	}
	
    // --------------------------------
    // MARK: - Tap
	
    func handleTap(gestureRecognize: UIGestureRecognizer) {
        let p = gestureRecognize.locationInView(scnView)
        if let hitResults = scnView.hitTest(p, options: nil) as NSArray! {
//			println("hitResults: \(hitResults)")
			var touchedSquare = false
			for result in hitResults {
//				println("result: \(result)")
				if result.node.name?.hasPrefix("Square") != true { continue }
				touchedSquare = true
				
				var row = -1, col = -1
				let comps = result.node.name?.componentsSeparatedByString("-")
				if let comps = comps {
					if comps.count > 2 {
						row = Int(comps[1])!
						col = Int(comps[2])!
					}
				}
				
				let position = Position(row, col)
				var moved = false
				
				for move in helpers {
					if move.0 == position {
						self.move(position, user: true)
						moved = true
						break
					}
				}
				
				if !moved {
					if let piece = gameBoardArray[row][col] {
						if piece.color == game.color {
							
							resetHelperLights()
//							lightNode.runAction(SCNAction.moveTo(SCNVector3(x: result.node.position.x, y: result.node.position.y, z: 2), duration: 0.25))
							
							activePiece = (piece, position)
							
							playSound(SOUND_CLICK)
							
							if let hints = detailGame.hints{
								for hint in hints {
									if hint.from == position {
										if let _ = getPiece(hint.to) {
											addHelper(hint.to, type: .Take)
										} else {
											addHelper(hint.to, type: .Move)
										}
									}
								}
							}
							
						} else {
							resetMove()
						}
					} else {
						resetMove()
					}
				}

			}

			if !touchedSquare {
				resetMove()
			}
        }
    }
	
	// --------------------------------
	// MARK: - Helpers
	
	func resetHelperLights() {
//		for light in helperLights.childNodes as [SCNNode] {
////			light.runAction(SCNAction.sequence([SCNAction.fadeOutWithDuration(0.25), SCNAction.removeFromParentNode()]))
//			light.removeFromParentNode()
//		}
		SCNTransaction.begin()
		SCNTransaction.setAnimationDuration(0.25)
		for square in squares.childNodes {
//			square.geometry?.firstMaterial?.diffuse.contents = UIColor.clearColor()
			square.geometry?.firstMaterial?.transparency = 0
		}
		SCNTransaction.commit()
		
		helpers = [(Position, MoveType)]()
	}
	
	func resetMove() {
		resetHelperLights()
		activePiece = nil
//		lightNode.runAction(SCNAction.moveTo(SCNVector3(x: 0, y: 0, z: 15), duration: 0.25))
	}
	
	func addHelper(pos: Position, type: MoveType) {
//		let position = getPositionForRow(row, col: col)
//		let helperLightNode = SCNNode()
//		helperLightNode.light = SCNLight()
//		helperLightNode.light!.type = SCNLightTypeSpot
//		helperLightNode.light!.color = UIColor.blueColor()
//		helperLightNode.position = SCNVector3(x: position.x, y: position.y, z: 1)
//		helperLights.addChildNode(helperLightNode)
		
		let square = board.childNodeWithName("Square-\(pos.row)-\(pos.col)", recursively: true)
		
		switch type {
		case .Move:
			square?.geometry?.firstMaterial?.diffuse.contents = UIColor.blueColor()
		case .Take:
			square?.geometry?.firstMaterial?.diffuse.contents = UIColor.redColor()
		}
		
		SCNTransaction.begin()
		SCNTransaction.setAnimationDuration(0.25)
//		square?.geometry?.firstMaterial?.diffuse.contents = UIColor.blueColor()
		square?.geometry?.firstMaterial?.transparency = 0.5
		SCNTransaction.commit()
		
		helpers.append(pos, type)
	}
	
	func getPositionForRow(row: Int, col: Int) -> (x: Float, y: Float) {
		return (-3.33 + Float(col)*0.95, -3.33 + Float(7-row)*0.95)
	}
	
	func getPosition(pos: Position) -> (x: Float, y: Float) {
		return getPositionForRow(pos.row, col: pos.col)
	}
	
	func modelForPieceType(pieceType: PieceType) -> SCNNode {
		var name: String
		var z: Float
		switch pieceType {
		case .Rook:
			name = "Rook"
			z = 0.7
		case .Knight:
			name = "Knight"
			z = 0.75
		case .Bishop:
			name = "Bishop"
			z = 0.8
		case .Queen:
			name = "Queen"
			z = 1.1
		case .King:
			name = "King"
			z = 1.1
		case .Pawn:
			name = "Pawn"
			z = 0.6
		}
		let node = piecesScene.rootNode.childNodeWithName(name, recursively: true)!
		var newNode: SCNNode
		if let geometry = node.geometry {
			newNode = SCNNode(geometry: geometry.copy() as? SCNGeometry)
		} else if pieceType == .Knight {
			let group = piecesScene.rootNode.childNodeWithName(name, recursively: true)!
			newNode = SCNNode()
			let part1 = group.childNodes[0].childNodes[0] 
			newNode.addChildNode(SCNNode(geometry: part1.geometry?.copy() as? SCNGeometry))
			let part2 = group.childNodes[0].childNodes[1] 
			newNode.addChildNode(SCNNode(geometry: part2.geometry?.copy() as? SCNGeometry))
		} else {
			newNode = SCNNode()
		}
		newNode.position = SCNVector3(x: 0, y: 0, z: z)
		newNode.scale = SCNVector3(x: 0.0033, y: 0.0033, z: 0.0033)
		newNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: Float(M_PI_2))
		return newNode
	}
	
	func modelForPiece(piece: BoardPiece) -> SCNNode {
		var node: SCNNode
		switch piece.color {
		case .White:
			node = modelForPieceType(piece.type)
			
			// recolor
			let whitePiece = piecesScene.rootNode.childNodeWithName("White", recursively: true)!
			node.geometry?.firstMaterial = whitePiece.geometry?.firstMaterial
			
			// rotate
			node.eulerAngles = SCNVector3(x: Float(M_PI_2), y: 0, z: Float(M_PI))
		case .Black:
			node = modelForPieceType(piece.type)
		}
		return node
	}
	
	func drawBoard() { //gameBoardArray
		let array = gameBoardArray
		for row in 0..<array.count {
			for col in 0..<array[row].count {
				if let piece = array[row][col] {
					let node = modelForPiece(piece)
					let position = getPositionForRow(row, col: col)
					node.position = SCNVector3(x: position.x, y: position.y, z: node.position.z)
					board.addChildNode(node)
					gameBoardArray[row][col] = BoardPiece(piece.color, piece.type, node)
				}
			}
		}
	}
	
	// --------------------------------
	// MARK: - Move
	
	func move(pos: Position, user: Bool) {
		
		var originalPiece: BoardPiece?
		
		if !waiting {
			
			if activePiece == nil {
				print("NO_PIECE")
				return
			}
			
			let piece = activePiece.piece
			let activePos = activePiece.pos
			
			// Piece being taken
			originalPiece = getPiece(pos)
			
			// Castling
			var castlingMove: Move?
			if activePiece.piece.type == .King {
				if game.color == .Black {
					if piece.color == .Black && activePos == Position(7, 3) {
						if pos == Position(7, 1) {
							castlingMove = Move(from: Position(7, 0), to: Position(7, 2))
						} else if pos == Position(7, 5) {
							castlingMove = Move(from: Position(7, 7), to: Position(7, 4))
						}
					} else if piece.color == .White && activePos == Position(0, 3) {
						if pos == Position(0, 1) {
							castlingMove = Move(from: Position(0, 0), to: Position(0, 2))
						} else if pos == Position(0, 5) {
							castlingMove = Move(from: Position(0, 7), to: Position(0, 4))
						}
					}
				} else {
					if piece.color == .White && activePos == Position(7, 4) {
						if pos == Position(7, 2) {
							castlingMove = Move(from: Position(7, 0), to: Position(7, 3))
						} else if pos == Position(7, 6) {
							castlingMove = Move(from: Position(7, 7), to: Position(7, 5))
						}
					} else if piece.color == .Black && activePos == Position(0, 4) {
						if pos == Position(0, 2) {
							castlingMove = Move(from: Position(0, 0), to: Position(0, 3))
						} else if pos == Position(0, 6) {
							castlingMove = Move(from: Position(0, 7), to: Position(0, 5))
						}
					}
				}
			}
			if let move = castlingMove {
				let newRookPos = getPosition(move.to)
				let rookPiece = getPiece(move.from)
				let model = rookPiece!.model
				
				SCNTransaction.begin()
				SCNTransaction.setAnimationDuration(0.25)
				model.position = SCNVector3(x: newRookPos.x, y: newRookPos.y, z: model.position.z)
				SCNTransaction.commit()
				
				gameBoardArray[move.from.row][move.from.col] = nil
				gameBoardArray[move.to.row][move.to.col] = rookPiece
			}
			
			// En passant
//			var en_passant = false
			if piece.type == .Pawn && pos.col != activePos.col && originalPiece == nil {
//				en_passant = true
				let enPassantPos = Position(activePos.row, pos.col)
				if let piece = getPiece(enPassantPos) {
					piece.model.removeFromParentNode()
				}
			}
			
			// Promotion
			var promotion = false
			if piece.type == .Pawn {
				if game.color == .Black {
					if piece.color == .Black && pos.row == 0 {
						promotion = true
					} else if piece.color == .White && pos.row == 7 {
						promotion = true
					}
				} else {
					if piece.color == .White && pos.row == 0 {
						promotion = true
					} else if piece.color == .Black && pos.row == 7 {
						promotion = true
					}
				}
			}
			if (promotion) {
				// TODO: Promotion
				print("Promotion")
//				piece.type = .Queen
			}
		
			// Actual move
			let position = getPosition(pos)
			let model = activePiece.piece.model
			
			SCNTransaction.begin()
			SCNTransaction.setAnimationDuration(0.25)
			model.position = SCNVector3(x: position.x, y: position.y, z: model.position.z)
			SCNTransaction.commit()
			
			// Taking
			if let actualOriginalPiece = originalPiece {
				actualOriginalPiece.model.removeFromParentNode()
			}
			
			gameBoardArray[activePiece.pos.row][activePiece.pos.col] = nil
			gameBoardArray[pos.row][pos.col] = activePiece.piece
			
			resetHelperLights()
			
			waiting = false
			
		}
		
		if user {
			
			//var data: [String: AnyObject]!
			
			/*let handler = { (response: MoveResponse?) -> Void in
				
				if let response = response {
					
					self.waiting = !response.opponent_played
					
					if response.opponent_played {
						
						if let hints = response.hints {
							if hints.count > 0 {
								self.detailGame.hints = hints
							} else {
								self.detailGame.hints = nil
							}
						} else {
							self.detailGame.hints = nil
						}
						
						if response.move != nil && response.b_check! {
							playSound(SOUND_CHECK)
						}
						
						if let move = response.move {
							
							if let piece = getPiece(move.from) {
								self.activePiece = (piece, move.from)
								self.move(move.to, user: false)
							} else {
								println("piece error")
							}
							
						}
						
						if response.move == nil {
							playSound(SOUND_WIN)
						} else if self.detailGame.hints == nil {
							playSound(SOUND_LOSS)
						}
						
						if response.move == nil && self.detailGame.hints != nil && response.w_check! {
							playSound(SOUND_CHECK_2)
						}
						
					} else {
						dispatch_after(2) {
							self.move(pos, user: user)
						}
					}
					
				} else {
					println("move error")
				}
				
				if !self.waiting {
					UIView.animateWithDuration(0.25) {
						self.overlayView.alpha = 0
					}
				}
				
			}*/
			
			
			UIView.animateWithDuration(0.25) {
				self.overlayView.alpha = 1
			}
			
			if !waiting {
				if originalPiece != nil {
					playSound(SOUND_CAPTURE)
				} else {
					playSound(SOUND_MOVE)
				}
				
				let move = Move(activePiece.pos, pos)
				
				if game.isAI {
					
					dispatch_after(0.25) {
						
						self.ai.board = self.ai.board.move(move)
						
						let result = self.ai.search(self.ai.board)
						if let aiMove: Move = result.0 {
							self.ai.board = self.ai.board.move(aiMove)
							
							let rotatedMove = aiMove.rotate()
							
							if let piece = getPiece(rotatedMove.from) {
								self.activePiece = (piece, rotatedMove.from)
								self.move(rotatedMove.to, user: false)
							} else {
								print("piece error")
							}
							
						}
						
						var hints = [Move]()
						for hintMove in self.ai.board.genMoves() {
							if !self.ai.board.move(hintMove).inCheck(.k) {
								hints.append(hintMove)
							}
						}
						self.detailGame.hints = hints
						
						UIView.animateWithDuration(0.25) {
							self.overlayView.alpha = 0
						}
						
					}
					
				} else {
					
					API.gameMove(game.uid, move: move.description)
					
				}
				
			}
			
		} else {
			if originalPiece != nil {
				playSound(SOUND_CAPTURE_2)
			} else {
				playSound(SOUND_MOVE_2)
			}
		}
		
	}

}
