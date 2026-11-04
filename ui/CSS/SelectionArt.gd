extends "res://bordermanager/FullArtManager.gd"

signal anim_reveal(player_id)
signal anim_unreveal(player_id)
signal anim_load_started(player_id)
signal anim_load_done(player_id)
signal banner_changed(player_id, banner)

onready var sfx_nodes = {
	1: [$"%LeftSFX1", $"%LeftSFX2"],
	2: [$"%RightSFX1", $"%RightSFX2"],
}

# shows each player banner on the opposite side from them, for multiplayer
var swap_sides = false

# banner scene paths where the fighter paths are the key
var custom_banners = {}
# the banner thats shown on each side
var banners = {1: null, 2: null}

func _ready():
	for player_id in sfx_nodes:
		for node in sfx_nodes[player_id]:
			node.get_node("Timer").connect("timeout", node, "play")
	reset()

# the side a player's art shows on
func get_side(player_id):
	return 3 - player_id if swap_sides else player_id

func reset():
	use_banner(1, "")
	use_banner(2, "")
	$"%LeftAnimPlayer".play("RESET")
	$"%RightAnimPlayer".play("RESET")
	$"%LeftLoadingAnimPlayer".play("RESET")
	$"%RightLoadingAnimPlayer".play("RESET")
	set_style_params(1, null)
	set_style_params(2, null)
	apply_style(1, null)
	apply_style(2, null)
	
	for player_id in sfx_nodes:
		for node in sfx_nodes[player_id]:
			node.stop()
			node.get_node("Timer").stop()



func apply_visibility_setting():
	visible = Global.show_selection_art

func animate_reveal(id :int):
	if not Global.show_selection_art:
		return
	emit_signal("anim_reveal", id)
	if banner_call("animate_reveal", id):
		return
	var anim_player = $"%LeftAnimPlayer" if id == 1 else $"%RightAnimPlayer"
	anim_player.play("reveal")
	BorderManager.set_border_color(id, BorderManager.dark_color)


func animate_unreveal(id :int):
	emit_signal("anim_unreveal", id)
	if banner_call("animate_unreveal", id):
		return
	var anim_player = $"%LeftAnimPlayer" if id == 1 else $"%RightAnimPlayer"
	anim_player.play("RESET")
	BorderManager.set_border_color(id, BorderManager.menu_color)


func animate_load_started(id :int):
	if not Global.show_selection_art:
		return
	emit_signal("anim_load_started", id)
	if banner_call("animate_load_started", id):
		return
	var anim_player = $"%LeftLoadingAnimPlayer" if id == 1 else $"%RightLoadingAnimPlayer"
	anim_player.play("loop")


func animate_load_done(id :int):
	if not Global.show_selection_art:
		return
	emit_signal("anim_load_done", id)
	if banner_call("animate_load_done", id):
		return
	var anim_player = $"%LeftLoadingAnimPlayer" if id == 1 else $"%RightLoadingAnimPlayer"
	anim_player.play("load_done")


func set_sfx_data(id, sfx_data : Array):
	if not sfx_nodes.has(id):
		return
	var side_sfx_nodes = sfx_nodes[id]
	var sound_num = 0
	for entry in sfx_data:
		if not (entry is Dictionary):
			continue
		var used_sfx_node = side_sfx_nodes[sound_num]
		var sfx_timer :Timer = used_sfx_node.get_node("Timer")
		
		used_sfx_node.pitch_scale = entry.get("base_pitch", 0.0)
		used_sfx_node.pitch_scale_ = used_sfx_node.pitch_scale
		used_sfx_node.pitch_variation = entry.get("pitch_variation", 0.1)
		used_sfx_node.stream = entry.get("sfx", null)
		used_sfx_node.volume_db = entry.get("volume_db", -10)
		sfx_timer.wait_time = max(entry.get("delay", 0), 0.00001)
		sfx_timer.start()
		
		sound_num += 1
		if sound_num >= 2: # max sounds
			break

# saves a banner to show whenever this fighter is picked
func set_custom_banner(fighter_path, scene_path):
	custom_banners[fighter_path] = scene_path

# shows the custom banner on this side, if no custom scene, use base banner
func use_banner(id, fighter_path):
	# clears any previous loaded banners
	if is_instance_valid(banners[id]):
		banners[id].queue_free()
	banners[id] = null
	# checks if to use vanilla or custom banner
	var side = $"%LeftOffset" if id == 1 else $"%RightOffset"
	side.visible = not custom_banners.has(fighter_path)
	if side.visible:
		emit_signal("banner_changed", id, null)
		return
	# loads the custom banner of the selected fighter
	var banner = load(custom_banners[fighter_path]).instance()
	banner.player_id = id
	add_child(banner)
	if id == 2:
		banner.mirror()
	banners[id] = banner
	emit_signal("banner_changed", id, banner)

# calls the banner function with the same name instead
func banner_call(method_name, id):
	var banner = banners[id]
	if not (is_instance_valid(banner) and banner.has_method(method_name)):
		return false
	banner.call(method_name, id)
	return true

