class_name PlayerStateNames extends Resource

#region MOVEMENT
const Idle:String = "PlayerStateIdle"
const Walking:String = "PlayerStateWalking"
const Running:String = "PlayerStateRunning"
const Climbing:String = "PlayerStateClimbing"
const Stop:String = "PlayerStateStop"
#endregion

#region INTERACTIONS
const Saving:String = "PlayerStateSaving"
const Interact:String = "PlayerStateInteract"
const Cinematic:String = "PlayerStateCinematic"
#endregion

#region COMBAT OFFENSIVE
const AttackA:String = "PlayerStateAttackA"
const AttackB:String = "PlayerStateAttackB"
#endregion

#region COMBAT DEFFENSIVE
const Blocking:String = "PlayerStateBlocking"
const Dodging:String = "PlayerStateDodge"
#endregion

#region HURT
const Hurt:String = "PlayerStateHurt"
const Dead:String = "PlayerStateDead"
#endregion
