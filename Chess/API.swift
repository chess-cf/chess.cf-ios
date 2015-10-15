//
//  API.swift
//  Chess
//
//  Created by Alex Studnicka on 22/12/14.
//  Copyright (c) 2014 Alex Studnička. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import GameKit
import WebKit

//private let SERVER_URL		= "http://10.20.1.18:9080"
//private let SERVER_URL		= "http://macbookpro.local:9080"
private let SERVER_URL			= "https://chess-cf.appspot.com"

private let API_URL				= "\(SERVER_URL)/_ah/api/chess/v1"
private let CHANNEL_API_URL		= "\(SERVER_URL)/_ah/channel/jsapi"

class LoginInfo {
	let token					: String!
	let username				: String!
	
	init(token: String, username: String) {
		self.token				= token
		self.username			= username
	}
	
	init?(json: JSON) {
		if let token = json["token"].string {
			self.token				= token
			self.username			= json["username"].stringValue
			
			let ud = NSUserDefaults.standardUserDefaults()
			ud.setValue(self.token, forKey: "token")
			ud.setValue(self.username, forKey: "username")
			ud.synchronize()
		} else {
			self.token				= nil
			self.username			= nil
			return nil
		}
	}
	
	class func fromDefaults() -> LoginInfo? {
		let ud = NSUserDefaults.standardUserDefaults()
		if let token = ud.stringForKey("token") {
			return LoginInfo(token: token, username: ud.stringForKey("username")!)
		}
		return nil
	}
	
}

class GameInfo: CustomStringConvertible {
	let uid						: Int
	let dateCreated				: NSDate
	let whitePlayer				: String
	let blackPlayer				: String
	var isAI					: Bool
	let color					: Player
	let status					: Int
	
	init(json: JSON) {
		self.uid				= json["uid"].intValue
		self.dateCreated		= NSDate(timeIntervalSince1970: NSTimeInterval(json["dateCreated"].intValue))
		
		self.isAI				= false
		
		if json["whitePlayer"].stringValue == "__AI__" {
			self.whitePlayer	= ~"COMPUTER"
			self.isAI			= true
		} else {
			self.whitePlayer	= json["whitePlayer"].stringValue
		}
		
		if json["blackPlayer"].stringValue == "__AI__" {
			self.blackPlayer	= ~"COMPUTER"
			self.isAI			= true
		} else {
			self.blackPlayer	= json["blackPlayer"].stringValue
		}
		
		self.color				= Player(string: json["color"].stringValue)
		self.status				= json["status"].intValue
		
	}
	
	var description: String {
		return "GameInfo { \(uid) / \(dateCreated) / \(whitePlayer) x \(blackPlayer)) }"
	}
	
}

class DetailGameInfo {
	var board					: [[BoardPiece?]]
	var hints					: [Move]?
	var opponent_played			: Bool
	var channelToken			: String
	
	init(board: [[BoardPiece?]], hints: [Move]? = nil, opponent_played: Bool = true, channelToken: String = "") {
		self.board = board
		self.hints = hints
		self.opponent_played = opponent_played
		self.channelToken = channelToken
	}
	
	init(json: JSON) {
		self.opponent_played	= json["opponent_played"].boolValue
		self.channelToken		= json["channelToken"].stringValue
		
		// ------------------------------------------------------------------
		
		var tmpBoard			= [[BoardPiece?]]()
		
		var boardStr = json["board"].stringValue
		boardStr = boardStr.replace(" ", withString: "")
		let board = boardStr.componentsSeparatedByString("\n")[2..<10]
		var row = 0
		for rowStr in board {
			var col = 0
			var boardRow = [BoardPiece?]()
			for char in rowStr.characters {
				let piece = BoardPiece(char: String(char), isBlack: false)
				boardRow.append(piece)
				col++
			}
			tmpBoard.append(boardRow)
			row++
		}
		
		self.board				= tmpBoard
		
		// ------------------------------------------------------------------
		
		var tmpHints			= [Move]()
		for (_, subJson): (String, JSON) in json["hints"] {
			tmpHints.append(Move(subJson.stringValue))
		}
		self.hints				= tmpHints
	}
}

class NewGameResponse {
	let info					: GameInfo
	let detailInfo				: DetailGameInfo
	
	init(json: JSON) {
		self.info				= GameInfo(json: json["info"])
		self.detailInfo			= DetailGameInfo(json: json["detailInfo"])
	}
}

class MoveResponse {
	let opponent_played			: Bool
	let w_check					: Bool?
	let b_check					: Bool?
	let move						: Move?
	let hints					: [Move]?
	
	init(json: JSON) {
		self.opponent_played	= json["opponent_played"].boolValue
		
		self.w_check			= json["w_check"].bool
		self.b_check			= json["b_check"].bool
		
		if let _ = json["move"].string {
			self.move			= Move(json["move"].stringValue)
		} else {
			self.move			= nil
		}
		
		if let _ = json["hints"].array {
			var tmpHints		= [Move]()
			for (_, subJson): (String, JSON) in json["hints"] {
				tmpHints.append(Move(subJson.stringValue))
			}
			self.hints			= tmpHints
		} else {
			self.hints			= nil
		}
	}
}

