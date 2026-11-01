extends RefCounted

## The course, generated deterministically from a seed so the same run is reproducible and testable.
##
## Two kinds of obstacle, and the ordering rule that makes the game fair: every obstacle is announced at least
## WARN_DISTANCE before it, and two obstacles are never closer than MIN_SPACING so a player always has room to recover
## from the last decision.

const WARN_DISTANCE := 150.0
const MIN_SPACING := 240.0
const GAP_WIDTH := 54.0

var length: float = 0.0
var obstacles: Array = []   # [{kind: "gap"|"gate", at: float, until: float}]


func build(seed_value: int, total_length: float) -> void:
	length = total_length
	obstacles.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var at := 600.0
	var want_gap := true
	while at < total_length - 400.0:
		if want_gap:
			obstacles.append({"kind": "gap", "at": at, "until": at + GAP_WIDTH})
		else:
			obstacles.append({"kind": "gate", "at": at, "until": at + 26.0})
		want_gap = not want_gap
		at += MIN_SPACING + rng.randf() * 180.0


func obstacle_at(x: float):
	for o in obstacles:
		if x >= o["at"] and x <= o["until"]:
			return o
	return null


func next_obstacle_after(x: float):
	for o in obstacles:
		if o["at"] > x:
			return o
	return null


func count_of(kind: String) -> int:
	var n := 0
	for o in obstacles:
		if o["kind"] == kind:
			n += 1
	return n


## Every obstacle must be announced, and no two may be closer than the recovery distance.
func validate() -> Array:
	var problems := []
	var prev := -1000.0
	for o in obstacles:
		if o["at"] >= length:
			problems.append("obstacle past the end: %s at %.0f" % [o["kind"], o["at"]])
		if o["at"] - prev < MIN_SPACING:
			problems.append("obstacles too close: %.0f after %.0f" % [o["at"], prev])
		prev = o["at"]
	return problems
