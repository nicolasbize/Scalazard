extends Node2D

@export var damage := 1

@onready var sprite := $Sprite2D
@onready var damage_dealer_area := $DamageDealerArea

func _ready():
	sprite.frame = randi_range(0, sprite.hframes - 1)
	damage_dealer_area.damage = damage
	damage_dealer_area.connect("body_entered", on_spike_entered.bind())

func on_spike_entered(body):
	print(body)
	print(body.name)
