#enemy_global_stats.gd:

class_name EnemyGlobalStats extends Resource

#-----------------------------------------------------------------------------#

@export var enemy_name: String = ""

#-----------------------------------------------------------------------------#

@export var MAX_HP: int = 50
@export var MAX_CP: int = 100

@export var CURRENT_HP: int = 1
@export var CURRENT_CP: int = 1

@export var MAX_SHIELD: int = 999   #---> Vida max. del blindaje (si la tiene)
@export var CURRENT_SHIELD: int = 0

@export var CURRENT_ALTERED_STATE: DamageData.StatusEffect = DamageData.StatusEffect.PURE

@export var x: String = "-------------------------"

#-----------------------------------------------------------------------------#

enum EnemyType { NONE, SPECTRE, BEAST, SNOOPER, HUMAN }
enum EnemyRank { NONE, ENEMIE, SUB_BOSS, BOSS }

@export var type: EnemyType = EnemyType.NONE
@export var rank: EnemyRank = EnemyRank.NONE

@export var x_: String = "-------------------------"

#-----------------------------------------------------------------------------#

@export var ATK: int = 0
@export var DEF: int = 0
@export var ESP: int = 0
@export var LCK: int = 0


@export var x__: String = "-------------------------"


@export var speed: float = 50.0
@export var running_speed: int = 40


@export var x___: String = "-------------------------"


#-----------------------------------------------------------------------------#

@export var affinities: Array[AffinityEntry] = []

#-----------------------------------------------------------------------------#

func get_affinity_for_attack(attack_data: DamageData) -> AffinityEntry.Affinity:
	for entry in affinities:
		if entry.matches_attack(attack_data):
			return entry.affinity
	return AffinityEntry.Affinity.NONE
