class_name ItemData    extends Resource

enum ItemType { NONE, CONSUMABLE, KEY, MATERIAL, MISCELLANEOUS, 
CONCRETE, ABSTRACT, SINGULAR, DEF1, DEF2, SPECIAL }

@export var name : String = ""
@export var type: ItemType = ItemType.NONE
@export var ID : int = 0
@export var is_quantitative : bool = false
@export_multiline var description : String = ""
@export var texture : Texture2D
@export var cost : int = 10
