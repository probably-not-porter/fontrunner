extends Sprite2D

@export var rotation_speed: float = 10.0
@export var idle_fade_delay: float = 1.0 # Time to wait before fading to 30%

var last_screen_mouse_pos: Vector2 = Vector2.ZERO
var time_since_mouse_move: float = 0.0
var is_faded_out: bool = true
var fade_tween: Tween

func _ready() -> void:
	modulate.a = 0.0;
	# Track the initial position on the screen
	last_screen_mouse_pos = get_viewport().get_mouse_position()

func _process(delta: float) -> void:
	# 1. ALWAYS rotate toward the world mouse position so aiming works perfectly
	var global_mouse_pos = get_global_mouse_position()
	var target_angle = global_position.direction_to(global_mouse_pos).angle()
	rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)
	
	# 2. Check the SCREEN mouse position to see if your physical hand moved
	var current_screen_mouse_pos = get_viewport().get_mouse_position()
	
	if current_screen_mouse_pos != last_screen_mouse_pos:
		time_since_mouse_move = 0.0
		last_screen_mouse_pos = current_screen_mouse_pos
		
		# Quick fade in over 0.1s when your hand actually moves the mouse
		if is_faded_out:
			fade_opacity(1.0, 0.05)
			is_faded_out = false
	else:
		time_since_mouse_move += delta
		
		# Slow fade to 30% over 1.0s if your hand is resting
		if time_since_mouse_move >= idle_fade_delay and not is_faded_out:
			fade_opacity(0.0, 0.5)
			is_faded_out = true

func fade_opacity(target_alpha: float, duration: float) -> void:
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()
		
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", target_alpha, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
