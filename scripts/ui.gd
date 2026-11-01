extends CanvasLayer

## Title, pause, end, and the cockpit readout.
##
## The readout is the game: which gear, how fast, how far. In a one-button game those three numbers are the whole
## information set the player has, so they get the top of the screen and nothing else competes with them.

var title_box: Control
var pause_box: Control
var end_box: Control
var gear_label: Label
var speed_label: Label
var progress_label: Label
var title_label: Label
var sub_label: Label
var credits_label: Label
var end_label: Label
var end_sub: Label


func _label(text: String, size: int, colour: Color, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.horizontal_alignment = align
	return l


func _panel() -> Panel:
	return Panel.new()


func build(game_title: String, subtitle: String, credits: Array) -> void:
	title_label.text = game_title
	sub_label.text = subtitle
	credits_label.text = "\n".join(credits)
	title_label.add_theme_font_size_override("font_size", 46)


func _build() -> void:
	title_box = _panel()
	title_box.position = Vector2.ZERO
	title_box.size = Vector2(480, 270)
	add_child(title_box)

	title_label = _label("SHIFT", 46, Color(0.88, 0.85, 0.79))
	title_label.position = Vector2(0, 34)
	title_label.size = Vector2(480, 56)
	title_box.add_child(title_label)

	sub_label = _label("hold to take the high gear", 13, Color(0.64, 0.62, 0.66))
	sub_label.position = Vector2(0, 92)
	sub_label.size = Vector2(480, 20)
	title_box.add_child(sub_label)

	var rules := _label("HOLD SHIFT  = high gear - fast, but it will not stop in time", 11,
		Color(0.80, 0.62, 0.30), HORIZONTAL_ALIGNMENT_LEFT)
	rules.position = Vector2(46, 122)
	rules.size = Vector2(400, 16)
	title_box.add_child(rules)

	var rules2 := _label("LET GO      = low gear - slow, but it fits through the gates", 11,
		Color(0.62, 0.78, 0.52), HORIZONTAL_ALIGNMENT_LEFT)
	rules2.position = Vector2(46, 140)
	rules2.size = Vector2(400, 16)
	title_box.add_child(rules2)

	var rules3 := _label("Gaps need speed. Gates punish it. That is the whole game.", 11,
		Color(0.56, 0.54, 0.58), HORIZONTAL_ALIGNMENT_LEFT)
	rules3.position = Vector2(46, 164)
	rules3.size = Vector2(400, 16)
	title_box.add_child(rules3)

	var hint := _label("[ ENTER to start ]", 14, Color(0.82, 0.80, 0.76))
	hint.position = Vector2(0, 192)
	hint.size = Vector2(480, 22)
	title_box.add_child(hint)

	credits_label = _label("", 10, Color(0.44, 0.43, 0.48), HORIZONTAL_ALIGNMENT_LEFT)
	credits_label.position = Vector2(28, 216)
	credits_label.size = Vector2(424, 50)
	title_box.add_child(credits_label)

	pause_box = _panel()
	pause_box.position = Vector2(150, 90)
	pause_box.size = Vector2(180, 76)
	pause_box.visible = false
	add_child(pause_box)
	var pl := _label("PAUSED", 20, Color(0.86, 0.83, 0.78))
	pl.position = Vector2(0, 12)
	pl.size = Vector2(180, 26)
	pause_box.add_child(pl)
	var ph := _label("ESC resume    R restart", 11, Color(0.60, 0.59, 0.63))
	ph.position = Vector2(0, 44)
	ph.size = Vector2(180, 18)
	pause_box.add_child(ph)

	end_box = _panel()
	end_box.position = Vector2.ZERO
	end_box.size = Vector2(480, 270)
	end_box.visible = false
	add_child(end_box)
	end_label = _label("", 24, Color(0.86, 0.83, 0.78))
	end_label.position = Vector2(0, 90)
	end_label.size = Vector2(480, 32)
	end_box.add_child(end_label)
	end_sub = _label("", 12, Color(0.62, 0.60, 0.64))
	end_sub.position = Vector2(0, 126)
	end_sub.size = Vector2(480, 20)
	end_box.add_child(end_sub)
	var eh := _label("ENTER to go again", 13, Color(0.55, 0.70, 0.40))
	eh.position = Vector2(0, 156)
	eh.size = Vector2(480, 20)
	end_box.add_child(eh)

	gear_label = _label("LOW", 15, Color(0.62, 0.78, 0.52), HORIZONTAL_ALIGNMENT_LEFT)
	gear_label.position = Vector2(12, 8)
	gear_label.size = Vector2(120, 20)
	add_child(gear_label)

	speed_label = _label("", 11, Color(0.78, 0.76, 0.72), HORIZONTAL_ALIGNMENT_LEFT)
	speed_label.position = Vector2(12, 28)
	speed_label.size = Vector2(200, 16)
	add_child(speed_label)

	progress_label = _label("", 11, Color(0.62, 0.60, 0.64), HORIZONTAL_ALIGNMENT_RIGHT)
	progress_label.position = Vector2(260, 8)
	progress_label.size = Vector2(208, 16)
	add_child(progress_label)


func _ready() -> void:
	layer = 10
	_build()


func show_title(on: bool) -> void:
	title_box.visible = on
	if not on:
		pause_box.visible = false
		end_box.visible = false


func show_hud(on: bool) -> void:
	gear_label.visible = on
	speed_label.visible = on
	progress_label.visible = on


func show_pause(on: bool) -> void:
	pause_box.visible = on


func show_end_panel(on: bool) -> void:
	end_box.visible = on


func set_gear(high: bool) -> void:
	gear_label.text = "HIGH GEAR" if high else "LOW GEAR"
	gear_label.add_theme_color_override("font_color",
		Color(0.88, 0.62, 0.28) if high else Color(0.62, 0.78, 0.52))


func set_readout(speed: float, distance: float, total: float, high: bool) -> void:
	speed_label.text = "%d px/s   %s" % [int(speed), "committed" if high else "gripping"]
	progress_label.text = "%d / %d" % [int(distance), int(total)]


func show_end_game(won: bool, fails: int, distance: float) -> void:
	end_box.visible = true
	if won:
		end_label.text = "SHIFTED THROUGH"
		end_label.add_theme_color_override("font_color", Color(0.60, 0.80, 0.44))
		end_sub.text = "the whole shift, %d crashes on the way" % fails
	else:
		end_label.text = "STALLED"
		end_label.add_theme_color_override("font_color", Color(0.82, 0.34, 0.30))
		end_sub.text = "reached %d px before the gearbox beat you" % int(distance)
		print("fail: ", fails, " distance ", int(distance))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER:
			if title_box.visible:
				get_parent()._start()
			elif end_box.visible:
				get_parent()._restart()