class FriendInfo: CustomStringConvertible {
	let uid						: Int
	let username				: String
	var isFriend				: Bool
	var requested				: Bool
	
	init(json: JSON) {
		self.uid				= json["uid"].intValue
		self.username			= json["username"].stringValue
		self.isFriend			= json["isFriend"].boolValue
		self.requested			= json["requested"].boolValue
	}
	
	var description: String {
		return "FriendInfo { \(uid) / \(username) / isFriend=\(isFriend), requested=\(requested) }"
	}
}

class OpenChannel {
	var game_uid				: Int
	var channelToken			: String
	
	init(game_uid: Int, channelToken: String) {
		self.game_uid			= game_uid
		self.channelToken		= channelToken
	}
}

class _API: NSObject, WKScriptMessageHandler {
	
	var loginInfo: LoginInfo?
	var openedChannel: OpenChannel?
	
	var requestedFriends: [FriendInfo]? {
		didSet {
			let tabBarVC = UIApp.window?.rootViewController as! UITabBarController
			let navC = tabBarVC.viewControllers![1] as! UINavigationController
			if requestedFriends!.count > 0 {
				navC.tabBarItem.badgeValue = String(requestedFriends!.count)
			} else {
				navC.tabBarItem.badgeValue = nil
			}
		}
	}
	var friends: [FriendInfo]?
	
	private var webView: WKWebView!
	
	// MARK: - Init
	
	private override init() {
		// Make init private, because it's singleton
	}
	
	// MARK: - Channels
	
	func setupChannelWebView(window: UIWindow) {
		
		let contentController = WKUserContentController()
		for name in ["onopen", "onmessage", "onerror", "onclose"] {
			contentController.addScriptMessageHandler(self, name: name)
		}
		
		let config = WKWebViewConfiguration()
		config.userContentController = contentController
		
		webView = WKWebView(frame: CGRectZero, configuration: config)
		webView.hidden = true
		window.addSubview(webView)
		
		webView.loadHTMLString("<html><head></head><body><script src=\"\(CHANNEL_API_URL)\"></script></body></html>", baseURL: NSURL(string: SERVER_URL))
		
	}
	
	func openChannel(game_uid: Int, channelToken: String) {
		var script = webView.loading ? "window.onload = function() {" : ""
		script    += "var channel = new goog.appengine.Channel('\(channelToken)');"
		script    += "var socket = channel.open();"
		script    += "socket.onopen = function() { webkit.messageHandlers.onopen.postMessage(null) };"
		script    += "socket.onmessage = function(message) { webkit.messageHandlers.onmessage.postMessage(message) };"
		script    += "socket.onerror = function(error) { webkit.messageHandlers.onerror.postMessage(error) };"
		script    += "socket.onclose = function() { webkit.messageHandlers.onclose.postMessage(null) };"
		script    += "window.channelSocket = socket;"
		script    += webView.loading ? "}": ""
		webView.evaluateJavaScript(script, completionHandler: nil)
		openedChannel = OpenChannel(game_uid: game_uid, channelToken: channelToken)
	}
	
	func closeChannel() {
		webView.evaluateJavaScript("window.channelSocket.close();", completionHandler: nil)
		openedChannel = nil
	}
	
	// MARK: - WKScriptMessageHandler
	
