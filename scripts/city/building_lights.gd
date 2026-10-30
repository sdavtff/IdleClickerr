class_name BuildingLights
extends Node2D
## Camada de luzes noturnas de um edifício (janelas acesas, letreiros).

var owner_node = null


func _draw() -> void:
	if owner_node == null:
		return
	BuildingArt.draw(self, owner_node.id, owner_node.level, 1)
