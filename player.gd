extends KinematicBody

const MAX_SPEED_WALKING = 10
const MAX_SPEED_SPRINTING = 30
const MAX_SPEED_CROUCHING = 5
const MAX_SPEED_AIR = 12

const GRAVITY = -40
const JUMP_SPEED = 15

const ACCEL = 4.5
const DEACCEL= 16

const MAX_SLOPE_ANGLE = 40
const MOUSE_SENSITIVITY = 0.5


var camera
var crouch_anim
var ceiling_check

var posture = 0  # 0 = stand, 1 = crouch

var vel = Vector3()

func _ready():
    camera = $Camera
    crouch_anim = $Crouch
    ceiling_check = $CeilingCheck
    
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    # Tell Godot that we want to handle input
    set_process_input(true)

func process_actions(delta):
    pass

func _physics_process(delta):
    process_movement(delta)
    process_actions(delta)

func process_movement(delta):

    # ----------------------------------
    # Walking
    var dir = Vector3()
    var cam_xform = camera.get_global_transform()

    var input_movement_vector = Vector2()

    if Input.is_action_pressed("move_forward"):
        input_movement_vector.y += 1
    if Input.is_action_pressed("move_back"):
        input_movement_vector.y -= 1
    if Input.is_action_pressed("move_left"):
        input_movement_vector.x -= 1
    if Input.is_action_pressed("move_right"):
        input_movement_vector.x += 1

    input_movement_vector = input_movement_vector.normalized()

    dir += -cam_xform.basis.z.normalized() * input_movement_vector.y
    dir += cam_xform.basis.x.normalized() * input_movement_vector.x
    # ----------------------------------

    # ----------------------------------
    # Jumping
    if is_on_floor():
        if Input.is_action_just_pressed("jump"):
            vel.y = JUMP_SPEED
    # ----------------------------------
    
    # ----------------------------------
    # Sprinting and crouching
    var is_sprinting = Input.is_action_pressed("sprint")
    if Input.is_action_just_pressed("crouch"):
        print("crouching")
        togglePosture()

    # ----------------------------------
    # Capturing/Freeing the cursor
    if Input.is_action_just_pressed("ui_cancel"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    # ----------------------------------
    
    # ----------------------------------
    # Move
    dir.y = 0
    dir = dir.normalized()
    
    var max_speed = get_max_speed(is_sprinting)

    vel.y += delta * GRAVITY

    var hvel = vel
    hvel.y = 0

    var target = dir
    target *= max_speed

    var accel
    if dir.dot(hvel) > 0:
        accel = ACCEL
    else:
        accel = DEACCEL

    hvel = hvel.linear_interpolate(target, accel * delta)
    vel.x = hvel.x
    vel.z = hvel.z
    vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))
    # ----------------------------------

func get_max_speed(is_sprinting):
    if (not is_on_floor()):
        return MAX_SPEED_AIR
    if (posture == 1):
        return MAX_SPEED_CROUCHING
    if (is_sprinting):
        return MAX_SPEED_SPRINTING
    return MAX_SPEED_WALKING

func _input(event):
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        mouse(event)

func look_updown_rotation(rotation = 0):
    """
    Get the new rotation for looking up and down
    """
    
    var toReturn = camera.get_rotation() + Vector3(rotation, 0, 0)
    # ----------------------------------
    # We don't want the player to be able to bend over backwards
    # neither to be able to look under their arse.
    # Here we'll clamp the vertical look to 90° up and down
    toReturn.x = clamp(toReturn.x, PI / -2, PI / 2)
    # ----------------------------------

    return toReturn

func look_leftright_rotation(rotation = 0):
    """
    Get the new rotation for looking left and right
    """
    return self.get_rotation() + Vector3(0, rotation, 0)

func mouse(event):
    """
    First person camera controls
    """
    # ----------------------------------
    ## We'll use the parent node "self" to set our left-right rotation
    ## This prevents us from adding the x-rotation to the y-rotation
    ## which would result in a kind of flight-simulator camera
    self.set_rotation(look_leftright_rotation(event.relative.x*MOUSE_SENSITIVITY / -200))
    # ----------------------------------
    
    # ----------------------------------
    ## Now we can simply set our y-rotation for the camera, and let godot
    ## handle the transformation of both together
    camera.set_rotation(look_updown_rotation(event.relative.y*MOUSE_SENSITIVITY / -200))
    # ----------------------------------
    
func setPosture(posture_in):
    if posture_in == 0 and ceiling_check.is_colliding():
        return

    print(posture)
    print(posture_in)
    posture = posture_in
    
    if posture == 0:
        crouch_anim.play_backwards("Crouch")
        
    if posture == 1:
        crouch_anim.play("Crouch")

func togglePosture():
    
    print("toggling, posture currently: " + str(posture))
    if posture == 0:
        setPosture(1)
    elif posture == 1:
        setPosture(0)