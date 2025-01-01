extends CharacterBody2D

@onready var anim = $animacao as AnimatedSprite2D

var speed = 300

var hsm: LimboHSM

func _ready() -> void:
	_init_state_machine()

#funcoes para o hsm
func _idle_ready():
	anim.play("idle")

func _move_ready():
	pass

func _attack_ready():
	pass

#funcoes physics para a hsm 

func _idle_physics_process(delta: float):
	pass

func _move_physics_process(delta: float):
	pass

func _attack_physics_process(delta: float):
	pass


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()



func _init_state_machine():
	hsm = LimboHSM.new()
	add_child(hsm)

	var idle_state = LimboState.new().named("idle").call_on_enter(_idle_ready).call_on_update(_idle_physics_process)
	var move_state = LimboState.new().named("move").call_on_enter(_move_ready).call_on_update(_move_physics_process)
	var attack_state = LimboState.new().named("attack").call_on_enter(_attack_ready).call_on_update(_attack_physics_process)
	
	hsm.add_child(idle_state)
	hsm.add_child(move_state)
	hsm.add_child(attack_state)
	
	hsm.add_transition(hsm.ANYSTATE, move_state, &"move_started")
	hsm.add_transition(move_state, idle_state, &"move_ended")
	hsm.add_transition(hsm.ANYSTATE, idle_state, &"state_ended")
	hsm.add_transition(hsm.ANYSTATE, attack_state, &"attack_started")

	hsm.initial_state = idle_state
	hsm.initialize(self)
	hsm.set_active(true)
