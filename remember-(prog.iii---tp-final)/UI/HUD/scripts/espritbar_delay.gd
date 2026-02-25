class_name EspritbarDelay    extends Espritbar

@export var delayEspritBar : Espritbar
@export var updateValueDelayTimer : Timer

func _ready() -> void:
	updateValueDelayTimer.timeout.connect(updateChildBar)

func updateChildBar() -> void:
	delayEspritBar.updateValue(value)

func setUp(maxValue : float) -> void:
	super.setUp(maxValue)
	delayEspritBar.setUp(maxValue)

func updateValue(_newValue : float) -> void:
	super.updateValue(_newValue)
	updateValueDelayTimer.start()
