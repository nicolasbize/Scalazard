extends Node

enum Sound {FootstepStone, FootstepWater, SlowFootstep, OutsideRain, Jump, Slide, Expand, Shrink, PushCrate, SwordSwish, SpellFail, HeroHurt,
EnemyHit, EnemyKill, BoxExplode, Warp, PowerUp, DoorOpen, DoorClose, Trigger, Collapse, Land, Fireball, Earthquake,
BossTeleport, Thunder, Chop, MenuNav, MenuSelect, ElectricCharge, Laser, FireballCreation, FireballExplosion, LifeUp, VaseBreak}

var sound_map = {}

func _ready():
	sound_map = {
		Sound.FootstepStone: $FootstepStone,
		Sound.FootstepWater: $FootstepWater,
		Sound.SlowFootstep: $SlowFootstep,
		Sound.OutsideRain: $OutsideRain,
		Sound.Jump: $Jump,
		Sound.Slide: $Slide,
		Sound.Expand: $ExpandMagic,
		Sound.Shrink: $ShrinkMagic,
		Sound.PushCrate: $PushCrate,
		Sound.SwordSwish: $SwordSwish,
		Sound.SpellFail: $SpellFail,
		Sound.HeroHurt: $HeroHurt,
		Sound.EnemyHit: $EnemyHit,
		Sound.EnemyKill: $EnemyKill,
		Sound.BoxExplode: $BoxExplode,
		Sound.Warp: $Warp,
		Sound.PowerUp: $PowerUp,
		Sound.DoorOpen: $DoorOpen,
		Sound.DoorClose: $DoorClose,
		Sound.Trigger: $Trigger,
		Sound.Collapse: $CollapsingPlatform,
		Sound.Land: $Land,
		Sound.Fireball: $Fireball,
		Sound.Earthquake: $Earthquake,
		Sound.BossTeleport: $BossTeleport,
		Sound.Thunder: $Thunder,
		Sound.Chop: $Chop,
		Sound.MenuNav: $MenuNav,
		Sound.MenuSelect: $MenuSelect,
		Sound.ElectricCharge: $ElectricShock,
		Sound.Laser: $Laser,
		Sound.FireballCreation: $EnergyCreation,
		Sound.FireballExplosion: $EnergyExplosion,
		Sound.LifeUp: $LifeUp,
		Sound.VaseBreak: $VaseBreak,
		
	}

func play(sound: Sound, alter_pitch: bool = false) -> void:
	if sound_map[sound] is SoundPool:
		sound_map[sound].play_random_sound(alter_pitch)
	else:
		sound_map[sound].play_sound(alter_pitch)

func stop(sound: Sound):
	sound_map[sound].stop()
