//
//  Sounds.swift
//  Chess
//
//  Created by Alex Studnicka on 23/12/14.
//  Copyright (c) 2014 Alex Studnička. All rights reserved.
//

import Foundation
import AudioToolbox

var SOUND_CLICK: SystemSoundID = 0
var SOUND_ILLEGAL: SystemSoundID = 0
var SOUND_MOVE: SystemSoundID = 0
var SOUND_CAPTURE: SystemSoundID = 0
var SOUND_SPECIAL_MOVE: SystemSoundID = 0
var SOUND_CHECK: SystemSoundID = 0
var SOUND_MOVE_2: SystemSoundID = 0
var SOUND_CAPTURE_2: SystemSoundID = 0
var SOUND_SPECIAL_MOVE_2: SystemSoundID = 0
var SOUND_CHECK_2: SystemSoundID = 0
var SOUND_WIN: SystemSoundID = 0
var SOUND_DRAW: SystemSoundID = 0
var SOUND_LOSS: SystemSoundID = 0
var SOUND_NEW_GAME: SystemSoundID = 0

func initializeSounds() {
	AudioServicesCreateSystemSoundID(NSBundle.mainBundle().URLForResource("click", withExtension: "wav")!, &SOUND_CLICK)
	AudioServicesCreateSystemSoundID(NSBundle.mainBundle().URLForResource("illegal", withExtension: "wav")!, &SOUND_ILLEGAL)
	AudioServicesCreateSystemSoundID(NSBundle.mainBundle().URLForResource("move", withExtension: "wav")!, &SOUND_MOVE)
	AudioServicesCreateSystemSoundID(NSBundle.mainBundle().URLForResource("capture", withExtension: "wav")!, &SOUND_CAPTURE)
	AudioServicesCreateSystemSoundID(NSBundle.mainBundle().URLForResource("special", withExtension: "wav")!, &SOUND_SPECIAL_MOVE)
	AudioServicesCreateSystemSoundID(NSBundle.mainBundle().URLForResource("check", withExtension: "wav")!, &SOUND_CHECK)
	AudioServicesCreateSystemSoundID(NSBundle.mainBundle().URLForResource("move2", withExtension: "wav")!, &SOUND_MOVE_2)
	AudioServicesCreateSystemSoundID(NSBundle.mainBundle().URLForResource("capture2", withExtension: "wav")!, &SOUND_CAPTURE_2)
	AudioServicesCreateSystemSoundID(NSBundle.mainBundle().URLForResource("special2", withExtension: "wav")!, &SOUND_SPECIAL_MOVE_2)
	AudioServicesCreateSystemSoundID(NSBundle.mainBundle().URLForResource("check2", withExtension: "wav")!, &SOUND_CHECK_2)
	AudioServicesCreateSystemSoundID(NSBundle.mainBundle().URLForResource("win", withExtension: "wav")!, &SOUND_WIN)
	AudioServicesCreateSystemSoundID(NSBundle.mainBundle().URLForResource("draw", withExtension: "wav")!, &SOUND_DRAW)
	AudioServicesCreateSystemSoundID(NSBundle.mainBundle().URLForResource("loss", withExtension: "wav")!, &SOUND_LOSS)
	AudioServicesCreateSystemSoundID(NSBundle.mainBundle().URLForResource("newgame", withExtension: "wav")!, &SOUND_NEW_GAME)
}

func playSound(soundID: SystemSoundID) {
	AudioServicesPlaySystemSound(soundID)
}