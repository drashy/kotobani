#    Kotobani - a game in which you create words to increase your points
#    Copyright (C) 2014  sammy fischer (sammy@cosmic-bandito.com)
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

extends Node2D

const _VERSION = "alpha_8"
const _COPYRIGHT = "\ncopyright 2014 Sammy Fischer\n(sammy@cosmic-bandito.com)\nLicensed under GPLv3"

const _startX = 224
const _startY = 0
const _sizeX = 16
const _sizeY = 12
const _tileSize = 50
const _halfTileSize = 25
const _HIGHEST = 999999
const _initialTimer = 60*2

var PLAY = false
var grid = []
var stars = []

var tile = preload("res://tile.scn")
var starsPrtcl = preload("res://particles_rainbow.scn")

var scoreNode = null
var sfxNode = null
var lgWdNode = null
var crtWdNode = null
var lstWdNode = null
var progressionBar = null


var soundToggle = 1
var musicToggle = 1

var gameTimer = null
var timer = _initialTimer
var lastTimer = timer
var timerNode = null

var selectedTiles = []
var lastTile = [-1,-1]
var createdWord = ""
var selectedTileCnt = 0
var score = 0
var longestWord = ""
var level = 1
var nextLevelAt = 200
var oldLevelAt = 0

var gameMode = 0
var highScore_m0 = 0
var highScore_m1 = 0

var lowestOrderedPerX = []

var options = null

var stats = null
var refs = null

func _input(e):
	if e.is_action("clear_selected"):
		if PLAY != true:
			return
		createdWord = ""
		lastTile = [-1,-1]
		clearSelected()
		selectedTileCnt = 0
		return
	if e.is_action("toggle_sound"):
		soundToggle = soundToggle ^ 1
		return
	if e.is_action("toggle_music"): 
		musicToggle = musicToggle ^ 1
		if musicToggle == 1:
			get_node("streamNode").play()
		else:
			get_node("streamNode").stop()
		return

func rebuildGrid():
	if PLAY != true:
		return
	for i in range(_sizeX*_sizeY):
		selectedTiles[i] = [-1,-1,null]
	for i in range(_sizeY):
		for s in range (_sizeX):
			grid[(i*_sizeX+s)].set_text(chooseRune())
			stars[i*_sizeX+s].set_emitting(true)
			

func gameOver():
	if PLAY != true:
		return
	gameTimer.stop()
	PLAY = false
	for i in range(_sizeX*_sizeY):
		grid[i].remove_and_skip()
		stars[i].remove_and_skip()
	get_node("gameover").set_pos(Vector2(0,0))
	get_node("gameover").raise()
	get_node("titlescreen").set_pos(Vector2(-10000,-10000))
	get_node("streamTitle").stop()
	get_node("streamGameOn").stop()
	get_node("streamGameOver").play()
	get_node("gameover/continue").connect("pressed", self, "titleMenu")
	get_node("gameover/continue").connect("pressed",self,"titleMenu")
	if score > highScore_m0:
		highScore_m0 = score
	get_node("gameover/finalScore").set_text(str(score))
	get_node("gameover/highScore").set_text(str(highScore_m0))
	get_node("gameover/longWord").set_text(longestWord)
	
func _time_out():
	if PLAY != true:
		return
	timer = timer - 1
	var seconds = int(timer) % 60
	var minutes = int(floor(timer/60))
	timerNode.set_text(str(minutes)+":"+str(seconds).pad_zeros(2))
	if timer < 0:
		gameTimer.stop()
		gameOver()

func getOut():
	self.remove_and_skip()

func _ready():
	randomize()

	options = load("res://options.gd").new()
	stats = load("res://dicts/"+options.locale+"/stats.gd").new()
	refs = load("res://dicts/"+options.locale+"/references.gd").new()
	get_node("version").set_text(_VERSION+_COPYRIGHT)
	print("locale :",options.locale)
	TranslationServer.set_locale(options.locale)
	highScore_m0 = options.highScore_m0
	highScore_m1 = options.highScore_m1
	get_node("titlescreen/Grid/playBtn").connect("pressed", self, "play")
	get_node("titlescreen/Grid/exitBtn").connect("pressed", self, "getOut")
	get_node("streamTitle").play()
	get_node("streamGameOver").stop()
	get_node("streamGameOn").stop()
	titleMenu()
	
