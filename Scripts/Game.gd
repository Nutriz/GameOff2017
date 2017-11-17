extends Node2D

var domino_scn = preload("res://Scenes/Domino.tscn")

var mouse_pressed = false
var must_magnet = false
var selected_dom
var clicked_pos = Vector2(0,0)
var magnet_pos

export var debug = true
export var magnet_threshold = 20
export var INITIAL_DOM_COUNT = 4

onready var anchors = {"1" : $CameraTarget/Camera2D/Panel/Pos1, "2" : $CameraTarget/Camera2D/Panel/Pos2, "3" : $CameraTarget/Camera2D/Panel/Pos3, "4" : $CameraTarget/Camera2D/Panel/Pos4}

func _ready():
	create_initial_dominoes()
	create_pickable_dominoes()
	
func _process(delta):
#	$Player.position.y += 50 * delta
	if debug:
		draw_debug()
	
func _on_mouse_over_domino(is_over, domino):
	printt("_on_mouse_over_domino", "is_over: " + str(is_over), domino.unique_id)
	if is_over:
		selected_dom = domino
	else:
		selected_dom = null
	
func _on_dom_placed(domino):
	domino.reparent_to($Dominoes, magnet_pos)
	# TODO free anchor ???
	$CameraTarget.position = magnet_pos

#	# TODO Generate new one at empty anchor
	selected_dom = null

func get_last_posed_dom():
	return $Dominoes.get_child($Dominoes.get_child_count()-1)

#####################
#### INPUTS
#####################
func _input(event):
	if selected_dom != null:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT:
				manage_mouse_click(event.pressed)
				
		if event is InputEventMouseMotion and mouse_pressed:
			manage_mouse_motion()

				
func manage_mouse_click(clicked):
	if clicked:
		clicked_pos = get_global_mouse_position()
		mouse_pressed = true
	else:
		mouse_pressed = false
		if must_magnet:
			selected_dom.place_and_lock()
		else:
			selected_dom.reset_pos_and_rot()
		

func manage_mouse_motion():
	if magnet_pos != null and magnet_pos.distance_to(get_global_mouse_position()) > 30:
		must_magnet = false
	
	if must_magnet:
		selected_dom.global_position = magnet_pos
	else:
		var diff = clicked_pos - get_global_mouse_position()
		selected_dom.position = -diff
				
func magnet_to(pos):
	must_magnet = true
	magnet_pos = pos

#####################
#### INIT SCENE
#####################
func create_initial_dominoes():
	randomize()
	
	var last_bottom_value = randi() % 6
	for num in range(4):
		var domino = domino_scn.instance()
		
		# if last value is blank, dont use it for next value
		if last_bottom_value == 0:
			last_bottom_value = randi() % 6
			
		domino.set_values(last_bottom_value, randi() % 6) # random numbrer from 0 to 6
		last_bottom_value = domino.values.bottom
			
		var dom_size = domino.get_node("Sprite").get_item_rect().size
		var dom_scale = domino.get_node("Sprite").scale
		domino.position = Vector2($Center.position.x, $Center.position.y + (num*dom_size.y*dom_scale.y))
		$Dominoes.add_child( domino)
		
func create_pickable_dominoes():
	for num in range(INITIAL_DOM_COUNT):
		add_new_domino(num)
		
func add_new_domino(anchor):
	randomize()
	var domino = domino_scn.instance()
	var anchor_num = str(anchor+1)
	domino.set_values(randi() % 6,  randi() % 6) # random numbrer from 0 to 6
	domino.bind_panel_anchor(anchors[anchor_num])

	domino.connect("_on_dom_can_move", self, "_on_mouse_over_domino")
	domino.connect("_on_dom_placed", self, "_on_dom_placed")
	anchors[anchor_num].add_child(domino)


#####################
#### DEBUG
#####################
func draw_debug():
	if selected_dom != null:
		var curr_top = selected_dom.get_node("Sprite/Top")
		var last_bottom = get_last_posed_dom().get_node("Sprite/Bottom")
		var last_bottom_left = get_last_posed_dom().get_node("Sprite/BottomLeft")
		var last_bottom_right = get_last_posed_dom().get_node("Sprite/BottomRight")
				
		$Debug/LineBottom.set_point_position(0, curr_top.global_position)
		$Debug/LineBottom.set_point_position(1, last_bottom.global_position)
				
		$Debug/LineBottomLeft.set_point_position(0, curr_top.global_position)
		$Debug/LineBottomLeft.set_point_position(1, last_bottom_left.global_position)
				
		$Debug/LineBottomRight.set_point_position(0, curr_top.global_position)
		$Debug/LineBottomRight.set_point_position(1, last_bottom_right.global_position)
		
		var from_bot_dist = curr_top.global_position.distance_to(last_bottom.global_position)
		var from_botleft_dist = curr_top.global_position.distance_to(last_bottom_left.global_position)
		var from_botright_dist = curr_top.global_position.distance_to(last_bottom_right.global_position)
			
		if from_bot_dist < from_botleft_dist and from_bot_dist < from_botright_dist:
			$Debug/LineBottom.default_color = Color(0, 1, 0)
			$Debug/LineBottomLeft.default_color = Color(1, 0, 0)
			$Debug/LineBottomRight.default_color = Color(1, 0, 0)
			if from_bot_dist < magnet_threshold:
				magnet_to(last_bottom.global_position)
				selected_dom.get_node("Sprite").rotation_deg = 0 + get_last_posed_dom().get_dom_rotation()
			else:
				must_magnet = false
	
		if from_botright_dist < from_bot_dist and from_botright_dist < from_botleft_dist:
			$Debug/LineBottom.default_color = Color(1, 0, 0)
			$Debug/LineBottomLeft.default_color = Color(1, 0, 0)
			$Debug/LineBottomRight.default_color = Color(0, 1, 0)
			if from_botright_dist < magnet_threshold:
				magnet_to(last_bottom_right.global_position)
				selected_dom.get_node("Sprite").rotation_deg = -90 + get_last_posed_dom().get_dom_rotation()
			else:
				must_magnet = false
				
		if from_botleft_dist < from_bot_dist and from_botleft_dist < from_botright_dist:
			$Debug/LineBottom.default_color = Color(1, 0, 0)
			$Debug/LineBottomLeft.default_color = Color(0, 1, 0)
			$Debug/LineBottomRight.default_color = Color(1, 0, 0)
			if from_botleft_dist < magnet_threshold:
				magnet_to(last_bottom_left.global_position)
				selected_dom.get_node("Sprite").rotation_deg = 90 + get_last_posed_dom().get_dom_rotation()
			else:
				must_magnet = false
