extends Control

var player_id = 1

onready var loading_anim_player = $"%LeftLoadingAnimPlayer"
onready var anim_player = $"%LeftAnimPlayer"

var p2_colors = {
	Color(0.67451, 0.631373, 0.996078): Color(0.996078, 0.47451, 0.505882),
	Color(0.152941, 0.133333, 0.290196): Color(0.294118, 0.0823529, 0.0901961),
	}

func _ready():
	reset()

func reset():
	anim_player.play("RESET")
	loading_anim_player.play("RESET")

func animate_reveal(id):
	anim_player.play("reveal")

func animate_unreveal(id):
	anim_player.play("RESET")

func animate_load_started(id):
	loading_anim_player.play("loop")

func animate_load_done(id):
	loading_anim_player.play("load_done")

# flips the banner onto the right side for P2
func mirror():
	set_anchors_and_margins_preset(PRESET_TOP_RIGHT)
	rect_scale.x = -1
	for node in $"%LeftLoadingText".get_children():
		if node is Label:
			node.rect_pivot_offset = node.rect_size / 2
			node.rect_scale.x *= -1
	use_p2_colors()

# swaps P1's colours for P2's in the anim players
func use_p2_colors():
	for player in [loading_anim_player, anim_player]:
		for anim_name in player.get_animation_list():
			# duplicated so the p1 banner keeps its colors
			var anim = player.get_animation(anim_name).duplicate()
			for track in anim.get_track_count():
				for key in anim.track_get_key_count(track):
					var value = anim.track_get_key_value(track, key)
					if value is Color and p2_colors.has(value):
						anim.track_set_key_value(track, key, p2_colors[value])
			player.add_animation(anim_name, anim)
	reset()