func titleMenu():
	get_node("streamTitle").play()
	get_node("streamGameOver").stop()
	get_node("streamGameOn").stop()
	get_node("gameover").set_pos(Vector2(-10000,-10000))
	get_node("titlescreen").set_pos(Vector2(0,0))
		
		
func play():
	if PLAY == true:
		return
	timer = _initialTimer
	lastTimer = timer
	selectedTiles = []
	lastTile = [-1,-1]
	createdWord = ""
	selectedTileCnt = 0
	score = 0
	longestWord = ""
	level = 1
	nextLevelAt = 200
	oldLevelAt = 0

	get_node("streamTitle").stop()
	get_node("titlescreen").set_pos(Vector2(-10000,-10000))
	PLAY = true
	var sX = _startX
	var sY = _startY
	#get_node("lastword-label").set_text(TranslationServer.translate("LASTWORD")+" :")
	#get_node("longest-label").set_text(TranslationServer.translate("LONGWORD")+" :")
	#get_node("buffer-label").set_text(TranslationServer.translate("BUFFER")+" :")
	#get_node("score-label").set_text(TranslationServer.translate("SCORE")+" :")
	#get_node("level-label").set_text(TranslationServer.translate("LEVEL")+" :")
	get_node("levelWord").set_text(str(level))

	scoreNode = get_node("scoreDisplay")
	sfxNode = get_node("sfxNode")
	lgWdNode = get_node("longuestWord")
	crtWdNode = get_node("currentWord")
	lstWdNode = get_node("lastWord")
	timerNode = get_node("timer")
	progressionBar = get_node("progressionBar")
	gameTimer=get_node("gameTimer")
	gameTimer.connect("timeout", self, "_time_out")
	gameTimer.start()
	
	grid.resize(_sizeX*_sizeY)
	stars.resize(_sizeX*_sizeY)
	selectedTiles.resize(_sizeX*_sizeY)
	lowestOrderedPerX.resize(_sizeX)
	for i in range(0,_sizeX):
		lowestOrderedPerX[i] = {}
		
	for i in range(_sizeX*_sizeY):
		selectedTiles[i] = [-1,-1,null]
	print("maxRuneProbability : ",stats.maxRuneProbability)
	for i in range(_sizeY):
		for s in range (_sizeX):
			var dup = tile.instance()
			var rune = chooseRune()
			add_child(dup)
			dup.set_pos(Vector2(sX,sY))
			dup.set_text(rune)
			var params = [dup, s, i]
			dup.connect("pressed", self, "_on_tile_pressed", params)
			grid[(i*_sizeX+s)]=dup
			dup = starsPrtcl.instance()
			add_child(dup)
			dup.set_pos(Vector2(sX+_halfTileSize,sY+_halfTileSize))
			stars[(i*_sizeX+s)]=dup
			sX += _tileSize
		sX = _startX
		sY += _tileSize
	for i in range(_sizeY*_sizeX):
		stars[i].raise()
		
	set_process_input(true)
	get_node("streamTitle").stop()
	get_node("streamGameOver").stop()
	get_node("streamGameOn").play()
		
func chooseRune():
	if PLAY != true:
		return
	var runeSelector = rand_range(0, stats.maxRuneProbability)
	var lowest = stats.maxRuneProbability
	for r in stats.dictStats:
		if (runeSelector <= r) && (r < lowest):
			lowest = r
	return stats.dictStats[lowest]

func notInSelected(x, y):
	if PLAY != true:
		return
	for i in range(0,selectedTileCnt):
		var st = selectedTiles[i]
		if (st[0] == x) && (st[1] == y):
			return false
	return true

func clearSelected():
	if PLAY != true:
		return
	print("Entering clearSelected")
	for i in range(0,selectedTileCnt):
		if selectedTiles[i] != [-1,-1,null]:
			selectedTiles[i][2].set_pressed(false)
		selectedTiles[i] = [-1,-1,null]
	selectedTileCnt=0
	createdWord = ""
	selectedTileCnt = 0
	lastTile = [-1,-1]
	crtWdNode.set_text(createdWord)
	print("done")
	
