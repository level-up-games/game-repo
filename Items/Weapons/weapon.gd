extends Node2D
class_name Weapon


var weapon_owner: Node = null
var can_attack: bool = true



func setup_weapon(owner_node: Node) -> void:
	weapon_owner = owner_node
	# Connect the player's attack signals to this weapon’s handlers.
	# We assume the player has signals: Attack1, Attack2, Attack3, Attack4.
	weapon_owner.Attack1.connect(_on_attack1)
	weapon_owner.Attack2.connect(_on_attack2)
	weapon_owner.Attack3.connect(_on_attack3)
	weapon_owner.Attack4.connect(_on_attack4)


# Define virtual functions (to be overridden by child classes) for each attack.
func _on_attack1() -> void:
	# Override in the weapon subclass.
	pass

func _on_attack2() -> void:
	# Override in the weapon subclass.
	pass

func _on_attack3() -> void:
	# Override in the weapon subclass.
	pass

func _on_attack4() -> void:
	# Override in the weapon subclass.
	pass