	func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
		switch message.name {
		case "onopen":
			print("socket onopen")
		case "onclose":
			print("socket onclose")
		case "onmessage":
			print("socket message: \(message.body)")
		case "onerror":
			print("onerror: \(message.body)")
			let error = message.body as! NSDictionary
			var code: Int
			if let codeStr = error["code"] as? String {
				code = Int(codeStr) ?? -1
			} else {
				code = error["code"] as! Int
			}
			if code == 400 || code == 401 {
				resetChannelToken(openedChannel!.game_uid) { newToken in
					print("newToken: \(newToken)")
					if let token = newToken {
						self.openChannel(self.openedChannel!.game_uid, channelToken: token)
						self.openedChannel?.channelToken = token
					} else {
						print("resetToken fail")
					}
				}
			} else {
				let description = error["description"] as? String?
				print("socket error: \(error) - \(description)")
			}
		default:
			break
		}
	}
	
	// MARK: - Token
	
	func getToken() -> String {
		if let loginInfo = self.loginInfo {
			return loginInfo.token
		}
		
		if let loginInfo = LoginInfo.fromDefaults() {
			self.loginInfo = loginInfo
			return loginInfo.token
		}
		
		return ""
	}
	
	// MARK: - API calls
	
	func login(username: String, password: String, completionHandler: (error: String?) -> Void) {
		Alamofire.request(.GET, "\(API_URL)/login", parameters: ["username": username, "password": password])
			.response { (request, response, data, error) in
				if let actualData = data {
					let json = JSON(data: actualData)
					if let loginInfo = LoginInfo(json: json) {
						self.loginInfo = loginInfo
						completionHandler(error: nil)
					} else {
						if let error = json["error"]["message"].string {
							completionHandler(error: error)
						} else {
							completionHandler(error: "SERVER_ERROR")
						}
					}
				} else {
					completionHandler(error: "SERVER_ERROR")
				}
		}
	}
	
	func listGames(completionHandler: ([GameInfo]?) -> Void) {
		Alamofire.request(.GET, "\(API_URL)/games", parameters: ["token": getToken()])
		.response { (request, response, data, error) in
			if let actualData = data {
				let json = JSON(data: actualData)
				let items = json["items"]
				
				var games = [GameInfo]()
				for (_, subJson): (String, JSON) in items {
					games.append(GameInfo(json: subJson))
				}
				
				completionHandler(games)
			} else {
				completionHandler(nil)
			}
		}
	}
	
	func newGame(color: String, opponent: String, friend: Int? = nil, completionHandler: (NewGameResponse?) -> Void) {
		var params: [String: AnyObject] = ["token": getToken(), "color": color, "opponent": opponent]
		if friend != nil { params["friend"] = friend }
		
		Alamofire.request(.GET, "\(API_URL)/newgame", parameters: params)
			.response { (request, response, data, error) in
				if let actualData = data {
					let json = JSON(data: actualData)
					let response = NewGameResponse(json: json)
					completionHandler(response)
				} else {
					completionHandler(nil)
				}
		}
	}
	
	func gameInfo(uid: Int, completionHandler: (DetailGameInfo?) -> Void) {
		Alamofire.request(.GET, "\(API_URL)/game/\(uid)", parameters: ["token": getToken()])
			.response { (request, response, data, error) in
				if let actualData = data {
					let json = JSON(data: actualData)
					let gameInfo = DetailGameInfo(json: json)
					completionHandler(gameInfo)
				} else {
					completionHandler(nil)
				}
		}
	}
	
	func gameMove(uid: Int, move: String, completionHandler: ((Void) -> Void)? = nil) {
		Alamofire.request(.GET, "\(API_URL)/game/\(uid)/move", parameters: ["token": getToken(), "move": move])
			.response { (request, response, data, error) in
				if let handler = completionHandler {
					handler()
				}
		}
	}
	
	func resetChannelToken(uid: Int, completionHandler: (String?) -> Void) {
		Alamofire.request(.GET, "\(API_URL)/game/\(uid)/resetChannelToken", parameters: ["token": getToken()])
			.response { (request, response, data, error) in
				if let actualData = data {
					let json = JSON(data: actualData)
					completionHandler(json["channelToken"].string)
				} else {
					completionHandler(nil)
				}
		}
	}
	
	func gameLeave(uid: Int, completionHandler: (Void) -> Void) {
		Alamofire.request(.GET, "\(API_URL)/game/\(uid)/leave", parameters: ["token": getToken()])
			.response { (request, response, data, error) in
				completionHandler()
		}
	}
	
	func listFriends(completionHandler: (NSError?) -> Void) {
		Alamofire.request(.GET, "\(API_URL)/friends", parameters: ["token": getToken()])
			.response { (request, response, data, error) in
				if let actualData = data {
					let json = JSON(data: actualData)
					
					let requestedJSON = json["requested"]
					var requestedFriends = [FriendInfo]()
					for (_, subJson): (String, JSON) in requestedJSON {
						requestedFriends.append(FriendInfo(json: subJson))
					}
					self.requestedFriends = requestedFriends
					
					let friendsJSON = json["friends"]
					var friends = [FriendInfo]()
					for (_, subJson): (String, JSON) in friendsJSON {
						friends.append(FriendInfo(json: subJson))
					}
					self.friends = friends
					
					completionHandler(nil)
				} else {
					completionHandler(error)
				}
		}
	}
	
	func searchFriends(query: String, completionHandler: ([FriendInfo]?) -> Void) {
		Alamofire.request(.GET, "\(API_URL)/searchFriends", parameters: ["token": getToken(), "query": query])
			.response { (request, response, data, error) in
				if let actualData = data {
					let json = JSON(data: actualData)
					let friendsJSON = json["friends"]
					
					var friends = [FriendInfo]()
					for (_, subJson): (String, JSON) in friendsJSON {
						friends.append(FriendInfo(json: subJson))
					}
					
					completionHandler(friends)
				} else {
					completionHandler(nil)
				}
		}
	}
	
	func sendRequest(friendID: Int, completionHandler: (Void) -> Void) {
		Alamofire.request(.GET, "\(API_URL)/friend/\(friendID)/sendRequest", parameters: ["token": getToken()])
			.response { (request, response, data, error) in
				completionHandler()
		}
	}
	
	func requestResponse(friendID: Int, action: String, completionHandler: (Void) -> Void) {
		Alamofire.request(.GET, "\(API_URL)/friend/\(friendID)/requestResponse", parameters: ["token": getToken(), "action": action])
			.response { (request, response, data, error) in
				completionHandler()
		}
	}
	
	func unfriend(friendID: Int, completionHandler: (Void) -> Void) {
		Alamofire.request(.GET, "\(API_URL)/friend/\(friendID)/unfriend", parameters: ["token": getToken()])
			.response { (request, response, data, error) in
				completionHandler()
		}
	}
	
}

let API = _API()
