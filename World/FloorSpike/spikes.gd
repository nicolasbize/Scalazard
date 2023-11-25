extends Node2D

@export var damage := 1

@onready var sprite := $Sprite2D
@onready var damage_dealer_area := $DamageDealerArea

func _ready():
	sprite.frame = randi_range(0, sprite.hframes - 1)
	damage_dealer_area.damage = damage

