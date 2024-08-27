extends AnimatedSprite2D
@onready var mouse_cursor = $"."


# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Input.set_custom_mouse_cursor(mouse_cursor)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position = get_global_mouse_position()
	
	if Input.is_action_just_pressed("mb_left"):
		play("click")
