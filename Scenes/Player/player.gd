extends CharacterBody2D

@onready var anim = $animation as AnimatedSprite2D

var speed = 300.0
const JUMP_VELOCITY = -400.0
const dash_speed = 900.0

var hsm: LimboHSM

var is_jumping = false
var is_dashing = false
var is_attacking = false
var attack_possible = true
var dash_possible = true
var facing_right = true
#func ready
#-----------------------------------
func _ready() -> void:
	_init_state_machine()

#funcoes para a state machine
func _idle_ready():
	anim.play("idle")

func _move_ready():
	anim.play("move")

func _attack_ready():
	anim.play("attack")

func _jump_ready():
	anim.play("jump")
		
func _fall_ready():
	anim.play("fall")

func _dash_ready():
	anim.play("dash")

#-----------------------------------
#funcoes para a state machine
func _idle_physics_process(delta: float) :
	is_attacking = false
	if velocity != Vector2.ZERO:
		hsm.dispatch(&"move_started")

func _move_physics_process(delta: float) :
	is_attacking = false
	move_and_slide()
	if velocity == Vector2.ZERO :
		hsm.dispatch(&"move_ended")
	if not is_on_floor():
		hsm.dispatch(&"fall_started")

func _attack_physics_process(delta: float):
	move_and_slide()
	if anim.frame == 3:
		is_attacking = false
		hsm.dispatch(&"state_ended")
	
func _jump_physics_process(delta: float):
	move_and_slide()
	if anim.frame == 2 :
		hsm.dispatch(&"fall_started")

func _fall_physics_process(delta: float):
	move_and_slide()
	if is_on_floor() :
		is_jumping = false
		is_attacking = false
		hsm.dispatch(&"state_ended")

func _dash_physics_process(delta: float):
	move_and_slide()
	await get_tree().create_timer(.3).timeout
	is_dashing = false
	if is_on_floor():
		hsm.dispatch(&"move_started")
	else :
		hsm.dispatch(&"fall_started")

#func process
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if not is_on_floor() and not is_jumping:
		hsm.dispatch(&"fall_started")
		
	if is_on_floor() :
		is_jumping = false
	
	var direction := Input.get_axis("ui_left", "ui_right")
	
	if is_dashing:
		if anim.scale.x == 1 :
			move_local_x(10)
		if anim.scale.x == -1 :
			move_local_x(-10)

	if direction:
		anim.scale.x = direction
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	if Input.is_action_just_pressed("attack") and attack_possible:
		$attack_cooldown.start()
		is_attacking = true
		attack_possible = false
		hsm.dispatch(&"attack_started")

	if Input.is_action_just_pressed("ui_accept") and not is_jumping and not is_attacking:
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		hsm.dispatch(&"jump_started")

	if Input.is_action_just_pressed("dash") and dash_possible:
		$dash_cooldown.start()
		dash_possible = false
		is_dashing = true
		hsm.dispatch(&"dash_started")

func _init_state_machine():
	hsm = LimboHSM.new()
	add_child(hsm)
	
	var idle_state = LimboState.new().named("idle").call_on_enter(_idle_ready).call_on_update(_idle_physics_process)
	var move_state = LimboState.new().named("move").call_on_enter(_move_ready).call_on_update(_move_physics_process)
	var attack_state = LimboState.new().named("attack").call_on_enter(_attack_ready).call_on_update(_attack_physics_process)
	var jump_state = LimboState.new().named("jump").call_on_enter(_jump_ready).call_on_update(_jump_physics_process)
	var fall_state = LimboState.new().named("fall").call_on_enter(_fall_ready).call_on_update(_fall_physics_process)
	var dash_state = LimboState.new().named("dash").call_on_enter(_dash_ready).call_on_update(_dash_physics_process)
	
	hsm.add_child(idle_state)
	hsm.add_child(move_state)
	hsm.add_child(attack_state)
	hsm.add_child(jump_state)
	hsm.add_child(fall_state)
	hsm.add_child(dash_state)

	hsm.add_transition(hsm.ANYSTATE, move_state, &"move_started")
	hsm.add_transition(move_state, idle_state, &"move_ended")
	hsm.add_transition(hsm.ANYSTATE, idle_state, &"state_ended")
	hsm.add_transition(hsm.ANYSTATE, attack_state, &"attack_started")
	hsm.add_transition(hsm.ANYSTATE, jump_state, &"jump_started")
	hsm.add_transition(hsm.ANYSTATE, fall_state, &"fall_started")
	hsm.add_transition(hsm.ANYSTATE, dash_state, &"dash_started")
	
	hsm.initial_state = idle_state
	hsm.initialize(self)
	hsm.set_active(true)


func _on_dash_cooldown_timeout() -> void:
	dash_possible = true

func _on_attack_cooldown_timeout() -> void:
	attack_possible = true
