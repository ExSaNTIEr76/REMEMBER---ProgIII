class_name HealthbarDelay    extends Healthbar

@export var delayHealthBar : Healthbar
@export var updateValueDelayTimer : Timer

func _ready() -> void:
	updateValueDelayTimer.timeout.connect(updateChildBar)

func updateChildBar() -> void:
	delayHealthBar.updateValue(value)

func setUp(maxValue : float) -> void:
	super.setUp(maxValue)
	delayHealthBar.setUp(maxValue)

func updateValue(_newValue : float) -> void:
	super.updateValue(_newValue)
	updateValueDelayTimer.start()
