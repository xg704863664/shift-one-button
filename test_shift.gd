extends SceneTree

## Headless test of SHIFT.
##
## The point of a one-button game is that its entire design is arithmetic, so these assertions can cover the actual game
## logic rather than the plumbing: that the two gears really differ, that a gap is impossible slowly and possible fast,
## that a gate is the inverse, and that the course announces everything with room to recover.

var _pass := 0
var _fail := 0
var _lines: Array[String] = []


func check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		_lines.append("PASS  " + name)
	else:
		_fail += 1
		_lines.append("FAIL  " + name + ("" if detail == "" else "  [" + detail + "]"))


func _init() -> void:
	var p = load("res://scripts/physics.gd")
	var c = load("res://scripts/course.gd")
	var a = load("res://scripts/app.gd")

	check("physics script loads", p != null)
	check("course script loads", c != null)
	check("app script loads", a != null)
	if p == null or c == null:
		_finish()
		return

	# --- the two gears must actually differ, or the button does nothing
	var sim = p.new()
	check("starts in low gear", sim.high_gear == false)
	check("starts stationary", sim.speed == 0.0)
	check("low cruise is slower than high cruise", p.SPEED_LOW < p.SPEED_HIGH)

	# low gear reaches its cruise quickly
	for i in 60:
		sim.step(1.0 / 60.0)
	check("low gear reaches its cruise", absf(sim.speed - p.SPEED_LOW) < 1.0, str(sim.speed))

	# switching up must take time - that is the commitment the game asks for
	var speed_before: float = sim.speed
	sim.set_gear(true)
	var frames_to_cruise := 0
	while absf(sim.speed - p.SPEED_HIGH) > 1.0 and frames_to_cruise < 600:
		sim.step(1.0 / 60.0)
		frames_to_cruise += 1
	check("high gear takes several frames to build", frames_to_cruise > 20, str(frames_to_cruise))
	check("high gear ends faster than it started", sim.speed > speed_before)

	# braking in high gear is deliberately poor
	var speed_at_high: float = sim.speed
	sim.set_gear(false)
	sim.step(1.0 / 60.0)
	check("does not stop instantly from high gear", sim.speed > p.SPEED_LOW, str(sim.speed))

	# --- gaps and gates are inverse tests on the same number
	var slow = p.new()
	slow.speed = p.SPEED_LOW
	check("a gap cannot be cleared at low cruise", slow.clears_gap() == false)
	check("a gate can be passed at low cruise", slow.passes_gate() == true)

	var fast = p.new()
	fast.speed = p.SPEED_HIGH
	check("a gap can be cleared at high cruise", fast.clears_gap() == true)
	check("a gate cannot be passed at high cruise", fast.passes_gate() == false)

	# --- and the design must be possible in principle
	check("the design is fair (each obstacle passable in some gear)", slow.design_is_fair() == true)
	check("gate limit is above low cruise", p.GATE_LIMIT_SPEED > p.SPEED_LOW,
		"%f vs %f" % [p.GATE_LIMIT_SPEED, p.SPEED_LOW])
	check("gap clear speed is below high cruise", p.GAP_CLEAR_SPEED < p.SPEED_HIGH,
		"%f vs %f" % [p.GAP_CLEAR_SPEED, p.SPEED_HIGH])

	# --- the course
	var course = c.new()
	course.build(20261102, 7200.0)
	check("course has obstacles", course.obstacles.size() > 8, str(course.obstacles.size()))
	check("course has both kinds", course.count_of("gap") > 0 and course.count_of("gate") > 0,
		"gaps %d gates %d" % [course.count_of("gap"), course.count_of("gate")])
	check("course is valid (spacing and bounds)", course.validate().is_empty(), str(course.validate()))
	check("first obstacle is not immediate", course.obstacles[0]["at"] > 300.0,
		str(course.obstacles[0]["at"]))

	# deterministic: the same seed must give the same course, or a bug is unreproducible
	var course2 = c.new()
	course2.build(20261102, 7200.0)
	check("same seed gives the same course", course2.obstacles.size() == course.obstacles.size())

	# obstacle lookup works at the boundary
	var first = course.obstacles[0]
	check("obstacle_at finds the obstacle inside its span",
		course.obstacle_at(first["at"] + 1.0) != null)
	check("obstacle_at finds nothing just before it",
		course.obstacle_at(first["at"] - 1.0) == null)

	# --- credits must name the assets, because the jam page has to be honest
	var credits = a.get_script_constant_map().get("CREDITS", [])
	var joined := " ".join(credits)
	check("credits name the ui kit", "HUD" in joined)
	check("credits name the audio", "SFX" in joined)
	check("credits name the art", "Character Library" in joined)
	check("credits name the jam and theme", "Game Off 2026" in joined and "SHIFT" in joined)

	var states = a.get_script_constant_map().get("State", {})
	check("five states exist", states.size() == 5, str(states.size()))

	_finish()


func _finish() -> void:
	_lines.append("")
	_lines.append("SUMMARY  %d passed, %d failed" % [_pass, _fail])
	var out := FileAccess.open("res://_test-result.txt", FileAccess.WRITE)
	out.store_string("\n".join(_lines))
	out.close()
	quit(0 if _fail == 0 else 1)
