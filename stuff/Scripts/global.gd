extends Node


##### Player direction variables #####
var player_facing_direction: int = 1
var player_movement_direction: float = 0.0

##### Player health variables #####
@export var player_max_health: int = 100
@export var player_health: int = 100



##### Player health/combat functions #####
func player_take_damage(damage):
	player_health -= damage
	print(player_health)


func player_death():
	if player_health <= 0:
		print("You died!")



# TODO: change inventory to global file
