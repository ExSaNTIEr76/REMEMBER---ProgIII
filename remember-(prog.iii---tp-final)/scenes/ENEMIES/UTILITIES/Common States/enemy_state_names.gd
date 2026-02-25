class_name EnemyStateNames extends Resource

#region MOVEMENT
const Spawn : String = "EnemyStateSpawn"
const Idle : String = "EnemyStateIdle"
const Cooldown : String = "EnemyStateCooldown"
#endregion

#region COMBAT OFFENSIVE
const Charging : String = "EnemyStateCharging"
const Onrushing : String = "EnemyStateOnrushing"
const Crashing : String = "EnemyStateCrashing"
#endregion

#region COMBAT DEFFENSIVE
#const Blocking : String = "EnemyStateBlock"
#const Dodging : String = "EnemyStateDodge"
#endregion

#region HURT
const Stunned : String = "EnemyStateStunned"
const Hurt : String = "EnemyStateHurt"
const Dead : String = "EnemyStateDead"
#endregion
