extends Node

enum STATE {MENU, GAME}

const OPTIONS_PATH := "res://options.cfg"
# Settings are a subset of options that can be modified by the user.
const USER_SETTINGS_PATH := "user://user_settings.cfg"

const CONTROLS_PATH := "res://controls.json"

const SAVE_FOLDER := "user://saves"

const DEFAULT_CONTEXT_PATH := "res://default_context.json"
const USER_SAVE_PATH := SAVE_FOLDER + "/user_save.json"

const DATA_PATH := "res://assets/data.json"

### PUBLIC VARIABLES ###
var pause_UI : Control = null

# Is the game currently in editor mode? or not?
var is_in_editor_mode := false
var verbose_mode := true

var upgrades_data := {}
var player_data := {}
var enemies_data := {}
var interactives_data := {}

var _game_flow := {
	"menu": {
		"packed_scene": preload("res://src/Menu.tscn"),
		"state": STATE.MENU
		},
	"game": {
		"packed_scene": preload("res://src/Game.tscn"),
		"state": STATE.GAME
		},
	}
var _game_state : int = STATE.MENU

onready var _options_loader := $OptionsLoader
onready var _controls_loader := $ControlsLoader
onready var _data_loader := $DataLoader
onready var _state_loader := $StateLoader

func _ready():
	var _error := load_settings()

func load_settings() -> int:
	print("----- (Re)loading game settings from file -----")
	var _error : int = _options_loader.load_optionsCFG()
	_error += _controls_loader.load_controlsJSON()
	_error += _data_loader.load_dataJSON()
	# Also load the default context!? If the user context doesnt exist?
	var file := File.new()
	if file.file_exists(Flow.USER_SAVE_PATH):
		print("Found existing save file! Loading it automagically...")
		_error = _state_loader.load_stateJSON(Flow.USER_SAVE_PATH)
		if _error != OK:
			_error += _state_loader.load_stateJSON()
	else:
		_error += _state_loader.load_stateJSON()
	if _error == OK:
		print("----> Succesfully loaded settings!")
	else:
		push_error("Failed to load settings! Check console for clues!")
	return _error

func save_user_settings() -> int:
	print("----- Saving user-modifiable settings to local system -----")
	var _error : int = _options_loader.save_settingsCFG()
	if _error == OK:
		print("----> Succesfully saved user settings!")
	else:
		push_error("Failed to save user settings! Check console for clues!")
	return _error

func translate(msg_id : String):
	var translated_text : String = TranslationServer.translate(msg_id)
	if translated_text != msg_id:
		return translated_text
	else:
		push_error("Could not find translation for msg_id '{0}'!".format([msg_id]))
		return msg_id

func _unhandled_input(event : InputEvent):
## Catch all unhandled input not caught be any other control nodes.
	if InputMap.has_action("toggle_full_screen") and event.is_action_pressed("toggle_full_screen"):
		OS.window_fullscreen = not OS.window_fullscreen

	# if InputMap.has_action("restart") and event.is_action_pressed("restart"):
	# 	call_deferred("deferred_reload_current_scene")

	match _game_state:
		STATE.GAME:
			if InputMap.has_action("toggle_paused") and event.is_action_pressed("toggle_paused"):
				toggle_paused()

func toggle_paused():
	get_tree().paused = not get_tree().paused
	if get_tree().paused:
		pause_UI.show()
	else:
		pause_UI.hide()

func deferred_quit() -> void:
## Quit the game during an idle frame.
	get_tree().quit()

func deferred_reload_current_scene() -> void:
## It is now safe to reload the current scene.
	var _error := load_settings()
	_error = get_tree().reload_current_scene()
	get_tree().paused = false

func change_scene_to(key : String) -> void:
	if _game_flow.has(key):
		var state_settings : Dictionary = _game_flow[key]
		var packed_scene : PackedScene = state_settings.packed_scene
		_game_state = state_settings.state

		var error := get_tree().change_scene_to(packed_scene)
		get_tree().paused = false
		if error != OK:
			push_error("Failed to change scene to '{0}'.".format([key]))
		else:
			print("Succesfully changed scene to '{0}'.".format([key]))
	else:
		push_error("Requested scene '{0}' was not recognized... ignoring call for changing scene.".format([key]))

func go_to_game() -> void:
	change_scene_to("game")

func go_to_menu() -> void:
	change_scene_to("menu")

func get_upgrade_value(id : String, key : String, default):
	if upgrades_data.has(id):
		var data : Dictionary = upgrades_data[id]
		return data.get(key, default)
	else:
		return default

func get_player_value(key : String, default):
	return player_data.get(key, default)

func get_enemy_value(id : String, key : String, default):
	if enemies_data.has(id):
		var data : Dictionary = enemies_data[id]
		return data.get(key, default)
	else:
		return default

func get_interactive_value(id : String, key : String, default):
	if interactives_data.has(id):
		var data : Dictionary = interactives_data[id]
		return data.get(key, default)
	else:
		return default

func new_game() -> void:
	_state_loader.load_stateJSON()
	go_to_game()

func save_game() -> void:
	print("Saving game context to '{0}'".format([Flow.USER_SAVE_PATH]))
	_state_loader.save_stateJSON()

func load_game():
	_state_loader.load_stateJSON(Flow.USER_SAVE_PATH)
	go_to_game()

static func load_JSON(path : String) -> Dictionary:
# Load a JSON-file, convert it to a dictionary and return it.
	var file : File = File.new()
	var dictionary := {}
	var error : int = file.open(path, File.READ)
	if error == OK:
		var text : String = file.get_as_text()
		file.close()
		if typeof(parse_json(text)) != TYPE_NIL:
			dictionary = parse_json(text)
			if dictionary == null:
				push_error("Detected null-value in JSON at {0}.".format([path]))
			else:
				return dictionary

		push_error("Failed to correctly process '{0}', check file format!".format([path]))
		return {}
	else:
		push_error("Failed to open '{0}', check file availability!".format([path]))
		return {}

static func save_JSON(path : String, dictionary : Dictionary) -> int:
## Save a dictionary, in JSON format, to a file.
	var file : File = File.new()
	var error : int = file.open(path, File.WRITE)
	if error == OK:
		var text : String = to_json(dictionary)
		text = JSONBeautifier.beautify_json(text)
		file.store_string(text)
		file.close()

		print("Succesfully saved '{0}'.".format([path]))
		return OK
	else:
		push_error("Could not open file for writing purposes '{0}', check if file is locked!".format([path]))
		return error