func _on_tile_pressed(btn, x, y):	
	if PLAY != true:
		return
	var txt = btn.get_text()
	if ((lastTile[0] == -1) || (lastTile[1] == -1)) || (x<=(lastTile[0]+1)) && (x>=(lastTile[0]-1)) && (y<=(lastTile[1]+1)) && (y>=(lastTile[1]-1)) && ((lastTile[0] != x) || (lastTile[1] != y)) && (notInSelected(x,y)):
		lastTile = [x,y]
		btn.set_pressed(true)
		selectedTiles[selectedTileCnt]=[x,y,btn]
		selectedTileCnt += 1
		createdWord = createdWord + txt
		crtWdNode.set_text(createdWord)
	elif (lastTile[0] == x) && (lastTile[1] == y):
		btn.set_pressed(true)
		var wordExists = checkWord(createdWord)
		print("Word : ",createdWord)
		print("Exists : ", wordExists)
		if wordExists:
			if soundToggle == 1:
				sfxNode.play("wordfound", false)
			lstWdNode.set_text(createdWord)
			var mult = ((createdWord.length()-3)*10)
			if mult == 0:
				mult = 1				
			score += selectedTileCnt*mult
			scoreNode.set_text(str(score))
			if createdWord.length() > longestWord.length():
				longestWord = createdWord
				lgWdNode.set_text(longestWord)
			destroyAndFall()
			clearSelected()
			if score >= nextLevelAt:
				gameTimer.stop()
				level = level + 1
				oldLevelAt = nextLevelAt
				nextLevelAt = nextLevelAt+(level * 100)				
				get_node("levelWord").set_text(str(level))
				sfxNode.play("levelup", false)
				timer = lastTimer+(60*(level/2))
				print("next level at : ",nextLevelAt)
				rebuildGrid()
				gameTimer.start()
			progressionBar.setProgression(score-oldLevelAt, nextLevelAt-oldLevelAt)
			
	else:
		clearSelected()
		print("CLEARED")
		lastTile = [x,y]
		selectedTiles[selectedTileCnt]=[x,y,btn]
		selectedTileCnt = 1
		createdWord = txt
		
func destroyAndFall():
	if PLAY != true:
		return
	# DESTROY
	for i in range(0,selectedTileCnt):
		var x = selectedTiles[i][0]
		var y =selectedTiles[i][1]
		selectedTiles[i][2].set_text("")
		stars[y*_sizeX+x].set_emitting(true)

		var keys = lowestOrderedPerX[x].keys()
		var highest = -1
		if ! keys.empty():
			var tmpOrder = 1000
			highest = lowestOrderedPerX[x][_HIGHEST]
			keys.sort()
			for k in keys:
				if k == _HIGHEST:
					continue
				if y < lowestOrderedPerX[x][k][1]:
					tmpOrder = k - 50
				elif y == lowestOrderedPerX[x][k][1]:
					tmpOrder = k - 1
					break
				else:
					tmpOrder = k+50
			lowestOrderedPerX[x][tmpOrder] = selectedTiles[i]
		else:
			lowestOrderedPerX[x][500]=selectedTiles[i]
		if y > highest:
			lowestOrderedPerX[x][_HIGHEST] = y
	# FALL
	var c = ""
	var rrange = []
	for x in range(0,_sizeX):
		if lowestOrderedPerX[x].empty():
			continue
		c = ""
		var rng = range(0,lowestOrderedPerX[x][_HIGHEST]+1)
		rng.invert()
		for y in rng:
			c = rcsvGetLetterAbove(x,y)
			if c == "":
				c = chooseRune()
			grid[y*_sizeX+x].set_text(c)
			
		
func rcsvGetLetterAbove(x,y):
	if PLAY != true:
		return
	var idx = y*_sizeX+x
	var cnt = grid[idx].get_text()
	if cnt != "":
		grid[idx].set_text("")
		return cnt
	else:
		y = y -1
		if y < 0:
			return ""
		else:
			return rcsvGetLetterAbove(x,y)
	
func checkWord(w):
	if PLAY != true:
		return
	if w.length() < 3:
		return false
	var prefix = w.substr(0,3)
	if ! refs.dictRefs.has(prefix):
		return false
	var fh = File.new()
	fh.open("res://dicts/"+options.locale+"/"+refs.dictRefs[prefix], 1)
	var cnt = fh.get_as_text()
	fh.close()
	var rs = cnt.find("\n"+w+"\n",0)
	if rs == -1:
		rs = cnt.find(w+"\n",0)
	if rs > -1:
		return true
	else:
		return false
