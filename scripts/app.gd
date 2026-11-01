extends Node2D

## The application. State machine, the playfield, the HUD, and the one input.

const Physics = preload("res://scripts/physics.gd")
const Course = preload("res://scripts/course.gd")
const UI = preload("res://scripts/ui.gd")

enum State { TITLE, PLAYING, PAUSED, FAILED, WON }

const TITLE := "SHIFT"
const SUBTITLE := "hold to take the high gear"
const CREDITS := [
    "UI       Gen XIA Dread HUD & UI Kit - gen-xia.itch.io",
    "AUDIO    Gen XIA Dread - Horror & Survival SFX - free",
    "ART      Gen XIA Character Library - free",
    "ENGINE   Godot 4",
    "",
    "Game Off 2026 - theme: SHIFT",
]
const TRACK_LENGTH := 7200.0
const CAMERA_LEAD := 130.0
const PLAYER_SCREEN_Y := 176.0

var state: int = State.TITLE
var ui
var sim
var course
var obstacles_drawn: Array = []
var gear_was_high: bool = false
var fails: int = 0
var best_distance: float = 0.0
var won: bool = false


func _ready() -> void:
	sim = Physics.new()
	course = Course.new()
	ui = UI.new()
	add_child(ui)
	ui.build(TITLE, SUBTITLE, CREDITS)
	if await _ready_shot_mode():
		return
	_show_title()


func _show_title() -> void:
	state = State.TITLE
	get_tree().paused = false
	ui.show_title(true)
	ui.show_hud(false)
	ui.show_end_panel(false)
	queue_redraw()


func _start() -> void:
	fails = 0
	_begin()


func _begin() -> void:
	state = State.PLAYING
	get_tree().paused = false
	sim.reset()
	won = false
	course.build(20261102, TRACK_LENGTH)
	obstacles_drawn.clear()
	gear_was_high = false
	ui.show_title(false)
	ui.show_hud(true)
	ui.show_end_panel(false)
	ui.set_gear(false)
	queue_redraw()


func _process(delta: float) -> void:
	if state == State.PLAYING:
		var held := Input.is_action_pressed("shift_gear")
		sim.set_gear(held)
		if held != gear_was_high:
			gear_was_high = held
			ui.set_gear(held)
		var before: float = sim.distance
		sim.step(delta)
		_check_obstacles(before)
		best_distance = maxf(best_distance, sim.distance)
		ui.set_readout(sim.speed, sim.distance, TRACK_LENGTH, sim.high_gear)
		queue_redraw()
	if camera_ok():
		pass


func camera_ok() -> bool:
	return true


func camera_x() -> float:
	return maxf(0.0, sim.distance - CAMERA_LEAD)


func _check_obstacles(before: float) -> void:
	if sim.distance >= TRACK_LENGTH:
		state = State.WON
		won = true
		ui.show_end(true, fails, sim.distance)
		return
	var crossed = null
	for o in course.obstacles:
		if before < o["at"] and sim.distance >= o["at"]:
			crossed = o
			break
	if crossed == null:
		return
	if crossed["kind"] == "gap" and not sim.clears_gap():
		_fail("too slow at the gap")
	elif crossed["kind"] == "gate" and not sim.passes_gate():
		_fail("too fast for the gate")


func _fail(reason: String) -> void:
	if state != State.PLAYING:
		return
	state = State.FAILED
	fails += 1
	ui.show_end(false, fails, sim.distance)


func _restart() -> void:
	if state == State.FAILED or state == State.WON:
		_begin()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if state == State.PLAYING:
				state = State.PAUSED
				get_tree().paused = true
				ui.show_pause(true)
			elif state == State.PAUSED:
				state = State.PLAYING
				get_tree().paused = false
				ui.show_pause(false)
		elif event.keycode == KEY_ENTER:
			if state == State.TITLE:
				_start()
			elif state == State.FAILED or state == State.WON:
				_restart()
		elif event.keycode == KEY_R and (state == State.FAILED or state == State.WON):
			_restart()


func _draw() -> void:
	if state == State.TITLE:
		return
	var cam := camera_x()
	var road_y := PLAYER_SCREEN_Y + 12.0
	draw_rect(Rect2(0, road_y, 480, 4), Color(0.24, 0.23, 0.26))
	draw_rect(Rect2(0, road_y + 4, 480, 90), Color(0.08, 0.08, 0.09))

	# obstacles within view
	for o in course.obstacles:
		var sx: float = o["at"] - cam
		if sx < -80 or sx > 560:
			continue
		if o["kind"] == "gap":
			var w: float = o["until"] - o["at"]
			draw_rect(Rect2(sx, road_y, w, 4), Color(0.05, 0.05, 0.06))
			draw_rect(Rect2(sx, road_y + 4, w, 90), Color(0.02, 0.02, 0.03))
			# warning stripe before the gap
			for i in 4:
				draw_rect(Rect2(sx - 120 + i * 26, road_y - 3, 12, 2), Color(0.85, 0.72, 0.30))
		else:
			draw_rect(Rect2(sx, road_y - 40, 26, 40), Color(0.55, 0.20, 0.18))
			for i in 3:
				draw_rect(Rect2(sx + 4, road_y - 34 + i * 11, 18, 5), Color(0.82, 0.30, 0.26))
			for i in 4:
				draw_rect(Rect2(sx - 120 + i * 26, road_y - 3, 12, 2), Color(0.82, 0.30, 0.26))

	# finish line
	var fx: float = TRACK_LENGTH - cam
	if fx > -20 and fx < 520:
		for i in 6:
			draw_rect(Rect2(fx + i * 6, road_y - 46 + i * 8, 6, 8), Color(0.85, 0.82, 0.74))

	# the player: a small machine, wide when in high gear
	var px := CAMERA_LEAD
	var wide := 20.0 if sim.high_gear else 13.0
	var body := Color(0.86, 0.84, 0.78) if sim.high_gear else Color(0.62, 0.60, 0.58)
	draw_rect(Rect2(px - wide * 0.5, PLAYER_SCREEN_Y - 9, wide, 9), body)
	draw_rect(Rect2(px - wide * 0.5, PLAYER_SCREEN_Y - 2, wide, 2), Color(0.20, 0.19, 0.21))
	if sim.high_gear:
		for i in 3:
			draw_rect(Rect2(px - wide * 0.5 - 6 - i * 5, PLAYER_SCREEN_Y - 7 + i, 4, 1), Color(0.78, 0.58, 0.26))


func _ready_shot_mode() -> bool:
	var args := OS.get_cmdline_user_args()
	var idx := args.find("--shot")
	if idx == -1 or idx + 1 >= args.size():
		return false
	var path: String = args[idx + 1]
	var mode: String = args[idx + 2] if args.size() > idx + 2 else ""
	if mode == "play" or mode == "high" or mode == "fail":
		_start()
		if mode == "high":
			sim.speed = Physics.SPEED_HIGH
			sim.distance = 300.0
			ui.set_gear(true)
		elif mode == "fail":
			sim.speed = 340.0
			sim.distance = 560.0
		else:
			sim.speed = 120.0
			sim.distance = 240.0
		ui.set_readout(sim.speed, sim.distance, TRACK_LENGTH, sim.high_gear)
		queue_redraw()
	for i in 4:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("shot saved: ", path, " ", img.get_width(), "x", img.get_height())
	get_tree().quit()
	return true
