extends CharacterBody2D

@onready var anim = $animacao as Animatio

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
	anim.play("idle")

func _move_ready():
	anim.play("run")

func _attack_ready():
	atacando = true
	anim.play("attack")

#-----------------------------------
#funcoes para a state machine
func _idle_physics_process(delta: float) :
	if velocity != Vector2.ZERO and not atacando:
		hsm.dispatch(&"move_started")

func _move_physics_process(delta: float) :
	move_and_slide()
	if velocity == Vector2.ZERO :
		hsm.dispatch(&"move_ended")

func _attack_physics_process(delta: float):
	if anim.animation_finished:
		print('atack')
		atacando = false
		#hsm.dispatch(&"state_ended")
#func process
func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		anim.scale.x = direction
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func _init_state_machine():
	hsm = LimboHSM.new()
	add_child(hsm)
	
	var idle_state = LimboState.new().named("idle").call_on_enter(_idle_ready).call_on_update(_idle_physics_process)
	var move_state = LimboState.new().named("move").call_on_enter(_move_ready).call_on_update(_move_physics_process)
	var attack_state = LimboState.new().named("attack").call_on_enter(_attack_ready).call_on_update(_attack_physics_process)

	hsm.add_child(idle_state)
	hsm.add_child(move_state)
	hsm.add_child(attack_state)
	
	
	hsm.add_transition(idle_state, move_state, &"move_started")
	hsm.add_transition(move_state, idle_state, &"move_ended")
	hsm.add_transition(hsm.ANYSTATE, idle_state, &"state_ended")
	#hsm.add_transition(hsm.ANYSTATE, idle_state, &"attack_ended")
	hsm.add_transition(hsm.ANYSTATE, attack_state, &"attack_started")
	
	hsm.initial_state = idle_state
	hsm.initialize(self)
	hsm.set_active(true)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("attack") :
		hsm.dispatch(&"attack_started")
