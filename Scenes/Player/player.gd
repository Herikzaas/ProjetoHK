extends CharacterBody2D

@onready var anim = $animation as AnimatedSprite2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var atacando = false
var hsm: LimboHSM


#func ready
#-----------------------------------
func _ready() -> void:
	_init_state_machine()

#funcoes para a state machine
func _idle_ready():
	if not atacando:
		anim.play("idle")

func _move_ready():
	if not atacando:
		anim.play("run")

func _attack_ready():
	atacando = true
	anim.play("attack")

func _jump_ready():
	if not atacando and is_on_floor() :
		pass

func _fall_ready():
	pass

#-----------------------------------
#funcoes para a state machine
func _idle_physics_process(delta: float) :
	if velocity != Vector2.ZERO:
		hsm.dispatch(&"move_started")

func _move_physics_process(delta: float) :
	move_and_slide()
	if velocity == Vector2.ZERO:
		hsm.dispatch(&"move_ended")

func _attack_physics_process(delta: float):
	move_and_slide()
	#gambiarra, esse == 3 `e quando a animacao acaba
	if anim.frame == 3:
		atacando = false
	if atacando == false :
		hsm.dispatch(&"state_ended")

func _jump_physics_process(delta: float):
	velocity.y = JUMP_VELOCITY

func _fall_physics_process(delta: float):
	pass


#func process
func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta
		

	
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		anim.scale.x = direction
		$Area2D/CollisionShape2D.position.x = direction * 34
		$CollisionShape2D.position.x = direction * -4
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func _init_state_machine():
	hsm = LimboHSM.new()
	add_child(hsm)
	
	var idle_state = LimboState.new().named("idle").call_on_enter(_idle_ready).call_on_update(_idle_physics_process)
	var move_state = LimboState.new().named("move").call_on_enter(_move_ready).call_on_update(_move_physics_process)
	var attack_state = LimboState.new().named("attack").call_on_enter(_attack_ready).call_on_update(_attack_physics_process)
	var jump_state = LimboState.new().named("jump").call_on_enter(_jump_ready).call_on_update(_jump_physics_process)
	var fall_state = LimboState.new().named("fall").call_on_enter(_fall_ready).call_on_update(_fall_physics_process)
	
	hsm.add_child(idle_state)
	hsm.add_child(move_state)
	hsm.add_child(attack_state)
	hsm.add_child(jump_state)
	hsm.add_child(fall_state)
	
	hsm.add_transition(idle_state, move_state, &"move_started")
	hsm.add_transition(move_state, idle_state, &"move_ended")
	hsm.add_transition(hsm.ANYSTATE, idle_state, &"state_ended")
	hsm.add_transition(hsm.ANYSTATE, attack_state, &"attack_started")
	hsm.add_transition(hsm.ANYSTATE, jump_state, &"jump_started")
	hsm.add_transition(jump_state, fall_state, &"jump_ended")
	
	hsm.initial_state = idle_state
	hsm.initialize(self)
	hsm.set_active(true)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("attack") :
		atacando = true
		hsm.dispatch(&"attack_started")
	if event.is_action_pressed("ui_accept") and is_on_floor():
		hsm.dispatch(&"jump_started")
