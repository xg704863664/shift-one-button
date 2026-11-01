extends RefCounted

## The whole game in arithmetic, deliberately separate from anything that draws.
##
## Two gears, and the tension between them:
##     LOW   target 120 px/s, reaches it in a fraction of a second, and braking is violent
##     HIGH  target 420 px/s, builds slowly, and almost cannot brake
##
## The course then asks for both: a gap needs speed at the lip, a gate rejects speed above a threshold. So the player is
## permanently choosing which of the two to be late for, which is the entire game.

const SPEED_LOW := 120.0
const SPEED_HIGH := 420.0
const ACCEL_LOW := 900.0
const ACCEL_HIGH := 300.0
const BRAKE_LOW := 1400.0
const BRAKE_HIGH := 260.0

const GAP_CLEAR_SPEED := 260.0     # below this you drop into the gap
const GATE_LIMIT_SPEED := 210.0    # above this the gate stops you

var high_gear: bool = false
var speed: float = 0.0
var distance: float = 0.0


func reset() -> void:
	high_gear = false
	speed = 0.0
	distance = 0.0


func set_gear(high: bool) -> void:
	high_gear = high


func target_speed() -> float:
	return SPEED_HIGH if high_gear else SPEED_LOW


func step(delta: float) -> void:
	var target := target_speed()
	var rate: float
	if speed < target:
		rate = ACCEL_HIGH if high_gear else ACCEL_LOW
	else:
		# braking in high gear is deliberately poor: that is what makes committing to a gap a decision
		rate = BRAKE_HIGH if high_gear else BRAKE_LOW
	var toward := signf(target - speed)
	if absf(target - speed) <= rate * delta:
		speed = target
	else:
		speed += toward * rate * delta
	speed = maxf(0.0, speed)
	distance += speed * delta


func clears_gap() -> bool:
	return speed >= GAP_CLEAR_SPEED


func passes_gate() -> bool:
	return speed <= GATE_LIMIT_SPEED


## A gap is unfair if it is too narrow to require speed, or a gate is unfair if it cannot be passed in any gear.
func design_is_fair() -> bool:
	# gate must be passable at LOW cruise, or it is impossible
	if GATE_LIMIT_SPEED < SPEED_LOW:
		return false
	# gap must be clearable in HIGH cruise, or it is impossible
	if GAP_CLEAR_SPEED > SPEED_HIGH:
		return false
	return true
