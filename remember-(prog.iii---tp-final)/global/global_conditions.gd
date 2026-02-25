#global_conditions.gd (autoload):
extends Node

signal conditions_changed

#region PLAYER SAVE MARKS

var player_name: String = ""
var level_name : String = ""
var zone_name : String = ""
var zone_tag : String = ""

var yellow_boxes_open: int = 0
var red_boxes_open: int = 0

var c_symbols_obtained: int = 0
var a_symbols_obtained: int = 0
var s_symbols_obtained: int = 0

var map_discovered: int = 0

var game_act: int = 1
var welcome_home: bool = false

var zodiac_key_cards: int = 1
var zone_flowers: int = 0

var zone_illness: int = 0

#endregion

var floating_box_state: int = 0


#region MENU UI CONDITIONS

var puppet_name_revealed: bool = false
var puppet_sucre: bool = false

var first_symbol_count: int = 0
var sleeve_count: int = 0
var special_2_slot_obtained: bool = false

#endregion


#region PRELUDE CONDITIONS

var cts_beggining: bool = false
var cts_z0_child_encounter: bool = false
var cts_chills: bool = false
var cts_ladderLost: bool = false

var has_read_bookshelf: bool = false

#endregion


#region ZONE 0 CONDITIONS

var has_read_zone0_sign: bool = false
var cats_picture_seen: bool = false

#endregion


#region ZONE 1 CONDITIONS

#region ELSEN STATION

var lookingForTheChild: int = 0
var tramPassport: int = 0

var has_talked_elsen: bool = false

#endregion



#region ANNEX MINES



#endregion

#endregion

func reveal_name():
	puppet_name_revealed = true
	conditions_changed.emit()


func set_sucre(active: bool):
	puppet_sucre = active
	conditions_changed.emit()


func reset_conditions() -> void:
	player_name = ""
	yellow_boxes_open = 0
	red_boxes_open = 0
	c_symbols_obtained = 0
	a_symbols_obtained = 0
	s_symbols_obtained = 0
	map_discovered = 0
	game_act = 1
	welcome_home = false
	zodiac_key_cards = 1
	zone_flowers = 0
	zone_illness = 0

	puppet_name_revealed = false
	puppet_sucre = false
	first_symbol_count = 0
	sleeve_count = 0
	special_2_slot_obtained = false

	cts_beggining = false
	cts_z0_child_encounter = false
	cts_chills = false
	cts_ladderLost = false
	has_read_bookshelf = false

	has_read_zone0_sign = false
	cats_picture_seen = false

	lookingForTheChild = 0
	tramPassport = 0
	has_talked_elsen = false
