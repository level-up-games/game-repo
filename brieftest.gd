extends Area2D


var player_in_range: bool = false



func _ready() -> void:
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_in_range = true
		Global.npc_dialogue_checkpoints["Villager1"] = "test1"


func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_in_range = false
