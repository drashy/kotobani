
extends Node2D

# member variables here, example:
# var a=2
# var b="textvar"
const _startX = 224
const _startY = 0
const _sizeX = 8
const _sizeY = 6

var grid = []
var tile = preload("res://tile.scn")
var arrows = preload("res://arrows.scn")

var stats = preload("res://dicts/de_DE/stats.gd").new()
var refs = preload("res://dicts/de_DE/references.gd").new()

var selectedTiles = []
var lastTile = [-1,-1]
var createdWord = ""
var selectedTileCnt = 0

func _ready():
	randomize()
	var sX = _startX
	var sY = _startY
	grid.resize(_sizeX*_sizeY)
	selectedTiles.resize(_sizeX*_sizeY)
	for i in range(0, _sizeX*_sizeY):
		selectedTiles[i] = [-1,-1,null]

	print("maxRuneProbability : ",stats.maxRuneProbability)

#	var lbl = Button.new()
#	add_child( lbl)
#	lbl.set_pos(Vector2(300, 300))
#	lbl.set_size(Vector2(100,100))
#	lbl.set_text("HALLLLOOOOOOO")
	for i in range(_sizeY):
		for s in range (_sizeX):
			var dup = tile.instance()
			var rune = chooseRune()
			add_child(dup)
			dup.set_pos(Vector2(sX,sY))
			dup.set_text(rune)
			var params = [dup,dup.get_text(), i, s]
			dup.connect("pressed", self, "_on_tile_pressed", params)
			grid[(i*_sizeX+s)]=dup
			sX += 100
		sX = _startX
		sY += 100
		
func chooseRune():
	var runeSelector = rand_range(0, stats.maxRuneProbability)
	var lowest = stats.maxRuneProbability
	for r in stats.dictStats:
		if (runeSelector <= r) && (r < lowest):
			lowest = r
	return stats.dictStats[lowest]

func notInSelected(x, y):
	for i in range(0,selectedTileCnt):
		var st = selectedTiles[i]
		if (st[0] == x) && (st[1] == y):
			return false
	return true

func clearSelected():
	print("Entering clearSelected")
	for i in range(0,selectedTileCnt):
		if selectedTiles[i] != [-1,-1,null]:
			selectedTiles[i][2].set_pressed(false)
		selectedTiles[i] = [-1,-1,null]
	selectedTileCnt=0
	print("done")
		
func _on_tile_pressed(btn, txt, x, y):
	if ((lastTile[0] == -1) || (lastTile[1] == -1)) || (x<=(lastTile[0]+1)) && (x>=(lastTile[0]-1)) && (y<=(lastTile[1]+1)) && (y>=(lastTile[1]-1)) && ((lastTile[0] != x) || (lastTile[1] != y)) && (notInSelected(x,y)):
		lastTile = [x,y]
		selectedTiles[selectedTileCnt]=[x,y,btn]
		selectedTileCnt += 1
		createdWord = createdWord + txt
	elif (lastTile[0] == x) && (lastTile[1] == y):
		print("Word : ",createdWord)
		print("Exists : ",checkWord(createdWord))
		createdWord = ""
		lastTile = [-1,-1]
		clearSelected()
	else:
		clearSelected()
		print("CLEARED")
		lastTile = [x,y]
		selectedTiles[selectedTileCnt]=[x,y,btn]
		selectedTileCnt += 1
		createdWord = txt
	
func checkWord(w):
	if w.length() < 3:
		return false
	var prefix = w.substr(0,3)
	if ! refs.dictRefs.has(prefix):
		return false
	var fh = File.new()
	fh.open("res://dicts/de_DE/"+refs.dictRefs[prefix], 1)
	var cnt = fh.get_as_text()
	fh.close()
	var search = "\n"+w+"\n"
	if w.length() == 3:
		search = w+"\n" 
	return cnt.find(search,0)
